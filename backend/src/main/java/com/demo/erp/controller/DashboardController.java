package com.demo.erp.controller;

import com.demo.erp.common.Result;
import com.demo.erp.service.DashboardService;
import com.demo.erp.service.StockService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;

/**
 * 报表看板接口
 */
@RestController
@RequestMapping("/dashboard")
@RequiredArgsConstructor
public class DashboardController {

    private final DashboardService dashboardService;
    private final StockService stockService;

    /** 核心指标卡 */
    @GetMapping("/summary")
    public Result<Map<String, Object>> summary() {
        return Result.ok(dashboardService.summary());
    }

    /** 近 30 天销售/采购趋势 */
    @GetMapping("/trend")
    public Result<List<Map<String, Object>>> trend() {
        return Result.ok(dashboardService.trend());
    }

    /** 热销商品 TOP10 */
    @GetMapping("/top-products")
    public Result<List<Map<String, Object>>> topProducts() {
        return Result.ok(dashboardService.topProducts());
    }

    /** 分类销售占比 */
    @GetMapping("/category-share")
    public Result<List<Map<String, Object>>> categoryShare() {
        return Result.ok(dashboardService.categoryShare());
    }

    /** 库存预警(看板表格用) */
    @GetMapping("/warnings")
    public Result<List<Map<String, Object>>> warnings() {
        return Result.ok(stockService.warnings());
    }
}
