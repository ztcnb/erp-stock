package com.demo.erp.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotEmpty;
import lombok.Data;

import java.util.List;

/**
 * 盘点实盘数量批量保存请求
 */
@Data
public class TakingSaveDTO {

    @NotEmpty(message = "至少需要一行盘点明细")
    @Valid
    private List<TakingItemDTO> items;
}
