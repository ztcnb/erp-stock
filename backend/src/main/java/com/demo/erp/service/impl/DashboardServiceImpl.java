package com.demo.erp.service.impl;

import com.demo.erp.mapper.DashboardMapper;
import com.demo.erp.service.DashboardService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * 报表看板服务实现
 */
@Service
@RequiredArgsConstructor
public class DashboardServiceImpl implements DashboardService {

    private final DashboardMapper dashboardMapper;

    @Override
    public Map<String, Object> summary() {
        Map<String, Object> result = new LinkedHashMap<>();
        result.put("monthSaleAmount", dashboardMapper.selectMonthSaleAmount());
        result.put("monthProfit", dashboardMapper.selectMonthProfit());
        result.put("monthPurchaseAmount", dashboardMapper.selectMonthPurchaseAmount());
        result.put("stockAmount", dashboardMapper.selectStockAmount());
        result.put("receivableBalance", dashboardMapper.selectReceivableBalance());
        result.put("payableBalance", dashboardMapper.selectPayableBalance());
        return result;
    }

    @Override
    public List<Map<String, Object>> trend() {
        return dashboardMapper.selectTrend();
    }

    @Override
    public List<Map<String, Object>> topProducts() {
        return dashboardMapper.selectTopProducts();
    }

    @Override
    public List<Map<String, Object>> categoryShare() {
        return dashboardMapper.selectCategoryShare();
    }
}
