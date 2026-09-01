package com.demo.erp.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 应收账款(销售出库时生成)
 * 状态: UNRECEIVED 未收款 / PARTIAL 部分收款 / RECEIVED 已结清
 */
@Data
@TableName("receivable")
public class Receivable {

    public static final String STATUS_UNRECEIVED = "UNRECEIVED";
    public static final String STATUS_PARTIAL = "PARTIAL";
    public static final String STATUS_RECEIVED = "RECEIVED";

    @TableId(type = IdType.AUTO)
    private Long id;

    /** 来源销售单号 */
    private String orderNo;

    private Long customerId;

    private BigDecimal totalAmount;

    private BigDecimal receivedAmount;

    private String status;

    private LocalDateTime createdAt;

    @TableField(exist = false)
    private String customerName;

    /** 未收余额(联查计算) */
    @TableField(exist = false)
    private BigDecimal balance;
}
