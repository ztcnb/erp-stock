package com.demo.erp.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.demo.erp.entity.StockTakingItem;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

import java.util.List;

/**
 * 库存盘点明细 Mapper
 */
public interface StockTakingItemMapper extends BaseMapper<StockTakingItem> {

    /**
     * 按盘点单查明细(带商品信息)
     */
    @Select("""
            SELECT i.*, p.code AS product_code, p.name AS product_name, p.unit AS unit
            FROM stock_taking_item i
            JOIN product p ON p.id = i.product_id
            WHERE i.taking_id = #{takingId}
            ORDER BY i.id
            """)
    List<StockTakingItem> selectByTakingId(@Param("takingId") Long takingId);
}
