package com.demo.erp.service.impl;

import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.demo.erp.common.BizException;
import com.demo.erp.entity.Product;
import com.demo.erp.entity.ProductCategory;
import com.demo.erp.mapper.ProductCategoryMapper;
import com.demo.erp.mapper.ProductMapper;
import com.demo.erp.service.CategoryService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * 商品分类服务实现
 */
@Service
@RequiredArgsConstructor
public class CategoryServiceImpl extends ServiceImpl<ProductCategoryMapper, ProductCategory> implements CategoryService {

    private final ProductMapper productMapper;

    @Override
    public List<ProductCategory> tree() {
        List<ProductCategory> all = this.list(Wrappers.<ProductCategory>lambdaQuery()
                .orderByAsc(ProductCategory::getSort).orderByAsc(ProductCategory::getId));
        Map<Long, List<ProductCategory>> byParent = all.stream()
                .collect(Collectors.groupingBy(ProductCategory::getParentId));
        for (ProductCategory c : all) {
            List<ProductCategory> children = byParent.get(c.getId());
            if (children != null) {
                children.sort(Comparator.comparing(ProductCategory::getSort));
                c.setChildren(children);
            }
        }
        return byParent.getOrDefault(0L, new ArrayList<>());
    }

    @Override
    public List<Long> selfAndDescendantIds(Long categoryId) {
        List<ProductCategory> all = this.list();
        Map<Long, List<Long>> childMap = all.stream().collect(Collectors.groupingBy(
                ProductCategory::getParentId,
                Collectors.mapping(ProductCategory::getId, Collectors.toList())));
        List<Long> result = new ArrayList<>();
        // 广度优先收集子孙分类
        List<Long> queue = new ArrayList<>(List.of(categoryId));
        while (!queue.isEmpty()) {
            Long cur = queue.remove(0);
            result.add(cur);
            queue.addAll(childMap.getOrDefault(cur, List.of()));
        }
        return result;
    }

    @Override
    public void delete(Long id) {
        long childCount = this.count(Wrappers.<ProductCategory>lambdaQuery()
                .eq(ProductCategory::getParentId, id));
        if (childCount > 0) {
            throw new BizException("存在子分类,不能删除");
        }
        Long productCount = productMapper.selectCount(Wrappers.<Product>lambdaQuery()
                .eq(Product::getCategoryId, id));
        if (productCount != null && productCount > 0) {
            throw new BizException("该分类下存在商品,不能删除");
        }
        this.removeById(id);
    }
}
