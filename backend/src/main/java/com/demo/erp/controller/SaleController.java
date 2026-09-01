package com.demo.erp.controller;

import com.baomidou.mybatisplus.core.metadata.IPage;
import com.demo.erp.common.Result;
import com.demo.erp.dto.SaleOrderDTO;
import com.demo.erp.entity.SaleOrder;
import com.demo.erp.service.SaleService;
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
 * 销售管理接口
 */
@RestController
@RequestMapping("/sale-orders")
@RequiredArgsConstructor
public class SaleController {

    private final SaleService saleService;

    @GetMapping
    public Result<IPage<SaleOrder>> page(@RequestParam(defaultValue = "1") long page,
                                         @RequestParam(defaultValue = "10") long size,
                                         @RequestParam(required = false) String keyword,
                                         @RequestParam(required = false) String status,
                                         @RequestParam(required = false) String startDate,
                                         @RequestParam(required = false) String endDate) {
        return Result.ok(saleService.pageQuery(page, size, keyword, status, startDate, endDate));
    }

    @GetMapping("/{id}")
    public Result<SaleOrder> detail(@PathVariable Long id) {
        return Result.ok(saleService.detail(id));
    }

    /** 创建草稿单,返回单号 */
    @PostMapping
    public Result<String> create(@Valid @RequestBody SaleOrderDTO dto) {
        return Result.ok(saleService.create(dto));
    }

    /** 编辑草稿单 */
    @PutMapping("/{id}")
    public Result<Void> update(@PathVariable Long id, @Valid @RequestBody SaleOrderDTO dto) {
        saleService.update(id, dto);
        return Result.ok();
    }

    /** 审核(校验库存充足) */
    @PostMapping("/{id}/approve")
    public Result<Void> approve(@PathVariable Long id) {
        saleService.approve(id);
        return Result.ok();
    }

    /** 作废 */
    @PostMapping("/{id}/cancel")
    public Result<Void> cancel(@PathVariable Long id) {
        saleService.cancel(id);
        return Result.ok();
    }

    /** 出库 */
    @PostMapping("/{id}/outbound")
    public Result<Void> outbound(@PathVariable Long id) {
        saleService.outbound(id);
        return Result.ok();
    }

    /** 删除草稿/已作废单据 */
    @DeleteMapping("/{id}")
    public Result<Void> delete(@PathVariable Long id) {
        saleService.delete(id);
        return Result.ok();
    }
}
