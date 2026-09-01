package com.demo.erp.service.impl;

import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.demo.erp.common.BizException;
import com.demo.erp.common.OrderNoUtil;
import com.demo.erp.common.UserContext;
import com.demo.erp.dto.OrderItemDTO;
import com.demo.erp.dto.PurchaseOrderDTO;
import com.demo.erp.entity.Payable;
import com.demo.erp.entity.PurchaseOrder;
import com.demo.erp.entity.PurchaseOrderItem;
import com.demo.erp.entity.Stock;
import com.demo.erp.entity.StockFlow;
import com.demo.erp.mapper.PayableMapper;
import com.demo.erp.mapper.PurchaseOrderItemMapper;
import com.demo.erp.mapper.PurchaseOrderMapper;
import com.demo.erp.mapper.StockFlowMapper;
import com.demo.erp.mapper.StockMapper;
import com.demo.erp.service.PurchaseService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDateTime;
import java.util.List;

/**
 * 采购管理服务实现
 */
@Service
@RequiredArgsConstructor
public class PurchaseServiceImpl implements PurchaseService {

    private final PurchaseOrderMapper orderMapper;
    private final PurchaseOrderItemMapper itemMapper;
    private final StockMapper stockMapper;
    private final StockFlowMapper flowMapper;
    private final PayableMapper payableMapper;

    @Override
    public IPage<PurchaseOrder> pageQuery(long page, long size, String keyword, String status,
                                          String startDate, String endDate) {
        return orderMapper.selectPageJoin(new Page<>(page, size), keyword, status, startDate, endDate);
    }

    @Override
    public PurchaseOrder detail(Long id) {
        PurchaseOrder order = getOrThrow(id);
        order.setItems(itemMapper.selectByOrderId(id));
        return order;
    }

    @Override
    @Transactional
    public String create(PurchaseOrderDTO dto) {
        PurchaseOrder order = new PurchaseOrder();
        String prefix = OrderNoUtil.todayPrefix("PO");
        order.setOrderNo(OrderNoUtil.next(prefix, orderMapper.selectMaxNo(prefix)));
        order.setSupplierId(dto.getSupplierId());
        order.setWarehouseId(dto.getWarehouseId());
        order.setStatus(PurchaseOrder.STATUS_DRAFT);
        order.setRemark(dto.getRemark());
        order.setCreatedBy(UserContext.get().id());
        fillTotals(order, dto.getItems());
        orderMapper.insert(order);
        insertItems(order.getId(), dto.getItems());
        return order.getOrderNo();
    }

    @Override
    @Transactional
    public void update(Long id, PurchaseOrderDTO dto) {
        PurchaseOrder order = getOrThrow(id);
        requireStatus(order, PurchaseOrder.STATUS_DRAFT, "仅草稿状态可编辑");
        order.setSupplierId(dto.getSupplierId());
        order.setWarehouseId(dto.getWarehouseId());
        order.setRemark(dto.getRemark());
        fillTotals(order, dto.getItems());
        orderMapper.updateById(order);
        itemMapper.delete(Wrappers.<PurchaseOrderItem>lambdaQuery()
                .eq(PurchaseOrderItem::getOrderId, id));
        insertItems(id, dto.getItems());
    }

    @Override
    @Transactional
    public void approve(Long id) {
        PurchaseOrder order = getOrThrow(id);
        requireStatus(order, PurchaseOrder.STATUS_DRAFT, "仅草稿状态可审核");
        order.setStatus(PurchaseOrder.STATUS_APPROVED);
        order.setApprovedAt(LocalDateTime.now());
        orderMapper.updateById(order);
    }

    @Override
    @Transactional
    public void cancel(Long id) {
        PurchaseOrder order = getOrThrow(id);
        requireStatus(order, PurchaseOrder.STATUS_DRAFT, "仅草稿状态可作废");
        order.setStatus(PurchaseOrder.STATUS_CANCELED);
        orderMapper.updateById(order);
    }

    @Override
    @Transactional
    public void delete(Long id) {
        PurchaseOrder order = getOrThrow(id);
        if (!PurchaseOrder.STATUS_DRAFT.equals(order.getStatus())
                && !PurchaseOrder.STATUS_CANCELED.equals(order.getStatus())) {
            throw new BizException("仅草稿或已作废单据可删除");
        }
        orderMapper.deleteById(id);
    }

    /**
     * 入库:加权平均法更新库存成本
     * 新平均成本 = (原数量 * 原平均成本 + 入库数量 * 采购价) / (原数量 + 入库数量)
     */
    @Override
    @Transactional
    public void inbound(Long id) {
        PurchaseOrder order = getOrThrow(id);
        requireStatus(order, PurchaseOrder.STATUS_APPROVED, "仅已审核的采购单可执行入库");
        List<PurchaseOrderItem> items = itemMapper.selectByOrderId(id);
        LocalDateTime now = LocalDateTime.now();
        for (PurchaseOrderItem item : items) {
            // 行级锁定库存记录,避免并发下加权平均成本计算错乱
            Stock stock = stockMapper.selectForUpdate(order.getWarehouseId(), item.getProductId());
            if (stock == null) {
                stock = new Stock();
                stock.setWarehouseId(order.getWarehouseId());
                stock.setProductId(item.getProductId());
                stock.setQty(BigDecimal.ZERO);
                stock.setAvgCost(BigDecimal.ZERO);
                stockMapper.insert(stock);
                stock = stockMapper.selectForUpdate(order.getWarehouseId(), item.getProductId());
            }
            BigDecimal newQty = stock.getQty().add(item.getQty());
            BigDecimal newAvg = stock.getQty().multiply(stock.getAvgCost())
                    .add(item.getQty().multiply(item.getPrice()))
                    .divide(newQty, 4, RoundingMode.HALF_UP);
            stock.setQty(newQty);
            stock.setAvgCost(newAvg);
            stock.setUpdatedAt(now);
            stockMapper.updateById(stock);
            insertFlow(order, item, newQty, now);
        }
        order.setStatus(PurchaseOrder.STATUS_STOCKED);
        order.setStockedAt(now);
        orderMapper.updateById(order);
        // 生成应付账款
        Payable payable = new Payable();
        payable.setOrderNo(order.getOrderNo());
        payable.setSupplierId(order.getSupplierId());
        payable.setTotalAmount(order.getTotalAmount());
        payable.setPaidAmount(BigDecimal.ZERO);
        payable.setStatus(Payable.STATUS_UNPAID);
        payableMapper.insert(payable);
    }

    // ------------------- 私有方法 -------------------

    private PurchaseOrder getOrThrow(Long id) {
        PurchaseOrder order = orderMapper.selectById(id);
        if (order == null) {
            throw new BizException("采购单不存在");
        }
        return order;
    }

    private void requireStatus(PurchaseOrder order, String expected, String message) {
        if (!expected.equals(order.getStatus())) {
            throw new BizException(message + "(当前状态: " + order.getStatus() + ")");
        }
    }

    /** 服务端重算金额,不信任前端合计 */
    private void fillTotals(PurchaseOrder order, List<OrderItemDTO> items) {
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
            PurchaseOrderItem item = new PurchaseOrderItem();
            item.setOrderId(orderId);
            item.setProductId(dto.getProductId());
            item.setQty(dto.getQty());
            item.setPrice(dto.getPrice());
            item.setAmount(lineAmount(dto));
            itemMapper.insert(item);
        }
    }

    private BigDecimal lineAmount(OrderItemDTO item) {
        return item.getQty().multiply(item.getPrice()).setScale(2, RoundingMode.HALF_UP);
    }

    private void insertFlow(PurchaseOrder order, PurchaseOrderItem item, BigDecimal qtyAfter, LocalDateTime now) {
        StockFlow flow = new StockFlow();
        flow.setWarehouseId(order.getWarehouseId());
        flow.setProductId(item.getProductId());
        flow.setBizType(StockFlow.TYPE_PURCHASE_IN);
        flow.setBizNo(order.getOrderNo());
        flow.setQtyChange(item.getQty());
        flow.setQtyAfter(qtyAfter);
        flow.setPrice(item.getPrice());
        flow.setAmount(item.getAmount());
        flow.setRemark("采购入库");
        flow.setCreatedAt(now);
        flowMapper.insert(flow);
    }
}
