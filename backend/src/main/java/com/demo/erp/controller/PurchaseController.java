package com.demo.erp.controller;

import com.baomidou.mybatisplus.core.metadata.IPage;
import com.demo.erp.common.Result;
import com.demo.erp.dto.PurchaseOrderDTO;
import com.demo.erp.entity.PurchaseOrder;
import com.demo.erp.service.PurchaseService;
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
 * 采购管理接口
 */
@RestController
@RequestMapping("/purchase-orders")
@RequiredArgsConstructor
public class PurchaseController {

    private final PurchaseService purchaseService;

    @GetMapping
    public Result<IPage<PurchaseOrder>> page(@RequestParam(defaultValue = "1") long page,
                                             @RequestParam(defaultValue = "10") long size,
                                             @RequestParam(required = false) String keyword,
                                             @RequestParam(required = false) String status,
                                             @RequestParam(required = false) String startDate,
                                             @RequestParam(required = false) String endDate) {
        return Result.ok(purchaseService.pageQuery(page, size, keyword, status, startDate, endDate));
    }

    @GetMapping("/{id}")
    public Result<PurchaseOrder> detail(@PathVariable Long id) {
        return Result.ok(purchaseService.detail(id));
    }

    /** 创建草稿单,返回单号 */
    @PostMapping
    public Result<String> create(@Valid @RequestBody PurchaseOrderDTO dto) {
        return Result.ok(purchaseService.create(dto));
    }

    /** 编辑草稿单 */
    @PutMapping("/{id}")
    public Result<Void> update(@PathVariable Long id, @Valid @RequestBody PurchaseOrderDTO dto) {
        purchaseService.update(id, dto);
        return Result.ok();
    }

    /** 审核 */
    @PostMapping("/{id}/approve")
    public Result<Void> approve(@PathVariable Long id) {
        purchaseService.approve(id);
        return Result.ok();
    }

    /** 作废 */
    @PostMapping("/{id}/cancel")
    public Result<Void> cancel(@PathVariable Long id) {
        purchaseService.cancel(id);
        return Result.ok();
    }

    /** 入库 */
    @PostMapping("/{id}/inbound")
    public Result<Void> inbound(@PathVariable Long id) {
        purchaseService.inbound(id);
        return Result.ok();
    }

    /** 删除草稿/已作废单据 */
    @DeleteMapping("/{id}")
    public Result<Void> delete(@PathVariable Long id) {
        purchaseService.delete(id);
        return Result.ok();
    }
}
