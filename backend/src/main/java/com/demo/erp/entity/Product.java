package com.demo.erp.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 商品
 */
@Data
@TableName("product")
public class Product {

    @TableId(type = IdType.AUTO)
    private Long id;

    @NotBlank(message = "商品编码不能为空")
    private String code;

    @NotBlank(message = "商品名称不能为空")
    private String name;

    @NotNull(message = "商品分类不能为空")
    private Long categoryId;

    @NotBlank(message = "计量单位不能为空")
    private String unit;

    private String spec;

    /** 参考进价 */
    @NotNull(message = "参考进价不能为空")
    @DecimalMin(value = "0", message = "参考进价不能为负")
    private BigDecimal purchasePrice;

    /** 参考售价 */
    @NotNull(message = "参考售价不能为空")
    @DecimalMin(value = "0", message = "参考售价不能为负")
    private BigDecimal salePrice;

    /** 库存预警线 */
    @DecimalMin(value = "0", message = "库存预警线不能为负")
    private BigDecimal warnQty;

    /** 状态: 1 在售 / 0 停售 */
    private Integer status;

    private String remark;

    private LocalDateTime createdAt;

    /** 分类名称(列表联查用) */
    @TableField(exist = false)
    private String categoryName;
}
