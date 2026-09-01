package com.demo.erp.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.demo.erp.entity.PurchaseOrderItem;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

import java.util.List;

/**
 * 采购订单明细 Mapper
 */
public interface PurchaseOrderItemMapper extends BaseMapper<PurchaseOrderItem> {

    /**
     * 按单据查明细(带商品编码/名称/单位)
     */
    @Select("""
            SELECT i.*, p.code AS product_code, p.name AS product_name, p.unit AS unit
            FROM purchase_order_item i
            JOIN product p ON p.id = i.product_id
            WHERE i.order_id = #{orderId}
            ORDER BY i.id
            """)
    List<PurchaseOrderItem> selectByOrderId(@Param("orderId") Long orderId);
}
