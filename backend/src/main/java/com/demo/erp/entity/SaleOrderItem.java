package com.demo.erp.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.math.BigDecimal;

/**
 * 销售订单明细
 */
@Data
@TableName("sale_order_item")
public class SaleOrderItem {

    @TableId(type = IdType.AUTO)
    private Long id;

    private Long orderId;

    private Long productId;

    private BigDecimal qty;

    private BigDecimal price;

    private BigDecimal amount;

    /** 出库时的加权平均单位成本 */
    private BigDecimal costPrice;

    /** 成本金额 = 数量 * 加权平均成本 */
    private BigDecimal costAmount;

    @TableField(exist = false)
    private String productCode;

    @TableField(exist = false)
    private String productName;

    @TableField(exist = false)
    private String unit;
}
