package com.demo.erp.controller;

import com.baomidou.mybatisplus.core.metadata.IPage;
import com.demo.erp.common.Result;
import com.demo.erp.dto.TakingCreateDTO;
import com.demo.erp.dto.TakingSaveDTO;
import com.demo.erp.entity.StockTaking;
import com.demo.erp.service.TakingService;
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
 * 库存盘点接口
 */
@RestController
@RequestMapping("/stock-takings")
@RequiredArgsConstructor
public class TakingController {

    private final TakingService takingService;

    @GetMapping
    public Result<IPage<StockTaking>> page(@RequestParam(defaultValue = "1") long page,
                                           @RequestParam(defaultValue = "10") long size,
                                           @RequestParam(required = false) String status) {
        return Result.ok(takingService.pageQuery(page, size, status));
    }

    @GetMapping("/{id}")
    public Result<StockTaking> detail(@PathVariable Long id) {
        return Result.ok(takingService.detail(id));
    }

    /** 创建盘点单(生成账面快照),返回盘点单号 */
    @PostMapping
    public Result<String> create(@Valid @RequestBody TakingCreateDTO dto) {
        return Result.ok(takingService.create(dto));
    }

    /** 保存实盘数量 */
    @PutMapping("/{id}/items")
    public Result<Void> saveItems(@PathVariable Long id, @Valid @RequestBody TakingSaveDTO dto) {
        takingService.saveItems(id, dto);
        return Result.ok();
    }

    /** 完成盘点(生成盈亏调整流水) */
    @PostMapping("/{id}/finish")
    public Result<Void> finish(@PathVariable Long id) {
        takingService.finish(id);
        return Result.ok();
    }

    @DeleteMapping("/{id}")
    public Result<Void> delete(@PathVariable Long id) {
        takingService.delete(id);
        return Result.ok();
    }
}
