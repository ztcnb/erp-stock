package com.demo.erp.controller;

import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.core.toolkit.StringUtils;
import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.demo.erp.common.Result;
import com.demo.erp.entity.Supplier;
import com.demo.erp.service.SupplierService;
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

import java.util.List;

/**
 * 供应商接口
 */
@RestController
@RequestMapping("/suppliers")
@RequiredArgsConstructor
public class SupplierController {

    private final SupplierService supplierService;

    @GetMapping
    public Result<IPage<Supplier>> page(@RequestParam(defaultValue = "1") long page,
                                        @RequestParam(defaultValue = "10") long size,
                                        @RequestParam(required = false) String keyword) {
        return Result.ok(supplierService.page(new Page<>(page, size), Wrappers.<Supplier>lambdaQuery()
                .and(StringUtils.isNotBlank(keyword), w -> w
                        .like(Supplier::getName, keyword).or()
                        .like(Supplier::getCode, keyword))
                .orderByAsc(Supplier::getId)));
    }

    /** 全量合作中供应商(下拉选择用) */
    @GetMapping("/all")
    public Result<List<Supplier>> all() {
        return Result.ok(supplierService.list(Wrappers.<Supplier>lambdaQuery()
                .eq(Supplier::getStatus, 1)
                .orderByAsc(Supplier::getId)));
    }

    @PostMapping
    public Result<Void> create(@Valid @RequestBody Supplier supplier) {
        supplier.setId(null);
        if (supplier.getStatus() == null) {
            supplier.setStatus(1);
        }
        supplierService.save(supplier);
        return Result.ok();
    }

    @PutMapping("/{id}")
    public Result<Void> update(@PathVariable Long id, @Valid @RequestBody Supplier supplier) {
        supplier.setId(id);
        supplierService.updateById(supplier);
        return Result.ok();
    }

    @DeleteMapping("/{id}")
    public Result<Void> delete(@PathVariable Long id) {
        supplierService.removeById(id);
        return Result.ok();
    }
}
