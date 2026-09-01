package com.demo.erp.service.impl;

import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.demo.erp.entity.Stock;
import com.demo.erp.entity.StockFlow;
import com.demo.erp.mapper.StockFlowMapper;
import com.demo.erp.mapper.StockMapper;
import com.demo.erp.service.StockService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Map;

/**
 * 库存查询服务实现
 */
@Service
@RequiredArgsConstructor
public class StockServiceImpl implements StockService {

    private final StockMapper stockMapper;
    private final StockFlowMapper flowMapper;

    @Override
    public IPage<Stock> pageQuery(long page, long size, Long warehouseId, String keyword) {
        return stockMapper.selectPageJoin(new Page<>(page, size), warehouseId, keyword);
    }

    @Override
    public IPage<StockFlow> flowPage(long page, long size, Long warehouseId, String bizType,
                                     String keyword, String startDate, String endDate) {
        return flowMapper.selectPageJoin(new Page<>(page, size), warehouseId, bizType, keyword, startDate, endDate);
    }

    @Override
    public List<Map<String, Object>> warnings() {
        return stockMapper.selectWarnings();
    }
}
