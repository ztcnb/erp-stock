package com.demo.erp.dto;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.math.BigDecimal;

/**
 * 单据明细行(采购/销售通用)
 */
@Data
public class OrderItemDTO {

    @NotNull(message = "明细行商品不能为空")
    private Long productId;

    @NotNull(message = "明细行数量不能为空")
    @DecimalMin(value = "0.01", message = "明细行数量必须大于 0")
    private BigDecimal qty;

    @NotNull(message = "明细行单价不能为空")
    @DecimalMin(value = "0", message = "明细行单价不能为负")
    private BigDecimal price;
}
