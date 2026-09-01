package com.demo.erp.service;

import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.service.IService;
import com.demo.erp.dto.UserDTO;
import com.demo.erp.entity.SysUser;

/**
 * 用户管理服务(仅管理员)
 */
public interface UserService extends IService<SysUser> {

    IPage<SysUser> pageQuery(long page, long size, String keyword);

    void create(UserDTO dto);

    void update(Long id, UserDTO dto);

    void delete(Long id);
}
