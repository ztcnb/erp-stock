package com.demo.erp.controller;

import com.baomidou.mybatisplus.core.metadata.IPage;
import com.demo.erp.common.Result;
import com.demo.erp.entity.Stock;
import com.demo.erp.entity.StockFlow;
import com.demo.erp.service.StockService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;

/**
 * 库存查询接口(实时库存 / 流水 / 预警)
 */
@RestController
@RequestMapping("/stocks")
@RequiredArgsConstructor
public class StockController {

    private final StockService stockService;

    /** 实时库存分页 */
    @GetMapping
    public Result<IPage<Stock>> page(@RequestParam(defaultValue = "1") long page,
                                     @RequestParam(defaultValue = "10") long size,
                                     @RequestParam(required = false) Long warehouseId,
                                     @RequestParam(required = false) String keyword) {
        return Result.ok(stockService.pageQuery(page, size, warehouseId, keyword));
    }

    /** 库存流水分页 */
    @GetMapping("/flows")
    public Result<IPage<StockFlow>> flows(@RequestParam(defaultValue = "1") long page,
                                          @RequestParam(defaultValue = "10") long size,
                                          @RequestParam(required = false) Long warehouseId,
                                          @RequestParam(required = false) String bizType,
                                          @RequestParam(required = false) String keyword,
                                          @RequestParam(required = false) String startDate,
                                          @RequestParam(required = false) String endDate) {
        return Result.ok(stockService.flowPage(page, size, warehouseId, bizType, keyword, startDate, endDate));
    }

    /** 库存预警列表 */
    @GetMapping("/warnings")
    public Result<List<Map<String, Object>>> warnings() {
        return Result.ok(stockService.warnings());
    }
}
