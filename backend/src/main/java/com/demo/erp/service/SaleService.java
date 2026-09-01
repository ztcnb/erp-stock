package com.demo.erp.service;

import com.baomidou.mybatisplus.core.metadata.IPage;
import com.demo.erp.dto.SaleOrderDTO;
import com.demo.erp.entity.SaleOrder;

/**
 * 销售管理服务
 * 状态机: DRAFT -> APPROVED -> SHIPPED;DRAFT 可作废为 CANCELED
 */
public interface SaleService {

    IPage<SaleOrder> pageQuery(long page, long size, String keyword, String status,
                               String startDate, String endDate);

    /** 单据详情(含明细行) */
    SaleOrder detail(Long id);

    /** 创建草稿单,返回单号 */
    String create(SaleOrderDTO dto);

    /** 编辑草稿单(整单覆盖明细) */
    void update(Long id, SaleOrderDTO dto);

    /** 审核: DRAFT -> APPROVED,校验库存充足 */
    void approve(Long id);

    /** 作废: DRAFT -> CANCELED */
    void cancel(Long id);

    /** 删除草稿/已作废单据 */
    void delete(Long id);

    /** 出库: APPROVED -> SHIPPED,行级条件扣减防止超卖,按加权平均成本记录毛利,生成流水与应收账款 */
    void outbound(Long id);
}
