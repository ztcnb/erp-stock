package com.demo.erp.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import jakarta.validation.constraints.NotBlank;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 供应商
 */
@Data
@TableName("supplier")
public class Supplier {

    @TableId(type = IdType.AUTO)
    private Long id;

    @NotBlank(message = "供应商编码不能为空")
    private String code;

    @NotBlank(message = "供应商名称不能为空")
    private String name;

    private String contact;

    private String phone;

    private String address;

    private String remark;

    /** 状态: 1 合作中 / 0 已停用 */
    private Integer status;

    private LocalDateTime createdAt;
}
