package com.demo.erp.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.demo.erp.entity.StockTaking;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

/**
 * 库存盘点单 Mapper
 */
public interface StockTakingMapper extends BaseMapper<StockTaking> {

    /**
     * 分页联查盘点单(带仓库/制单人名称)
     */
    @Select("""
            <script>
            SELECT t.*, w.name AS warehouse_name, u.real_name AS created_by_name
            FROM stock_taking t
            JOIN warehouse w ON w.id = t.warehouse_id
            LEFT JOIN sys_user u ON u.id = t.created_by
            <where>
                <if test="status != null and status != ''">
                    AND t.status = #{status}
                </if>
            </where>
            ORDER BY t.created_at DESC, t.id DESC
            </script>
            """)
    IPage<StockTaking> selectPageJoin(IPage<StockTaking> page, @Param("status") String status);

    /**
     * 查询指定前缀下最大的盘点单号
     */
    @Select("SELECT max(taking_no) FROM stock_taking WHERE taking_no LIKE #{prefix} || '%'")
    String selectMaxNo(@Param("prefix") String prefix);
}
