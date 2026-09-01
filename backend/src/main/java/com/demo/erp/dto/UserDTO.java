package com.demo.erp.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Data;

/**
 * 用户创建/编辑请求
 */
@Data
public class UserDTO {

    @NotBlank(message = "用户名不能为空")
    @Size(max = 50, message = "用户名最长 50 字")
    private String username;

    /** 创建时必填;编辑时留空表示不修改密码 */
    private String password;

    @NotBlank(message = "姓名不能为空")
    private String realName;

    @NotBlank(message = "角色不能为空")
    @Pattern(regexp = "ADMIN|BUYER|SELLER|STOCKER", message = "非法角色")
    private String role;

    private String phone;

    private Integer status;
}
