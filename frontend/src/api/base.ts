import { del, get, post, put } from '@/utils/request'
import type { PageData } from '@/types'

/** 基础资料通用行类型(字段宽松,便于表格直接渲染) */
export type Row = Record<string, any>

// ---------- 商品分类 ----------
export const categoryApi = {
  tree: () => get<Row[]>('/categories/tree'),
  create: (data: Row) => post<void>('/categories', data),
  update: (id: number, data: Row) => put<void>(`/categories/${id}`, data),
  remove: (id: number) => del<void>(`/categories/${id}`),
}

// ---------- 商品 ----------
export const productApi = {
  page: (params: Row) => get<PageData<Row>>('/products', params),
  all: () => get<Row[]>('/products/all'),
  create: (data: Row) => post<void>('/products', data),
  update: (id: number, data: Row) => put<void>(`/products/${id}`, data),
  remove: (id: number) => del<void>(`/products/${id}`),
}

// ---------- 供应商 ----------
export const supplierApi = {
  page: (params: Row) => get<PageData<Row>>('/suppliers', params),
  all: () => get<Row[]>('/suppliers/all'),
  create: (data: Row) => post<void>('/suppliers', data),
  update: (id: number, data: Row) => put<void>(`/suppliers/${id}`, data),
  remove: (id: number) => del<void>(`/suppliers/${id}`),
}

// ---------- 客户 ----------
export const customerApi = {
  page: (params: Row) => get<PageData<Row>>('/customers', params),
  all: () => get<Row[]>('/customers/all'),
  create: (data: Row) => post<void>('/customers', data),
  update: (id: number, data: Row) => put<void>(`/customers/${id}`, data),
  remove: (id: number) => del<void>(`/customers/${id}`),
}

// ---------- 仓库 ----------
export const warehouseApi = {
  page: (params: Row) => get<PageData<Row>>('/warehouses', params),
  all: () => get<Row[]>('/warehouses/all'),
  create: (data: Row) => post<void>('/warehouses', data),
  update: (id: number, data: Row) => put<void>(`/warehouses/${id}`, data),
  remove: (id: number) => del<void>(`/warehouses/${id}`),
}
