package com.demo.erp.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 系统用户
 */
@Data
@TableName("sys_user")
public class SysUser {

    @TableId(type = IdType.AUTO)
    private Long id;

    private String username;

    /** 密码(BCrypt),仅反序列化,响应中不输出 */
    @JsonProperty(access = JsonProperty.Access.WRITE_ONLY)
    private String password;

    private String realName;

    /** 角色: ADMIN / BUYER / SELLER / STOCKER */
    private String role;

    private String phone;

    /** 状态: 1 启用 / 0 停用 */
    private Integer status;

    private LocalDateTime createdAt;
}
