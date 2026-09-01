package com.demo.erp.controller;

import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.demo.erp.common.Result;
import com.demo.erp.entity.Product;
import com.demo.erp.service.ProductService;
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
 * 商品接口
 */
@RestController
@RequestMapping("/products")
@RequiredArgsConstructor
public class ProductController {

    private final ProductService productService;

    @GetMapping
    public Result<IPage<Product>> page(@RequestParam(defaultValue = "1") long page,
                                       @RequestParam(defaultValue = "10") long size,
                                       @RequestParam(required = false) String keyword,
                                       @RequestParam(required = false) Long categoryId) {
        return Result.ok(productService.pageQuery(page, size, keyword, categoryId));
    }

    /** 全量在售商品(单据明细选择器用) */
    @GetMapping("/all")
    public Result<List<Product>> all() {
        return Result.ok(productService.list(Wrappers.<Product>lambdaQuery()
                .eq(Product::getStatus, 1)
                .orderByAsc(Product::getCode)));
    }

    @PostMapping
    public Result<Void> create(@Valid @RequestBody Product product) {
        product.setId(null);
        if (product.getStatus() == null) {
            product.setStatus(1);
        }
        productService.save(product);
        return Result.ok();
    }

    @PutMapping("/{id}")
    public Result<Void> update(@PathVariable Long id, @Valid @RequestBody Product product) {
        product.setId(id);
        productService.updateById(product);
        return Result.ok();
    }

    @DeleteMapping("/{id}")
    public Result<Void> delete(@PathVariable Long id) {
        productService.removeById(id);
        return Result.ok();
    }
}
