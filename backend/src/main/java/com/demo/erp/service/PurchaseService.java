package com.demo.erp.service;

import com.baomidou.mybatisplus.core.metadata.IPage;
import com.demo.erp.dto.PurchaseOrderDTO;
import com.demo.erp.entity.PurchaseOrder;

/**
 * 采购管理服务
 * 状态机: DRAFT -> APPROVED -> STOCKED;DRAFT 可作废为 CANCELED
 */
public interface PurchaseService {

    IPage<PurchaseOrder> pageQuery(long page, long size, String keyword, String status,
                                   String startDate, String endDate);

    /** 单据详情(含明细行) */
    PurchaseOrder detail(Long id);

    /** 创建草稿单,返回单号 */
    String create(PurchaseOrderDTO dto);

    /** 编辑草稿单(整单覆盖明细) */
    void update(Long id, PurchaseOrderDTO dto);

    /** 审核: DRAFT -> APPROVED */
    void approve(Long id);

    /** 作废: DRAFT -> CANCELED */
    void cancel(Long id);

    /** 删除草稿/已作废单据 */
    void delete(Long id);

    /** 入库: APPROVED -> STOCKED,按加权平均法更新库存成本,生成流水与应付账款 */
    void inbound(Long id);
}
