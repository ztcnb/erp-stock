package com.demo.erp.service;

import com.baomidou.mybatisplus.core.metadata.IPage;
import com.demo.erp.entity.Stock;
import com.demo.erp.entity.StockFlow;

import java.util.List;
import java.util.Map;

/**
 * 库存查询服务
 */
public interface StockService {

    /** 实时库存分页(按仓库/商品过滤,含库存金额) */
    IPage<Stock> pageQuery(long page, long size, Long warehouseId, String keyword);

    /** 库存流水分页 */
    IPage<StockFlow> flowPage(long page, long size, Long warehouseId, String bizType,
                              String keyword, String startDate, String endDate);

    /** 库存预警列表(商品总库存低于预警线) */
    List<Map<String, Object>> warnings();
}
