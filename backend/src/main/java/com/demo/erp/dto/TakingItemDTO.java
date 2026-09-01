package com.demo.erp.dto;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.math.BigDecimal;

/**
 * 盘点明细实盘录入
 */
@Data
public class TakingItemDTO {

    @NotNull(message = "明细 id 不能为空")
    private Long id;

    @NotNull(message = "实盘数量不能为空")
    @DecimalMin(value = "0", message = "实盘数量不能为负")
    private BigDecimal actualQty;
}
