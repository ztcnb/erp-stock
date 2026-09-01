/**
 * 全局类型定义
 */

/** 统一响应体 */
export interface R<T = unknown> {
  code: number
  msg: string
  data: T
}

/** MyBatis-Plus 分页结构 */
export interface PageData<T = Record<string, unknown>> {
  records: T[]
  total: number
  size: number
  current: number
}

/** 登录用户 */
export interface LoginUser {
  id: number
  username: string
  realName: string
  role: 'ADMIN' | 'BUYER' | 'SELLER' | 'STOCKER'
}

/** 单据明细行(采购/销售编辑页用) */
export interface OrderItemRow {
  productId: number | null
  productCode?: string
  productName?: string
  unit?: string
  qty: number
  price: number
}
