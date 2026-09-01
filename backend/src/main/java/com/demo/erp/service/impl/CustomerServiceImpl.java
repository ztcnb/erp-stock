package com.demo.erp.service.impl;

import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.demo.erp.entity.Customer;
import com.demo.erp.mapper.CustomerMapper;
import com.demo.erp.service.CustomerService;
import org.springframework.stereotype.Service;

/**
 * 客户服务实现
 */
@Service
public class CustomerServiceImpl extends ServiceImpl<CustomerMapper, Customer> implements CustomerService {
}
