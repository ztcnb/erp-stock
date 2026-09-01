package com.demo.erp.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;
import java.util.List;

/**
 * 库存盘点单
 * 状态: DRAFT 盘点中 -> FINISHED 已完成
 */
@Data
@TableName("stock_taking")
public class StockTaking {

    public static final String STATUS_DRAFT = "DRAFT";
    public static final String STATUS_FINISHED = "FINISHED";

    @TableId(type = IdType.AUTO)
    private Long id;

    private String takingNo;

    private Long warehouseId;

    private String status;

    private String remark;

    private Long createdBy;

    private LocalDateTime createdAt;

    private LocalDateTime finishedAt;

    @TableField(exist = false)
    private String warehouseName;

    @TableField(exist = false)
    private String createdByName;

    @TableField(exist = false)
    private List<StockTakingItem> items;
}
