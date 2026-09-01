package com.demo.erp.service.impl;

import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.core.toolkit.StringUtils;
import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.demo.erp.common.BizException;
import com.demo.erp.common.UserContext;
import com.demo.erp.dto.SettleDTO;
import com.demo.erp.entity.Payable;
import com.demo.erp.entity.PayableRecord;
import com.demo.erp.entity.Receivable;
import com.demo.erp.entity.ReceivableRecord;
import com.demo.erp.mapper.PayableMapper;
import com.demo.erp.mapper.PayableRecordMapper;
import com.demo.erp.mapper.ReceivableMapper;
import com.demo.erp.mapper.ReceivableRecordMapper;
import com.demo.erp.service.FinanceService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;

/**
 * 财务服务实现
 */
@Service
@RequiredArgsConstructor
public class FinanceServiceImpl implements FinanceService {

    private static final String DEFAULT_METHOD = "银行转账";

    private final PayableMapper payableMapper;
    private final PayableRecordMapper payableRecordMapper;
    private final ReceivableMapper receivableMapper;
    private final ReceivableRecordMapper receivableRecordMapper;

    @Override
    public IPage<Payable> payablePage(long page, long size, String status, String keyword) {
        return payableMapper.selectPageJoin(new Page<>(page, size), status, keyword);
    }

    @Override
    public List<PayableRecord> payableRecords(Long payableId) {
        return payableRecordMapper.selectList(Wrappers.<PayableRecord>lambdaQuery()
                .eq(PayableRecord::getPayableId, payableId)
                .orderByDesc(PayableRecord::getCreatedAt));
    }

    @Override
    @Transactional
    public void pay(Long payableId, SettleDTO dto) {
        Payable payable = payableMapper.selectById(payableId);
        if (payable == null) {
            throw new BizException("应付账款不存在");
        }
        BigDecimal balance = payable.getTotalAmount().subtract(payable.getPaidAmount());
        if (dto.getAmount().compareTo(balance) > 0) {
            throw new BizException("付款金额超过未付余额 " + balance.toPlainString());
        }
        BigDecimal newPaid = payable.getPaidAmount().add(dto.getAmount());
        payable.setPaidAmount(newPaid);
        payable.setStatus(newPaid.compareTo(payable.getTotalAmount()) >= 0
                ? Payable.STATUS_PAID : Payable.STATUS_PARTIAL);
        payableMapper.updateById(payable);

        PayableRecord record = new PayableRecord();
        record.setPayableId(payableId);
        record.setAmount(dto.getAmount());
        record.setPayMethod(StringUtils.isBlank(dto.getMethod()) ? DEFAULT_METHOD : dto.getMethod());
        record.setRemark(dto.getRemark());
        record.setCreatedBy(UserContext.get().id());
        payableRecordMapper.insert(record);
    }

    @Override
    public IPage<Receivable> receivablePage(long page, long size, String status, String keyword) {
        return receivableMapper.selectPageJoin(new Page<>(page, size), status, keyword);
    }

    @Override
    public List<ReceivableRecord> receivableRecords(Long receivableId) {
        return receivableRecordMapper.selectList(Wrappers.<ReceivableRecord>lambdaQuery()
                .eq(ReceivableRecord::getReceivableId, receivableId)
                .orderByDesc(ReceivableRecord::getCreatedAt));
    }

    @Override
    @Transactional
    public void receive(Long receivableId, SettleDTO dto) {
        Receivable receivable = receivableMapper.selectById(receivableId);
        if (receivable == null) {
            throw new BizException("应收账款不存在");
        }
        BigDecimal balance = receivable.getTotalAmount().subtract(receivable.getReceivedAmount());
        if (dto.getAmount().compareTo(balance) > 0) {
            throw new BizException("收款金额超过未收余额 " + balance.toPlainString());
        }
        BigDecimal newReceived = receivable.getReceivedAmount().add(dto.getAmount());
        receivable.setReceivedAmount(newReceived);
        receivable.setStatus(newReceived.compareTo(receivable.getTotalAmount()) >= 0
                ? Receivable.STATUS_RECEIVED : Receivable.STATUS_PARTIAL);
        receivableMapper.updateById(receivable);

        ReceivableRecord record = new ReceivableRecord();
        record.setReceivableId(receivableId);
        record.setAmount(dto.getAmount());
        record.setReceiveMethod(StringUtils.isBlank(dto.getMethod()) ? DEFAULT_METHOD : dto.getMethod());
        record.setRemark(dto.getRemark());
        record.setCreatedBy(UserContext.get().id());
        receivableRecordMapper.insert(record);
    }
}
