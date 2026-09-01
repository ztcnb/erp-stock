import { del, get, post, put } from '@/utils/request'
import type { PageData } from '@/types'
import type { Row } from '@/api/base'

/** 用户管理(仅管理员) */
export const userApi = {
  page: (params: Row) => get<PageData<Row>>('/users', params),
  create: (data: Row) => post<void>('/users', data),
  update: (id: number, data: Row) => put<void>(`/users/${id}`, data),
  remove: (id: number) => del<void>(`/users/${id}`),
}
