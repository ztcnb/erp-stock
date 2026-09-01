package com.demo.erp.dto;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Data;

import java.math.BigDecimal;

/**
 * 付款/收款登记请求
 */
@Data
public class SettleDTO {

    @NotNull(message = "金额不能为空")
    @DecimalMin(value = "0.01", message = "金额必须大于 0")
    private BigDecimal amount;

    /** 结算方式:银行转账/现金/微信收款/支付宝/承兑汇票等 */
    @Size(max = 20, message = "结算方式最长 20 字")
    private String method;

    @Size(max = 200, message = "备注最长 200 字")
    private String remark;
}
