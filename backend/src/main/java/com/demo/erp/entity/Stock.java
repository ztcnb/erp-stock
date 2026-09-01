package com.demo.erp.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 实时库存(仓库 + 商品 维度,数量 + 加权平均成本)
 */
@Data
@TableName("stock")
public class Stock {

    @TableId(type = IdType.AUTO)
    private Long id;

    private Long warehouseId;

    private Long productId;

    private BigDecimal qty;

    /** 加权平均单位成本 */
    private BigDecimal avgCost;

    private LocalDateTime updatedAt;

    @TableField(exist = false)
    private String warehouseName;

    @TableField(exist = false)
    private String productCode;

    @TableField(exist = false)
    private String productName;

    @TableField(exist = false)
    private String unit;

    /** 库存金额 = 数量 * 加权平均成本(联查计算) */
    @TableField(exist = false)
    private BigDecimal amount;

    /** 预警线(联查商品表) */
    @TableField(exist = false)
    private BigDecimal warnQty;
}
