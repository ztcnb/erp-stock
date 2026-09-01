package com.demo.erp.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

/**
 * 销售订单(单头)
 * 状态机: DRAFT 草稿 -> APPROVED 已审核 -> SHIPPED 已出库;DRAFT 可作废为 CANCELED
 */
@Data
@TableName("sale_order")
public class SaleOrder {

    /** 状态常量 */
    public static final String STATUS_DRAFT = "DRAFT";
    public static final String STATUS_APPROVED = "APPROVED";
    public static final String STATUS_SHIPPED = "SHIPPED";
    public static final String STATUS_CANCELED = "CANCELED";

    @TableId(type = IdType.AUTO)
    private Long id;

    private String orderNo;

    private Long customerId;

    private Long warehouseId;

    private String status;

    private BigDecimal totalQty;

    private BigDecimal totalAmount;

    /** 销售成本合计(出库时按加权平均成本计算) */
    private BigDecimal totalCost;

    /** 毛利 = 销售金额 - 销售成本 */
    private BigDecimal grossProfit;

    private String remark;

    private Long createdBy;

    private LocalDateTime createdAt;

    private LocalDateTime approvedAt;

    private LocalDateTime shippedAt;

    @TableField(exist = false)
    private String customerName;

    @TableField(exist = false)
    private String warehouseName;

    @TableField(exist = false)
    private String createdByName;

    @TableField(exist = false)
    private List<SaleOrderItem> items;
}
