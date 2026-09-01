package com.demo.erp.service.impl;

import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.demo.erp.entity.Warehouse;
import com.demo.erp.mapper.WarehouseMapper;
import com.demo.erp.service.WarehouseService;
import org.springframework.stereotype.Service;

/**
 * 仓库服务实现
 */
@Service
public class WarehouseServiceImpl extends ServiceImpl<WarehouseMapper, Warehouse> implements WarehouseService {
}
