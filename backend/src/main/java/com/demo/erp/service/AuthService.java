package com.demo.erp.service;

import com.demo.erp.dto.LoginDTO;

import java.util.Map;

/**
 * 认证服务
 */
public interface AuthService {

    /** 登录:校验账号密码,返回 token 与用户信息 */
    Map<String, Object> login(LoginDTO dto);

    /** 获取当前登录用户信息 */
    Map<String, Object> currentUser();
}
