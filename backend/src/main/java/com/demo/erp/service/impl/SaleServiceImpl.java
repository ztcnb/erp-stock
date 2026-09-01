package com.demo.erp.service.impl;

import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.demo.erp.common.BizException;
import com.demo.erp.common.OrderNoUtil;
import com.demo.erp.common.UserContext;
import com.demo.erp.dto.OrderItemDTO;
import com.demo.erp.dto.SaleOrderDTO;
import com.demo.erp.entity.Receivable;
import com.demo.erp.entity.SaleOrder;
import com.demo.erp.entity.SaleOrderItem;
import com.demo.erp.entity.Stock;
import com.demo.erp.entity.StockFlow;
import com.demo.erp.mapper.ReceivableMapper;
import com.demo.erp.mapper.SaleOrderItemMapper;
import com.demo.erp.mapper.SaleOrderMapper;
import com.demo.erp.mapper.StockFlowMapper;
import com.demo.erp.mapper.StockMapper;
import com.demo.erp.service.SaleService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 销售管理服务实现
 */
@Service
@RequiredArgsConstructor
public class SaleServiceImpl implements SaleService {

    private final SaleOrderMapper orderMapper;
    private final SaleOrderItemMapper itemMapper;
    private final StockMapper stockMapper;
    private final StockFlowMapper flowMapper;
    private final ReceivableMapper receivableMapper;

    @Override
    public IPage<SaleOrder> pageQuery(long page, long size, String keyword, String status,
                                      String startDate, String endDate) {
        return orderMapper.selectPageJoin(new Page<>(page, size), keyword, status, startDate, endDate);
    }

    @Override
    public SaleOrder detail(Long id) {
        SaleOrder order = getOrThrow(id);
        order.setItems(itemMapper.selectByOrderId(id));
        return order;
    }

    @Override
    @Transactional
    public String create(SaleOrderDTO dto) {
        SaleOrder order = new SaleOrder();
        String prefix = OrderNoUtil.todayPrefix("SO");
        order.setOrderNo(OrderNoUtil.next(prefix, orderMapper.selectMaxNo(prefix)));
        order.setCustomerId(dto.getCustomerId());
        order.setWarehouseId(dto.getWarehouseId());
        order.setStatus(SaleOrder.STATUS_DRAFT);
        order.setRemark(dto.getRemark());
        order.setCreatedBy(UserContext.get().id());
        order.setTotalCost(BigDecimal.ZERO);
        order.setGrossProfit(BigDecimal.ZERO);
        fillTotals(order, dto.getItems());
        orderMapper.insert(order);
        insertItems(order.getId(), dto.getItems());
        return order.getOrderNo();
    }

    @Override
    @Transactional
    public void update(Long id, SaleOrderDTO dto) {
        SaleOrder order = getOrThrow(id);
        requireStatus(order, SaleOrder.STATUS_DRAFT, "仅草稿状态可编辑");
        order.setCustomerId(dto.getCustomerId());
        order.setWarehouseId(dto.getWarehouseId());
        order.setRemark(dto.getRemark());
        fillTotals(order, dto.getItems());
        orderMapper.updateById(order);
        itemMapper.delete(Wrappers.<SaleOrderItem>lambdaQuery()
                .eq(SaleOrderItem::getOrderId, id));
        insertItems(id, dto.getItems());
    }

    /** 审核时校验发货仓库库存充足(同一商品多行合并校验) */
    @Override
    @Transactional
    public void approve(Long id) {
        SaleOrder order = getOrThrow(id);
        requireStatus(order, SaleOrder.STATUS_DRAFT, "仅草稿状态可审核");
        List<SaleOrderItem> items = itemMapper.selectByOrderId(id);
        Map<Long, BigDecimal> needMap = new HashMap<>();
        Map<Long, String> nameMap = new HashMap<>();
        for (SaleOrderItem item : items) {
            needMap.merge(item.getProductId(), item.getQty(), BigDecimal::add);
            nameMap.put(item.getProductId(), item.getProductName());
        }
        for (Map.Entry<Long, BigDecimal> entry : needMap.entrySet()) {
            Stock stock = stockMapper.selectOne(Wrappers.<Stock>lambdaQuery()
                    .eq(Stock::getWarehouseId, order.getWarehouseId())
                    .eq(Stock::getProductId, entry.getKey()));
            BigDecimal available = stock == null ? BigDecimal.ZERO : stock.getQty();
            if (available.compareTo(entry.getValue()) < 0) {
                throw new BizException("商品[" + nameMap.get(entry.getKey()) + "]库存不足,现有 "
                        + available.stripTrailingZeros().toPlainString() + ",需要 "
                        + entry.getValue().stripTrailingZeros().toPlainString());
            }
        }
        order.setStatus(SaleOrder.STATUS_APPROVED);
        order.setApprovedAt(LocalDateTime.now());
        orderMapper.updateById(order);
    }

    @Override
    @Transactional
    public void cancel(Long id) {
        SaleOrder order = getOrThrow(id);
        requireStatus(order, SaleOrder.STATUS_DRAFT, "仅草稿状态可作废");
        order.setStatus(SaleOrder.STATUS_CANCELED);
        orderMapper.updateById(order);
    }

    @Override
    @Transactional
    public void delete(Long id) {
        SaleOrder order = getOrThrow(id);
        if (!SaleOrder.STATUS_DRAFT.equals(order.getStatus())
                && !SaleOrder.STATUS_CANCELED.equals(order.getStatus())) {
            throw new BizException("仅草稿或已作废单据可删除");
        }
        orderMapper.deleteById(id);
    }

    /**
     * 出库:使用条件更新 (UPDATE ... WHERE qty >= ?) 按影响行数判断,
     * 并发情况下也不会把库存扣成负数;成本按出库时点的加权平均成本记账。
     */
    @Override
    @Transactional
    public void outbound(Long id) {
        SaleOrder order = getOrThrow(id);
        requireStatus(order, SaleOrder.STATUS_APPROVED, "仅已审核的销售单可执行出库");
        List<SaleOrderItem> items = itemMapper.selectByOrderId(id);
        LocalDateTime now = LocalDateTime.now();
        BigDecimal totalCost = BigDecimal.ZERO;
        for (SaleOrderItem item : items) {
            int affected = stockMapper.deductQty(order.getWarehouseId(), item.getProductId(), item.getQty());
            if (affected == 0) {
                // 影响行数为 0 说明库存不足,整个事务回滚
                throw new BizException("商品[" + item.getProductName() + "]库存不足,出库失败");
            }
            Stock stock = stockMapper.selectOne(Wrappers.<Stock>lambdaQuery()
                    .eq(Stock::getWarehouseId, order.getWarehouseId())
                    .eq(Stock::getProductId, item.getProductId()));
            BigDecimal costPrice = stock.getAvgCost();
            BigDecimal costAmount = item.getQty().multiply(costPrice).setScale(2, RoundingMode.HALF_UP);
            item.setCostPrice(costPrice);
            item.setCostAmount(costAmount);
            itemMapper.updateById(item);
            totalCost = totalCost.add(costAmount);
            insertFlow(order, item, stock.getQty(), costPrice, costAmount, now);
        }
        order.setStatus(SaleOrder.STATUS_SHIPPED);
        order.setShippedAt(now);
        order.setTotalCost(totalCost);
        order.setGrossProfit(order.getTotalAmount().subtract(totalCost));
        orderMapper.updateById(order);
        // 生成应收账款
        Receivable receivable = new Receivable();
        receivable.setOrderNo(order.getOrderNo());
        receivable.setCustomerId(order.getCustomerId());
        receivable.setTotalAmount(order.getTotalAmount());
        receivable.setReceivedAmount(BigDecimal.ZERO);
        receivable.setStatus(Receivable.STATUS_UNRECEIVED);
        receivableMapper.insert(receivable);
    }

    // ------------------- 私有方法 -------------------

    private SaleOrder getOrThrow(Long id) {
        SaleOrder order = orderMapper.selectById(id);
        if (order == null) {
            throw new BizException("销售单不存在");
        }
        return order;
    }

    private void requireStatus(SaleOrder order, String expected, String message) {
        if (!expected.equals(order.getStatus())) {
            throw new BizException(message + "(当前状态: " + order.getStatus() + ")");
        }
    }

    /** 服务端重算金额,不信任前端合计 */
    private void fillTotals(SaleOrder order, List<OrderItemDTO> items) {
        BigDecimal totalQty = BigDecimal.ZERO;
        BigDecimal totalAmount = BigDecimal.ZERO;
        for (OrderItemDTO item : items) {
            totalQty = totalQty.add(item.getQty());
            totalAmount = totalAmount.add(lineAmount(item));
        }
        order.setTotalQty(totalQty);
        order.setTotalAmount(totalAmount);
    }

    private void insertItems(Long orderId, List<OrderItemDTO> items) {
        for (OrderItemDTO dto : items) {
            SaleOrderItem item = new SaleOrderItem();
            item.setOrderId(orderId);
            item.setProductId(dto.getProductId());
            item.setQty(dto.getQty());
            item.setPrice(dto.getPrice());
            item.setAmount(lineAmount(dto));
            item.setCostPrice(BigDecimal.ZERO);
            item.setCostAmount(BigDecimal.ZERO);
            itemMapper.insert(item);
        }
    }

    private BigDecimal lineAmount(OrderItemDTO item) {
        return item.getQty().multiply(item.getPrice()).setScale(2, RoundingMode.HALF_UP);
    }

    private void insertFlow(SaleOrder order, SaleOrderItem item, BigDecimal qtyAfter,
                            BigDecimal costPrice, BigDecimal costAmount, LocalDateTime now) {
        StockFlow flow = new StockFlow();
        flow.setWarehouseId(order.getWarehouseId());
        flow.setProductId(item.getProductId());
        flow.setBizType(StockFlow.TYPE_SALE_OUT);
        flow.setBizNo(order.getOrderNo());
        flow.setQtyChange(item.getQty().negate());
        flow.setQtyAfter(qtyAfter);
        flow.setPrice(costPrice);
        flow.setAmount(costAmount);
        flow.setRemark("销售出库");
        flow.setCreatedAt(now);
        flowMapper.insert(flow);
    }
}
