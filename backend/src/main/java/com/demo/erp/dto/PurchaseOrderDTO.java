package com.demo.erp.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Data;

import java.util.List;

/**
 * 采购订单创建/编辑请求
 */
@Data
public class PurchaseOrderDTO {

    @NotNull(message = "供应商不能为空")
    private Long supplierId;

    @NotNull(message = "入库仓库不能为空")
    private Long warehouseId;

    @Size(max = 200, message = "备注最长 200 字")
    private String remark;

    @NotEmpty(message = "至少需要一行明细")
    @Valid
    private List<OrderItemDTO> items;
}
