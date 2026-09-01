package com.demo.erp.mapper;

import org.apache.ibatis.annotations.Select;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

/**
 * 报表看板 Mapper:聚合统计 SQL
 */
public interface DashboardMapper {

    /** 本月销售额(已出库口径) */
    @Select("""
            SELECT COALESCE(SUM(total_amount), 0) FROM sale_order
            WHERE status = 'SHIPPED' AND shipped_at >= date_trunc('month', current_date)
            """)
    BigDecimal selectMonthSaleAmount();

    /** 本月毛利(已出库口径) */
    @Select("""
            SELECT COALESCE(SUM(gross_profit), 0) FROM sale_order
            WHERE status = 'SHIPPED' AND shipped_at >= date_trunc('month', current_date)
            """)
    BigDecimal selectMonthProfit();

    /** 本月采购额(已入库口径) */
    @Select("""
            SELECT COALESCE(SUM(total_amount), 0) FROM purchase_order
            WHERE status = 'STOCKED' AND stocked_at >= date_trunc('month', current_date)
            """)
    BigDecimal selectMonthPurchaseAmount();

    /** 当前库存总额(数量 * 加权平均成本) */
    @Select("SELECT COALESCE(ROUND(SUM(qty * avg_cost), 2), 0) FROM stock")
    BigDecimal selectStockAmount();

    /** 应收余额合计 */
    @Select("SELECT COALESCE(SUM(total_amount - received_amount), 0) FROM receivable")
    BigDecimal selectReceivableBalance();

    /** 应付余额合计 */
    @Select("SELECT COALESCE(SUM(total_amount - paid_amount), 0) FROM payable")
    BigDecimal selectPayableBalance();

    /** 近 30 天销售/采购趋势(按天,连续日期轴) */
    @Select("""
            SELECT to_char(d.day, 'MM-DD') AS day,
                   COALESCE(s.amt, 0) AS sale_amount,
                   COALESCE(p.amt, 0) AS purchase_amount
            FROM generate_series(current_date - interval '29 day', current_date, interval '1 day') AS d(day)
            LEFT JOIN (
                SELECT date(shipped_at) AS dt, SUM(total_amount) AS amt
                FROM sale_order WHERE status = 'SHIPPED' GROUP BY date(shipped_at)
            ) s ON s.dt = d.day::date
            LEFT JOIN (
                SELECT date(stocked_at) AS dt, SUM(total_amount) AS amt
                FROM purchase_order WHERE status = 'STOCKED' GROUP BY date(stocked_at)
            ) p ON p.dt = d.day::date
            ORDER BY d.day
            """)
    List<Map<String, Object>> selectTrend();

    /** 近 30 天热销商品 TOP10(按销售额) */
    @Select("""
            SELECT p.name, SUM(i.qty) AS qty, SUM(i.amount) AS amount
            FROM sale_order_item i
            JOIN sale_order o ON o.id = i.order_id AND o.status = 'SHIPPED'
            JOIN product p ON p.id = i.product_id
            WHERE o.shipped_at >= current_date - interval '30 day'
            GROUP BY p.name
            ORDER BY SUM(i.amount) DESC
            LIMIT 10
            """)
    List<Map<String, Object>> selectTopProducts();

    /** 近 30 天分类销售占比(按一级分类归集,递归 CTE 找根分类) */
    @Select("""
            WITH RECURSIVE cat AS (
                SELECT id, id AS root_id, name AS root_name FROM product_category WHERE parent_id = 0
                UNION ALL
                SELECT c.id, cat.root_id, cat.root_name
                FROM product_category c JOIN cat ON c.parent_id = cat.id
            )
            SELECT cat.root_name AS name, SUM(i.amount) AS value
            FROM sale_order_item i
            JOIN sale_order o ON o.id = i.order_id AND o.status = 'SHIPPED'
            JOIN product p ON p.id = i.product_id
            JOIN cat ON cat.id = p.category_id
            WHERE o.shipped_at >= current_date - interval '30 day'
            GROUP BY cat.root_name
            ORDER BY SUM(i.amount) DESC
            """)
    List<Map<String, Object>> selectCategoryShare();
}
