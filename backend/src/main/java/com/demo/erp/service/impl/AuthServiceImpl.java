package com.demo.erp.service.impl;

import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.demo.erp.common.BizException;
import com.demo.erp.common.LoginUser;
import com.demo.erp.common.UserContext;
import com.demo.erp.config.JwtUtil;
import com.demo.erp.dto.LoginDTO;
import com.demo.erp.entity.SysUser;
import com.demo.erp.mapper.SysUserMapper;
import com.demo.erp.service.AuthService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.LinkedHashMap;
import java.util.Map;

/**
 * 认证服务实现
 */
@Service
@RequiredArgsConstructor
public class AuthServiceImpl implements AuthService {

    private static final BCryptPasswordEncoder ENCODER = new BCryptPasswordEncoder();

    private final SysUserMapper userMapper;
    private final JwtUtil jwtUtil;

    @Override
    public Map<String, Object> login(LoginDTO dto) {
        SysUser user = userMapper.selectOne(
                Wrappers.<SysUser>lambdaQuery().eq(SysUser::getUsername, dto.getUsername()));
        if (user == null || !ENCODER.matches(dto.getPassword(), user.getPassword())) {
            throw new BizException("用户名或密码错误");
        }
        if (user.getStatus() == null || user.getStatus() != 1) {
            throw new BizException("账号已被停用,请联系管理员");
        }
        LoginUser loginUser = new LoginUser(user.getId(), user.getUsername(), user.getRealName(), user.getRole());
        Map<String, Object> result = new LinkedHashMap<>();
        result.put("token", jwtUtil.createToken(loginUser));
        result.put("user", loginUser);
        return result;
    }

    @Override
    public Map<String, Object> currentUser() {
        LoginUser user = UserContext.get();
        Map<String, Object> result = new LinkedHashMap<>();
        result.put("user", user);
        return result;
    }
}
