package com.demo.erp.service.impl;

import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.demo.erp.common.BizException;
import com.demo.erp.common.OrderNoUtil;
import com.demo.erp.common.UserContext;
import com.demo.erp.dto.TakingCreateDTO;
import com.demo.erp.dto.TakingItemDTO;
import com.demo.erp.dto.TakingSaveDTO;
import com.demo.erp.entity.Stock;
import com.demo.erp.entity.StockFlow;
import com.demo.erp.entity.StockTaking;
import com.demo.erp.entity.StockTakingItem;
import com.demo.erp.mapper.StockFlowMapper;
import com.demo.erp.mapper.StockMapper;
import com.demo.erp.mapper.StockTakingItemMapper;
import com.demo.erp.mapper.StockTakingMapper;
import com.demo.erp.service.TakingService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDateTime;
import java.util.List;

/**
 * 库存盘点服务实现
 */
@Service
@RequiredArgsConstructor
public class TakingServiceImpl implements TakingService {

    private final StockTakingMapper takingMapper;
    private final StockTakingItemMapper itemMapper;
    private final StockMapper stockMapper;
    private final StockFlowMapper flowMapper;

    @Override
    public IPage<StockTaking> pageQuery(long page, long size, String status) {
        return takingMapper.selectPageJoin(new Page<>(page, size), status);
    }

    @Override
    public StockTaking detail(Long id) {
        StockTaking taking = getOrThrow(id);
        taking.setItems(itemMapper.selectByTakingId(id));
        return taking;
    }

    @Override
    @Transactional
    public String create(TakingCreateDTO dto) {
        List<Stock> stocks = stockMapper.selectList(Wrappers.<Stock>lambdaQuery()
                .eq(Stock::getWarehouseId, dto.getWarehouseId())
                .orderByAsc(Stock::getProductId));
        if (stocks.isEmpty()) {
            throw new BizException("该仓库暂无库存记录,无需盘点");
        }
        StockTaking taking = new StockTaking();
        String prefix = OrderNoUtil.todayPrefix("PD");
        taking.setTakingNo(OrderNoUtil.next(prefix, takingMapper.selectMaxNo(prefix)));
        taking.setWarehouseId(dto.getWarehouseId());
        taking.setStatus(StockTaking.STATUS_DRAFT);
        taking.setRemark(dto.getRemark());
        taking.setCreatedBy(UserContext.get().id());
        takingMapper.insert(taking);
        for (Stock stock : stocks) {
            StockTakingItem item = new StockTakingItem();
            item.setTakingId(taking.getId());
            item.setProductId(stock.getProductId());
            item.setBookQty(stock.getQty());
            item.setDiffQty(BigDecimal.ZERO);
            itemMapper.insert(item);
        }
        return taking.getTakingNo();
    }

    @Override
    @Transactional
    public void saveItems(Long id, TakingSaveDTO dto) {
        StockTaking taking = getOrThrow(id);
        requireDraft(taking);
        for (TakingItemDTO itemDto : dto.getItems()) {
            StockTakingItem item = itemMapper.selectById(itemDto.getId());
            if (item == null || !item.getTakingId().equals(id)) {
                throw new BizException("盘点明细不存在或不属于当前盘点单");
            }
            item.setActualQty(itemDto.getActualQty());
            item.setDiffQty(itemDto.getActualQty().subtract(item.getBookQty()));
            itemMapper.updateById(item);
        }
    }

    /**
     * 完成盘点:以当前库存为最新账面数重算盈亏(防止盘点期间发生出入库导致口径漂移),
     * 差异按盘盈/盘亏生成调整流水,加权平均成本保持不变。
     */
    @Override
    @Transactional
    public void finish(Long id) {
        StockTaking taking = getOrThrow(id);
        requireDraft(taking);
        List<StockTakingItem> items = itemMapper.selectByTakingId(id);
        boolean anyActual = items.stream().anyMatch(i -> i.getActualQty() != null);
        if (!anyActual) {
            throw new BizException("尚未录入任何实盘数量,不能完成盘点");
        }
        LocalDateTime now = LocalDateTime.now();
        for (StockTakingItem item : items) {
            if (item.getActualQty() == null) {
                continue; // 未录入实盘的行视为不调整
            }
            Stock stock = stockMapper.selectForUpdate(taking.getWarehouseId(), item.getProductId());
            BigDecimal bookQty = stock == null ? BigDecimal.ZERO : stock.getQty();
            BigDecimal diff = item.getActualQty().subtract(bookQty);
            item.setBookQty(bookQty);
            item.setDiffQty(diff);
            itemMapper.updateById(item);
            if (diff.compareTo(BigDecimal.ZERO) == 0 || stock == null) {
                continue;
            }
            stock.setQty(item.getActualQty());
            stock.setUpdatedAt(now);
            stockMapper.updateById(stock);
            StockFlow flow = new StockFlow();
            flow.setWarehouseId(taking.getWarehouseId());
            flow.setProductId(item.getProductId());
            boolean gain = diff.compareTo(BigDecimal.ZERO) > 0;
            flow.setBizType(gain ? StockFlow.TYPE_TAKING_GAIN : StockFlow.TYPE_TAKING_LOSS);
            flow.setBizNo(taking.getTakingNo());
            flow.setQtyChange(diff);
            flow.setQtyAfter(item.getActualQty());
            flow.setPrice(stock.getAvgCost());
            flow.setAmount(diff.abs().multiply(stock.getAvgCost()).setScale(2, RoundingMode.HALF_UP));
            flow.setRemark(gain ? "盘盈调整" : "盘亏调整");
            flow.setCreatedAt(now);
            flowMapper.insert(flow);
        }
        taking.setStatus(StockTaking.STATUS_FINISHED);
        taking.setFinishedAt(now);
        takingMapper.updateById(taking);
    }

    @Override
    @Transactional
    public void delete(Long id) {
        StockTaking taking = getOrThrow(id);
        requireDraft(taking);
        takingMapper.deleteById(id);
    }

    // ------------------- 私有方法 -------------------

    private StockTaking getOrThrow(Long id) {
        StockTaking taking = takingMapper.selectById(id);
        if (taking == null) {
            throw new BizException("盘点单不存在");
        }
        return taking;
    }

    private void requireDraft(StockTaking taking) {
        if (!StockTaking.STATUS_DRAFT.equals(taking.getStatus())) {
            throw new BizException("盘点单已完成,不可再操作");
        }
    }
}
