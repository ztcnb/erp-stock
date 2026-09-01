package com.demo.erp.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.demo.erp.entity.Receivable;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

/**
 * 应收账款 Mapper
 */
public interface ReceivableMapper extends BaseMapper<Receivable> {

    /**
     * 分页联查应收账款(带客户名称与未收余额)
     */
    @Select("""
            <script>
            SELECT a.*, c.name AS customer_name, (a.total_amount - a.received_amount) AS balance
            FROM receivable a
            JOIN customer c ON c.id = a.customer_id
            <where>
                <if test="status != null and status != ''">
                    AND a.status = #{status}
                </if>
                <if test="keyword != null and keyword != ''">
                    AND (a.order_no ILIKE '%' || #{keyword} || '%' OR c.name ILIKE '%' || #{keyword} || '%')
                </if>
            </where>
            ORDER BY a.created_at DESC, a.id DESC
            </script>
            """)
    IPage<Receivable> selectPageJoin(IPage<Receivable> page,
                                     @Param("status") String status,
                                     @Param("keyword") String keyword);
}
