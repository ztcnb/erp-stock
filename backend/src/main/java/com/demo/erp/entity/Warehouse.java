package com.demo.erp.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import jakarta.validation.constraints.NotBlank;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 仓库
 */
@Data
@TableName("warehouse")
public class Warehouse {

    @TableId(type = IdType.AUTO)
    private Long id;

    @NotBlank(message = "仓库编码不能为空")
    private String code;

    @NotBlank(message = "仓库名称不能为空")
    private String name;

    private String location;

    private String remark;

    /** 状态: 1 启用 / 0 停用 */
    private Integer status;

    private LocalDateTime createdAt;
}
