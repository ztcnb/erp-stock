package com.demo.erp.dto;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Data;

/**
 * 创建盘点单请求:按仓库对当前有库存记录的商品生成账面快照
 */
@Data
public class TakingCreateDTO {

    @NotNull(message = "盘点仓库不能为空")
    private Long warehouseId;

    @Size(max = 200, message = "备注最长 200 字")
    private String remark;
}
