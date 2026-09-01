package com.demo.erp.common;

/**
 * 当前登录用户信息(由 JWT 解析得到,存于 ThreadLocal)
 */
public record LoginUser(Long id, String username, String realName, String role) {

    public boolean isAdmin() {
        return "ADMIN".equals(role);
    }
}
