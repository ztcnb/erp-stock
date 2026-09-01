package com.demo.erp.service;

import com.baomidou.mybatisplus.core.metadata.IPage;
import com.demo.erp.dto.SettleDTO;
import com.demo.erp.entity.Payable;
import com.demo.erp.entity.PayableRecord;
import com.demo.erp.entity.Receivable;
import com.demo.erp.entity.ReceivableRecord;

import java.util.List;

/**
 * 财务服务(应付付款 / 应收收款,支持部分核销)
 */
public interface FinanceService {

    IPage<Payable> payablePage(long page, long size, String status, String keyword);

    List<PayableRecord> payableRecords(Long payableId);

    /** 付款登记:金额不得超过未付余额,自动维护 UNPAID/PARTIAL/PAID 状态 */
    void pay(Long payableId, SettleDTO dto);

    IPage<Receivable> receivablePage(long page, long size, String status, String keyword);

    List<ReceivableRecord> receivableRecords(Long receivableId);

    /** 收款登记:金额不得超过未收余额,自动维护 UNRECEIVED/PARTIAL/RECEIVED 状态 */
    void receive(Long receivableId, SettleDTO dto);
}
