import { get, post } from '@/utils/request'
import type { PageData } from '@/types'
import type { Row } from '@/api/base'

/** 付款/收款登记载荷 */
export interface SettlePayload {
  amount: number
  method?: string
  remark?: string
}

// ---------- 应付账款 ----------
export const payableApi = {
  page: (params: Row) => get<PageData<Row>>('/payables', params),
  records: (id: number) => get<Row[]>(`/payables/${id}/records`),
  pay: (id: number, data: SettlePayload) => post<void>(`/payables/${id}/pay`, data),
}

// ---------- 应收账款 ----------
export const receivableApi = {
  page: (params: Row) => get<PageData<Row>>('/receivables', params),
  records: (id: number) => get<Row[]>(`/receivables/${id}/records`),
  receive: (id: number, data: SettlePayload) => post<void>(`/receivables/${id}/receive`, data),
}
