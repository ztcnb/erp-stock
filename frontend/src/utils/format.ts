/**
 * 格式化与字典工具
 */

/** 金额格式化:千分位 + 两位小数 */
export function fmtMoney(v: unknown): string {
  const n = Number(v)
  if (Number.isNaN(n)) return '0.00'
  return n.toLocaleString('zh-CN', { minimumFractionDigits: 2, maximumFractionDigits: 2 })
}

/** 数量格式化:去掉多余的小数零 */
export function fmtQty(v: unknown): string {
  const n = Number(v)
  if (Number.isNaN(n)) return '0'
  return String(parseFloat(n.toFixed(2)))
}

/** 单据状态字典 */
export const orderStatusMap: Record<string, { text: string; type: 'info' | 'warning' | 'success' | 'danger' | 'primary' }> = {
  DRAFT: { text: '草稿', type: 'info' },
  APPROVED: { text: '已审核', type: 'warning' },
  STOCKED: { text: '已入库', type: 'success' },
  SHIPPED: { text: '已出库', type: 'success' },
  CANCELED: { text: '已作废', type: 'danger' },
  FINISHED: { text: '已完成', type: 'success' },
}

/** 库存流水类型字典 */
export const flowTypeMap: Record<string, { text: string; type: 'success' | 'danger' | 'warning' | 'primary' }> = {
  PURCHASE_IN: { text: '采购入库', type: 'success' },
  SALE_OUT: { text: '销售出库', type: 'danger' },
  TAKING_GAIN: { text: '盘盈', type: 'primary' },
  TAKING_LOSS: { text: '盘亏', type: 'warning' },
}

/** 应付/应收状态字典 */
export const settleStatusMap: Record<string, { text: string; type: 'info' | 'warning' | 'success' | 'danger' }> = {
  UNPAID: { text: '未付款', type: 'danger' },
  UNRECEIVED: { text: '未收款', type: 'danger' },
  PARTIAL: { text: '部分核销', type: 'warning' },
  PAID: { text: '已结清', type: 'success' },
  RECEIVED: { text: '已结清', type: 'success' },
}

/** 角色字典 */
export const roleMap: Record<string, string> = {
  ADMIN: '管理员',
  BUYER: '采购员',
  SELLER: '销售员',
  STOCKER: '仓管员',
}
