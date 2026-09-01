package com.demo.erp.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.math.BigDecimal;

/**
 * 库存盘点明细
 */
@Data
@TableName("stock_taking_item")
public class StockTakingItem {

    @TableId(type = IdType.AUTO)
    private Long id;

    private Long takingId;

    private Long productId;

    /** 账面数量(盘点时的库存快照) */
    private BigDecimal bookQty;

    /** 实盘数量(未录入为 null) */
    private BigDecimal actualQty;

    /** 盈亏数量 = 实盘 - 账面 */
    private BigDecimal diffQty;

    @TableField(exist = false)
    private String productCode;

    @TableField(exist = false)
    private String productName;

    @TableField(exist = false)
    private String unit;
}
