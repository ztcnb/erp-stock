package com.demo.erp.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.demo.erp.entity.ProductCategory;

import java.util.List;

/**
 * 商品分类服务
 */
public interface CategoryService extends IService<ProductCategory> {

    /** 查询完整分类树 */
    List<ProductCategory> tree();

    /** 查询某分类及其所有子孙分类的 id 集合 */
    List<Long> selfAndDescendantIds(Long categoryId);

    /** 删除分类(存在子分类或商品引用时拒绝) */
    void delete(Long id);
}
