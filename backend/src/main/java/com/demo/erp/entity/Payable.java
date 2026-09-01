package com.demo.erp.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 应付账款(采购入库时生成)
 * 状态: UNPAID 未付款 / PARTIAL 部分付款 / PAID 已结清
 */
@Data
@TableName("payable")
public class Payable {

    public static final String STATUS_UNPAID = "UNPAID";
    public static final String STATUS_PARTIAL = "PARTIAL";
    public static final String STATUS_PAID = "PAID";

    @TableId(type = IdType.AUTO)
    private Long id;

    /** 来源采购单号 */
    private String orderNo;

    private Long supplierId;

    private BigDecimal totalAmount;

    private BigDecimal paidAmount;

    private String status;

    private LocalDateTime createdAt;

    @TableField(exist = false)
    private String supplierName;

    /** 未付余额(联查计算) */
    @TableField(exist = false)
    private BigDecimal balance;
}
