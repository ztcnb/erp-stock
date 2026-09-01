import { get } from '@/utils/request'
import type { Row } from '@/api/base'

/** 报表看板 */
export const dashboardApi = {
  summary: () => get<Row>('/dashboard/summary'),
  trend: () => get<Row[]>('/dashboard/trend'),
  topProducts: () => get<Row[]>('/dashboard/top-products'),
  categoryShare: () => get<Row[]>('/dashboard/category-share'),
  warnings: () => get<Row[]>('/dashboard/warnings'),
}
