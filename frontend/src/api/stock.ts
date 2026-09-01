import { del, get, post, put } from '@/utils/request'
import type { PageData } from '@/types'
import type { Row } from '@/api/base'

// ---------- 库存 / 流水 / 预警 ----------
export const stockApi = {
  page: (params: Row) => get<PageData<Row>>('/stocks', params),
  flows: (params: Row) => get<PageData<Row>>('/stocks/flows', params),
  warnings: () => get<Row[]>('/stocks/warnings'),
}

// ---------- 库存盘点 ----------
export const takingApi = {
  page: (params: Row) => get<PageData<Row>>('/stock-takings', params),
  detail: (id: number) => get<Row>(`/stock-takings/${id}`),
  create: (data: { warehouseId: number; remark?: string }) => post<string>('/stock-takings', data),
  saveItems: (id: number, items: { id: number; actualQty: number }[]) =>
    put<void>(`/stock-takings/${id}/items`, { items }),
  finish: (id: number) => post<void>(`/stock-takings/${id}/finish`),
  remove: (id: number) => del<void>(`/stock-takings/${id}`),
}
