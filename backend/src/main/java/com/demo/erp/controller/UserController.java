package com.demo.erp.controller;

import com.baomidou.mybatisplus.core.metadata.IPage;
import com.demo.erp.common.Result;
import com.demo.erp.common.UserContext;
import com.demo.erp.dto.UserDTO;
import com.demo.erp.entity.SysUser;
import com.demo.erp.service.UserService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * 用户管理接口(仅管理员)
 */
@RestController
@RequestMapping("/users")
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;

    @GetMapping
    public Result<IPage<SysUser>> page(@RequestParam(defaultValue = "1") long page,
                                       @RequestParam(defaultValue = "10") long size,
                                       @RequestParam(required = false) String keyword) {
        UserContext.checkAdmin();
        return Result.ok(userService.pageQuery(page, size, keyword));
    }

    @PostMapping
    public Result<Void> create(@Valid @RequestBody UserDTO dto) {
        UserContext.checkAdmin();
        userService.create(dto);
        return Result.ok();
    }

    @PutMapping("/{id}")
    public Result<Void> update(@PathVariable Long id, @Valid @RequestBody UserDTO dto) {
        UserContext.checkAdmin();
        userService.update(id, dto);
        return Result.ok();
    }

    @DeleteMapping("/{id}")
    public Result<Void> delete(@PathVariable Long id) {
        UserContext.checkAdmin();
        userService.delete(id);
        return Result.ok();
    }
}
