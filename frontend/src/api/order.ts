import { del, get, post, put } from '@/utils/request'
import type { PageData } from '@/types'
import type { Row } from '@/api/base'

/** 单据保存载荷 */
export interface OrderPayload {
  supplierId?: number
  customerId?: number
  warehouseId: number
  remark?: string
  items: { productId: number; qty: number; price: number }[]
}

// ---------- 采购订单 ----------
export const purchaseApi = {
  page: (params: Row) => get<PageData<Row>>('/purchase-orders', params),
  detail: (id: number) => get<Row>(`/purchase-orders/${id}`),
  create: (data: OrderPayload) => post<string>('/purchase-orders', data),
  update: (id: number, data: OrderPayload) => put<void>(`/purchase-orders/${id}`, data),
  approve: (id: number) => post<void>(`/purchase-orders/${id}/approve`),
  cancel: (id: number) => post<void>(`/purchase-orders/${id}/cancel`),
  inbound: (id: number) => post<void>(`/purchase-orders/${id}/inbound`),
  remove: (id: number) => del<void>(`/purchase-orders/${id}`),
}

// ---------- 销售订单 ----------
export const saleApi = {
  page: (params: Row) => get<PageData<Row>>('/sale-orders', params),
  detail: (id: number) => get<Row>(`/sale-orders/${id}`),
  create: (data: OrderPayload) => post<string>('/sale-orders', data),
  update: (id: number, data: OrderPayload) => put<void>(`/sale-orders/${id}`, data),
  approve: (id: number) => post<void>(`/sale-orders/${id}/approve`),
  cancel: (id: number) => post<void>(`/sale-orders/${id}/cancel`),
  outbound: (id: number) => post<void>(`/sale-orders/${id}/outbound`),
  remove: (id: number) => del<void>(`/sale-orders/${id}`),
}
