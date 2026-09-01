package com.demo.erp.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 库存流水
 */
@Data
@TableName("stock_flow")
public class StockFlow {

    /** 业务类型常量 */
    public static final String TYPE_PURCHASE_IN = "PURCHASE_IN";
    public static final String TYPE_SALE_OUT = "SALE_OUT";
    public static final String TYPE_TAKING_GAIN = "TAKING_GAIN";
    public static final String TYPE_TAKING_LOSS = "TAKING_LOSS";

    @TableId(type = IdType.AUTO)
    private Long id;

    private Long warehouseId;

    private Long productId;

    /** 业务类型: PURCHASE_IN 采购入库 / SALE_OUT 销售出库 / TAKING_GAIN 盘盈 / TAKING_LOSS 盘亏 */
    private String bizType;

    /** 来源单据编号 */
    private String bizNo;

    /** 数量变动(入库为正,出库为负) */
    private BigDecimal qtyChange;

    /** 变动后结存数量 */
    private BigDecimal qtyAfter;

    /** 单价(入库为采购价,出库为加权平均成本) */
    private BigDecimal price;

    private BigDecimal amount;

    private String remark;

    private LocalDateTime createdAt;

    @TableField(exist = false)
    private String warehouseName;

    @TableField(exist = false)
    private String productCode;

    @TableField(exist = false)
    private String productName;

    @TableField(exist = false)
    private String unit;
}
