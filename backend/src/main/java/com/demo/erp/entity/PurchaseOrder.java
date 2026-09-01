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
 * 采购订单(单头)
 * 状态机: DRAFT 草稿 -> APPROVED 已审核 -> STOCKED 已入库;DRAFT 可作废为 CANCELED
 */
@Data
@TableName("purchase_order")
public class PurchaseOrder {

    /** 状态常量 */
    public static final String STATUS_DRAFT = "DRAFT";
    public static final String STATUS_APPROVED = "APPROVED";
    public static final String STATUS_STOCKED = "STOCKED";
    public static final String STATUS_CANCELED = "CANCELED";

    @TableId(type = IdType.AUTO)
    private Long id;

    private String orderNo;

    private Long supplierId;

    private Long warehouseId;

    private String status;

    private BigDecimal totalQty;

    private BigDecimal totalAmount;

    private String remark;

    private Long createdBy;

    private LocalDateTime createdAt;

    private LocalDateTime approvedAt;

    private LocalDateTime stockedAt;

    @TableField(exist = false)
    private String supplierName;

    @TableField(exist = false)
    private String warehouseName;

    @TableField(exist = false)
    private String createdByName;

    @TableField(exist = false)
    private List<PurchaseOrderItem> items;
}
