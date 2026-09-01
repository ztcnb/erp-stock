package com.demo.erp.service;

import com.baomidou.mybatisplus.core.metadata.IPage;
import com.demo.erp.dto.TakingCreateDTO;
import com.demo.erp.dto.TakingSaveDTO;
import com.demo.erp.entity.StockTaking;

/**
 * 库存盘点服务
 * 状态: DRAFT 盘点中 -> FINISHED 已完成
 */
public interface TakingService {

    IPage<StockTaking> pageQuery(long page, long size, String status);

    /** 盘点单详情(含明细) */
    StockTaking detail(Long id);

    /** 创建盘点单:对指定仓库当前有库存记录的商品生成账面快照,返回盘点单号 */
    String create(TakingCreateDTO dto);

    /** 保存实盘数量(盘点中可反复保存) */
    void saveItems(Long id, TakingSaveDTO dto);

    /** 完成盘点:按 实盘 - 账面 生成盘盈/盘亏调整流水并更新库存 */
    void finish(Long id);

    /** 删除盘点中的单据 */
    void delete(Long id);
}
