package com.demo.erp.controller;

import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.core.toolkit.StringUtils;
import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.demo.erp.common.Result;
import com.demo.erp.entity.Customer;
import com.demo.erp.service.CustomerService;
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
 * 客户接口
 */
@RestController
@RequestMapping("/customers")
@RequiredArgsConstructor
public class CustomerController {

    private final CustomerService customerService;

    @GetMapping
    public Result<IPage<Customer>> page(@RequestParam(defaultValue = "1") long page,
                                        @RequestParam(defaultValue = "10") long size,
                                        @RequestParam(required = false) String keyword) {
        return Result.ok(customerService.page(new Page<>(page, size), Wrappers.<Customer>lambdaQuery()
                .and(StringUtils.isNotBlank(keyword), w -> w
                        .like(Customer::getName, keyword).or()
                        .like(Customer::getCode, keyword))
                .orderByAsc(Customer::getId)));
    }

    /** 全量合作中客户(下拉选择用) */
    @GetMapping("/all")
    public Result<List<Customer>> all() {
        return Result.ok(customerService.list(Wrappers.<Customer>lambdaQuery()
                .eq(Customer::getStatus, 1)
                .orderByAsc(Customer::getId)));
    }

    @PostMapping
    public Result<Void> create(@Valid @RequestBody Customer customer) {
        customer.setId(null);
        if (customer.getStatus() == null) {
            customer.setStatus(1);
        }
        customerService.save(customer);
        return Result.ok();
    }

    @PutMapping("/{id}")
    public Result<Void> update(@PathVariable Long id, @Valid @RequestBody Customer customer) {
        customer.setId(id);
        customerService.updateById(customer);
        return Result.ok();
    }

    @DeleteMapping("/{id}")
    public Result<Void> delete(@PathVariable Long id) {
        customerService.removeById(id);
        return Result.ok();
    }
}
