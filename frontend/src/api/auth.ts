import { get, post } from '@/utils/request'
import type { LoginUser } from '@/types'

/** 登录 */
export function login(data: { username: string; password: string }) {
  return post<{ token: string; user: LoginUser }>('/auth/login', data)
}

/** 当前登录用户信息 */
export function getInfo() {
  return get<{ user: LoginUser }>('/auth/info')
}
