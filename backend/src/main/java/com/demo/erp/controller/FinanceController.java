package com.demo.erp.controller;

import com.baomidou.mybatisplus.core.metadata.IPage;
import com.demo.erp.common.Result;
import com.demo.erp.dto.SettleDTO;
import com.demo.erp.entity.Payable;
import com.demo.erp.entity.PayableRecord;
import com.demo.erp.entity.Receivable;
import com.demo.erp.entity.ReceivableRecord;
import com.demo.erp.service.FinanceService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * 财务接口(应付付款 / 应收收款)
 */
@RestController
@RequiredArgsConstructor
public class FinanceController {

    private final FinanceService financeService;

    // -------- 应付账款 --------

    @GetMapping("/payables")
    public Result<IPage<Payable>> payablePage(@RequestParam(defaultValue = "1") long page,
                                              @RequestParam(defaultValue = "10") long size,
                                              @RequestParam(required = false) String status,
                                              @RequestParam(required = false) String keyword) {
        return Result.ok(financeService.payablePage(page, size, status, keyword));
    }

    /** 付款记录 */
    @GetMapping("/payables/{id}/records")
    public Result<List<PayableRecord>> payableRecords(@PathVariable Long id) {
        return Result.ok(financeService.payableRecords(id));
    }

    /** 付款登记(支持部分核销) */
    @PostMapping("/payables/{id}/pay")
    public Result<Void> pay(@PathVariable Long id, @Valid @RequestBody SettleDTO dto) {
        financeService.pay(id, dto);
        return Result.ok();
    }

    // -------- 应收账款 --------

    @GetMapping("/receivables")
    public Result<IPage<Receivable>> receivablePage(@RequestParam(defaultValue = "1") long page,
                                                    @RequestParam(defaultValue = "10") long size,
                                                    @RequestParam(required = false) String status,
                                                    @RequestParam(required = false) String keyword) {
        return Result.ok(financeService.receivablePage(page, size, status, keyword));
    }

    /** 收款记录 */
    @GetMapping("/receivables/{id}/records")
    public Result<List<ReceivableRecord>> receivableRecords(@PathVariable Long id) {
        return Result.ok(financeService.receivableRecords(id));
    }

    /** 收款登记(支持部分核销) */
    @PostMapping("/receivables/{id}/receive")
    public Result<Void> receive(@PathVariable Long id, @Valid @RequestBody SettleDTO dto) {
        financeService.receive(id, dto);
        return Result.ok();
    }
}
