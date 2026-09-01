package com.demo.erp.service.impl;

import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.demo.erp.entity.Product;
import com.demo.erp.mapper.ProductMapper;
import com.demo.erp.service.CategoryService;
import com.demo.erp.service.ProductService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

/**
 * 商品服务实现
 */
@Service
@RequiredArgsConstructor
public class ProductServiceImpl extends ServiceImpl<ProductMapper, Product> implements ProductService {

    private final CategoryService categoryService;

    @Override
    public IPage<Product> pageQuery(long page, long size, String keyword, Long categoryId) {
        List<Long> categoryIds = categoryId == null ? null : categoryService.selfAndDescendantIds(categoryId);
        return baseMapper.selectPageJoin(new Page<>(page, size), keyword, categoryIds);
    }
}
