package com.demo.erp.service.impl;

import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.core.toolkit.StringUtils;
import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.demo.erp.common.BizException;
import com.demo.erp.common.UserContext;
import com.demo.erp.dto.UserDTO;
import com.demo.erp.entity.SysUser;
import com.demo.erp.mapper.SysUserMapper;
import com.demo.erp.service.UserService;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;

/**
 * 用户管理服务实现
 */
@Service
public class UserServiceImpl extends ServiceImpl<SysUserMapper, SysUser> implements UserService {

    private static final BCryptPasswordEncoder ENCODER = new BCryptPasswordEncoder();

    @Override
    public IPage<SysUser> pageQuery(long page, long size, String keyword) {
        return this.page(new Page<>(page, size), Wrappers.<SysUser>lambdaQuery()
                .and(StringUtils.isNotBlank(keyword), w -> w
                        .like(SysUser::getUsername, keyword).or()
                        .like(SysUser::getRealName, keyword))
                .orderByAsc(SysUser::getId));
    }

    @Override
    public void create(UserDTO dto) {
        SysUser user = new SysUser();
        user.setUsername(dto.getUsername());
        // 未填写密码时默认 123456
        String rawPwd = StringUtils.isBlank(dto.getPassword()) ? "123456" : dto.getPassword();
        user.setPassword(ENCODER.encode(rawPwd));
        user.setRealName(dto.getRealName());
        user.setRole(dto.getRole());
        user.setPhone(dto.getPhone());
        user.setStatus(dto.getStatus() == null ? 1 : dto.getStatus());
        this.save(user);
    }

    @Override
    public void update(Long id, UserDTO dto) {
        SysUser user = this.getById(id);
        if (user == null) {
            throw new BizException("用户不存在");
        }
        user.setUsername(dto.getUsername());
        user.setRealName(dto.getRealName());
        user.setRole(dto.getRole());
        user.setPhone(dto.getPhone());
        if (dto.getStatus() != null) {
            user.setStatus(dto.getStatus());
        }
        // 密码留空表示不修改
        if (StringUtils.isNotBlank(dto.getPassword())) {
            user.setPassword(ENCODER.encode(dto.getPassword()));
        }
        this.updateById(user);
    }

    @Override
    public void delete(Long id) {
        SysUser user = this.getById(id);
        if (user == null) {
            throw new BizException("用户不存在");
        }
        if ("admin".equals(user.getUsername())) {
            throw new BizException("内置管理员账号不允许删除");
        }
        if (id.equals(UserContext.get().id())) {
            throw new BizException("不能删除当前登录账号");
        }
        this.removeById(id);
    }
}
