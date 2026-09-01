package com.demo.erp.service.impl;

import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.demo.erp.entity.Supplier;
import com.demo.erp.mapper.SupplierMapper;
import com.demo.erp.service.SupplierService;
import org.springframework.stereotype.Service;

/**
 * 供应商服务实现
 */
@Service
public class SupplierServiceImpl extends ServiceImpl<SupplierMapper, Supplier> implements SupplierService {
}
