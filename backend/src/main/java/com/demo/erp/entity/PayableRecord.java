package com.demo.erp.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 付款记录(支持部分核销)
 */
@Data
@TableName("payable_record")
public class PayableRecord {

    @TableId(type = IdType.AUTO)
    private Long id;

    private Long payableId;

    private BigDecimal amount;

    private String payMethod;

    private String remark;

    private Long createdBy;

    private LocalDateTime createdAt;
}
