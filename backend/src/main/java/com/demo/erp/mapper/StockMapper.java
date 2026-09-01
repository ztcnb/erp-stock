package com.demo.erp.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.demo.erp.entity.Stock;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;
import org.apache.ibatis.annotations.Update;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

/**
 * 库存 Mapper
 */
public interface StockMapper extends BaseMapper<Stock> {

    /**
     * 分页联查库存(带仓库/商品信息与库存金额)
     */
    @Select("""
            <script>
            SELECT s.*, w.name AS warehouse_name, p.code AS product_code, p.name AS product_name,
                   p.unit AS unit, p.warn_qty AS warn_qty,
                   ROUND(s.qty * s.avg_cost, 2) AS amount
            FROM stock s
            JOIN warehouse w ON w.id = s.warehouse_id
            JOIN product p ON p.id = s.product_id
            <where>
                <if test="warehouseId != null">
                    AND s.warehouse_id = #{warehouseId}
                </if>
                <if test="keyword != null and keyword != ''">
                    AND (p.name ILIKE '%' || #{keyword} || '%' OR p.code ILIKE '%' || #{keyword} || '%')
                </if>
            </where>
            ORDER BY s.warehouse_id, p.code
            </script>
            """)
    IPage<Stock> selectPageJoin(IPage<Stock> page,
                                @Param("warehouseId") Long warehouseId,
                                @Param("keyword") String keyword);

    /**
     * 行级锁定查询库存(入库/盘盈路径,避免并发下加权成本计算错乱)
     */
    @Select("SELECT * FROM stock WHERE warehouse_id = #{warehouseId} AND product_id = #{productId} FOR UPDATE")
    Stock selectForUpdate(@Param("warehouseId") Long warehouseId, @Param("productId") Long productId);

    /**
     * 条件扣减库存:仅当现存数量足够时才扣减,返回受影响行数(0 表示库存不足)。
     * 配合表上的 CHECK (qty >= 0) 约束,双重保证库存不出负。
     */
    @Update("""
            UPDATE stock SET qty = qty - #{qty}, updated_at = now()
            WHERE warehouse_id = #{warehouseId} AND product_id = #{productId} AND qty >= #{qty}
            """)
    int deductQty(@Param("warehouseId") Long warehouseId,
                  @Param("productId") Long productId,
                  @Param("qty") BigDecimal qty);

    /**
     * 库存预警列表:商品总库存(各仓合计)低于预警线
     */
    @Select("""
            SELECT p.id AS product_id, p.code, p.name, p.unit, p.warn_qty,
                   COALESCE(SUM(s.qty), 0) AS total_qty,
                   ROUND(COALESCE(SUM(s.qty * s.avg_cost), 0), 2) AS total_amount
            FROM product p
            LEFT JOIN stock s ON s.product_id = p.id
            WHERE p.status = 1 AND p.warn_qty > 0
            GROUP BY p.id, p.code, p.name, p.unit, p.warn_qty
            HAVING COALESCE(SUM(s.qty), 0) < p.warn_qty
            ORDER BY COALESCE(SUM(s.qty), 0) / p.warn_qty
            """)
    List<Map<String, Object>> selectWarnings();
}
