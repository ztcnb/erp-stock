package com.demo.erp.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.demo.erp.entity.SaleOrder;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

/**
 * 销售订单 Mapper
 */
public interface SaleOrderMapper extends BaseMapper<SaleOrder> {

    /**
     * 分页联查销售单(带客户/仓库/制单人名称)
     */
    @Select("""
            <script>
            SELECT o.*, c.name AS customer_name, w.name AS warehouse_name, u.real_name AS created_by_name
            FROM sale_order o
            JOIN customer c ON c.id = o.customer_id
            JOIN warehouse w ON w.id = o.warehouse_id
            LEFT JOIN sys_user u ON u.id = o.created_by
            <where>
                <if test="keyword != null and keyword != ''">
                    AND (o.order_no ILIKE '%' || #{keyword} || '%' OR c.name ILIKE '%' || #{keyword} || '%')
                </if>
                <if test="status != null and status != ''">
                    AND o.status = #{status}
                </if>
                <if test="startDate != null and startDate != ''">
                    AND o.created_at &gt;= CAST(#{startDate} AS timestamp)
                </if>
                <if test="endDate != null and endDate != ''">
                    AND o.created_at &lt; CAST(#{endDate} AS timestamp) + interval '1 day'
                </if>
            </where>
            ORDER BY o.created_at DESC, o.id DESC
            </script>
            """)
    IPage<SaleOrder> selectPageJoin(IPage<SaleOrder> page,
                                    @Param("keyword") String keyword,
                                    @Param("status") String status,
                                    @Param("startDate") String startDate,
                                    @Param("endDate") String endDate);

    /**
     * 查询指定前缀下最大的单号(用于生成当日流水号)
     */
    @Select("SELECT max(order_no) FROM sale_order WHERE order_no LIKE #{prefix} || '%'")
    String selectMaxNo(@Param("prefix") String prefix);
}
