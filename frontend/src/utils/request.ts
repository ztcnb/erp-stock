import axios, { type AxiosRequestConfig } from 'axios'
import { ElMessage } from 'element-plus'
import router from '@/router'
import type { R } from '@/types'

/**
 * Axios 实例:统一携带 token,统一处理响应码
 */
const instance = axios.create({
  baseURL: '/api',
  timeout: 30000,
})

instance.interceptors.request.use((config) => {
  const token = localStorage.getItem('erp_token')
  if (token) {
    config.headers.Authorization = `Bearer ${token}`
  }
  return config
})

instance.interceptors.response.use(
  (response) => {
    const res = response.data as R
    if (res.code === 200) {
      return res.data as never
    }
    if (res.code === 401) {
      // 登录失效:清理本地状态并跳转登录页
      localStorage.removeItem('erp_token')
      localStorage.removeItem('erp_user')
      router.push('/login')
    }
    ElMessage.error(res.msg || '请求失败')
    return Promise.reject(new Error(res.msg))
  },
  (error) => {
    ElMessage.error(error.message || '网络异常')
    return Promise.reject(error)
  },
)

/** 泛型请求封装:直接返回业务数据 data(响应拦截器已拆包) */
export function request<T>(config: AxiosRequestConfig): Promise<T> {
  return instance.request(config) as Promise<T>
}

export function get<T>(url: string, params?: Record<string, unknown>): Promise<T> {
  return request<T>({ method: 'get', url, params })
}

export function post<T>(url: string, data?: unknown): Promise<T> {
  return request<T>({ method: 'post', url, data })
}

export function put<T>(url: string, data?: unknown): Promise<T> {
  return request<T>({ method: 'put', url, data })
}

export function del<T>(url: string): Promise<T> {
  return request<T>({ method: 'delete', url })
}
