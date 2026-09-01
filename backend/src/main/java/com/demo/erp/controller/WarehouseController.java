package com.demo.erp.controller;

import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.demo.erp.common.Result;
import com.demo.erp.entity.Warehouse;
import com.demo.erp.service.WarehouseService;
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
 * 仓库接口
 */
@RestController
@RequestMapping("/warehouses")
@RequiredArgsConstructor
public class WarehouseController {

    private final WarehouseService warehouseService;

    @GetMapping
    public Result<IPage<Warehouse>> page(@RequestParam(defaultValue = "1") long page,
                                         @RequestParam(defaultValue = "10") long size) {
        return Result.ok(warehouseService.page(new Page<>(page, size),
                Wrappers.<Warehouse>lambdaQuery().orderByAsc(Warehouse::getId)));
    }

    /** 全量启用仓库(下拉选择用) */
    @GetMapping("/all")
    public Result<List<Warehouse>> all() {
        return Result.ok(warehouseService.list(Wrappers.<Warehouse>lambdaQuery()
                .eq(Warehouse::getStatus, 1)
                .orderByAsc(Warehouse::getId)));
    }

    @PostMapping
    public Result<Void> create(@Valid @RequestBody Warehouse warehouse) {
        warehouse.setId(null);
        if (warehouse.getStatus() == null) {
            warehouse.setStatus(1);
        }
        warehouseService.save(warehouse);
        return Result.ok();
    }

    @PutMapping("/{id}")
    public Result<Void> update(@PathVariable Long id, @Valid @RequestBody Warehouse warehouse) {
        warehouse.setId(id);
        warehouseService.updateById(warehouse);
        return Result.ok();
    }

    @DeleteMapping("/{id}")
    public Result<Void> delete(@PathVariable Long id) {
        warehouseService.removeById(id);
        return Result.ok();
    }
}
