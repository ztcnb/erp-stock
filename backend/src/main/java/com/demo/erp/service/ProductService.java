package com.demo.erp.service;

import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.service.IService;
import com.demo.erp.entity.Product;

/**
 * 商品服务
 */
public interface ProductService extends IService<Product> {

    /** 分页查询(带分类名称,支持关键字与分类过滤,分类过滤含子孙分类) */
    IPage<Product> pageQuery(long page, long size, String keyword, Long categoryId);
}
