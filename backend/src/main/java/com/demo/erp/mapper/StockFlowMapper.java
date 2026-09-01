package com.demo.erp.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.demo.erp.entity.StockFlow;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

/**
 * 库存流水 Mapper
 */
public interface StockFlowMapper extends BaseMapper<StockFlow> {

    /**
     * 分页联查库存流水
     */
    @Select("""
            <script>
            SELECT f.*, w.name AS warehouse_name, p.code AS product_code, p.name AS product_name, p.unit AS unit
            FROM stock_flow f
            JOIN warehouse w ON w.id = f.warehouse_id
            JOIN product p ON p.id = f.product_id
            <where>
                <if test="warehouseId != null">
                    AND f.warehouse_id = #{warehouseId}
                </if>
                <if test="bizType != null and bizType != ''">
                    AND f.biz_type = #{bizType}
                </if>
                <if test="keyword != null and keyword != ''">
                    AND (p.name ILIKE '%' || #{keyword} || '%' OR p.code ILIKE '%' || #{keyword} || '%'
                         OR f.biz_no ILIKE '%' || #{keyword} || '%')
                </if>
                <if test="startDate != null and startDate != ''">
                    AND f.created_at &gt;= CAST(#{startDate} AS timestamp)
                </if>
                <if test="endDate != null and endDate != ''">
                    AND f.created_at &lt; CAST(#{endDate} AS timestamp) + interval '1 day'
                </if>
            </where>
            ORDER BY f.created_at DESC, f.id DESC
            </script>
            """)
    IPage<StockFlow> selectPageJoin(IPage<StockFlow> page,
                                    @Param("warehouseId") Long warehouseId,
                                    @Param("bizType") String bizType,
                                    @Param("keyword") String keyword,
                                    @Param("startDate") String startDate,
                                    @Param("endDate") String endDate);
}
