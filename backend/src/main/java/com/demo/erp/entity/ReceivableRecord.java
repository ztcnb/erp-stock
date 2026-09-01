package com.demo.erp.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 收款记录(支持部分核销)
 */
@Data
@TableName("receivable_record")
public class ReceivableRecord {

    @TableId(type = IdType.AUTO)
    private Long id;

    private Long receivableId;

    private BigDecimal amount;

    private String receiveMethod;

    private String remark;

    private Long createdBy;

    private LocalDateTime createdAt;
}
