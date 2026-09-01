package com.demo.erp.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.demo.erp.entity.Payable;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

/**
 * 应付账款 Mapper
 */
public interface PayableMapper extends BaseMapper<Payable> {

    /**
     * 分页联查应付账款(带供应商名称与未付余额)
     */
    @Select("""
            <script>
            SELECT a.*, s.name AS supplier_name, (a.total_amount - a.paid_amount) AS balance
            FROM payable a
            JOIN supplier s ON s.id = a.supplier_id
            <where>
                <if test="status != null and status != ''">
                    AND a.status = #{status}
                </if>
                <if test="keyword != null and keyword != ''">
                    AND (a.order_no ILIKE '%' || #{keyword} || '%' OR s.name ILIKE '%' || #{keyword} || '%')
                </if>
            </where>
            ORDER BY a.created_at DESC, a.id DESC
            </script>
            """)
    IPage<Payable> selectPageJoin(IPage<Payable> page,
                                  @Param("status") String status,
                                  @Param("keyword") String keyword);
}
