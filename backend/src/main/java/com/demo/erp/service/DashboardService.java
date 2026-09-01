package com.demo.erp.service;

import java.util.List;
import java.util.Map;

/**
 * 报表看板服务
 */
public interface DashboardService {

    /** 核心指标卡:本月销售额/毛利/采购额、库存总额、应收应付余额 */
    Map<String, Object> summary();

    /** 近 30 天销售与采购趋势(连续日期轴) */
    List<Map<String, Object>> trend();

    /** 近 30 天热销商品 TOP10 */
    List<Map<String, Object>> topProducts();

    /** 近 30 天分类销售占比(按一级分类) */
    List<Map<String, Object>> categoryShare();
}
