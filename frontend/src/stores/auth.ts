import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { login as loginApi } from '@/api/auth'
import type { LoginUser } from '@/types'

/**
 * 认证状态:token 与用户信息持久化到 localStorage
 */
export const useAuthStore = defineStore('auth', () => {
  const token = ref<string>(localStorage.getItem('erp_token') || '')
  const user = ref<LoginUser | null>(JSON.parse(localStorage.getItem('erp_user') || 'null'))

  const role = computed(() => user.value?.role || '')

  async function login(username: string, password: string) {
    const data = await loginApi({ username, password })
    token.value = data.token
    user.value = data.user
    localStorage.setItem('erp_token', data.token)
    localStorage.setItem('erp_user', JSON.stringify(data.user))
  }

  function logout() {
    token.value = ''
    user.value = null
    localStorage.removeItem('erp_token')
    localStorage.removeItem('erp_user')
  }

  /** 是否拥有任一角色(空数组表示所有角色可见) */
  function hasRole(roles?: string[]) {
    if (!roles || roles.length === 0) return true
    return roles.includes(role.value)
  }

  return { token, user, role, login, logout, hasRole }
})
