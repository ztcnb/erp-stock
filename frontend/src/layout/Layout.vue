<template>
  <el-container class="layout">
    <!-- 侧边菜单 -->
    <el-aside width="210px" class="aside">
      <div class="logo">
        <el-icon :size="22"><Box /></el-icon>
        <span>云仓进销存</span>
      </div>
      <el-menu
        :default-active="activePath"
        router
        background-color="#001529"
        text-color="rgba(255,255,255,0.68)"
        active-text-color="#ffffff"
      >
        <template v-for="menu in visibleMenus" :key="menu.title">
          <el-menu-item v-if="!menu.children" :index="menu.path">
            <el-icon><component :is="menu.icon" /></el-icon>
            <span>{{ menu.title }}</span>
          </el-menu-item>
          <el-sub-menu v-else :index="menu.title">
            <template #title>
              <el-icon><component :is="menu.icon" /></el-icon>
              <span>{{ menu.title }}</span>
            </template>
            <el-menu-item v-for="child in menu.children" :key="child.path" :index="child.path">
              {{ child.title }}
            </el-menu-item>
          </el-sub-menu>
        </template>
      </el-menu>
    </el-aside>

    <el-container>
      <!-- 顶栏 -->
      <el-header class="header">
        <div class="header-title">{{ currentTitle }}</div>
        <el-dropdown @command="onCommand">
          <span class="user-info">
            <el-icon><UserFilled /></el-icon>
            {{ auth.user?.realName }}
            <el-tag size="small" type="primary" effect="plain">{{ roleMap[auth.role] || auth.role }}</el-tag>
            <el-icon><ArrowDown /></el-icon>
          </span>
          <template #dropdown>
            <el-dropdown-menu>
              <el-dropdown-item command="logout">退出登录</el-dropdown-item>
            </el-dropdown-menu>
          </template>
        </el-dropdown>
      </el-header>

      <!-- 内容区 -->
      <el-main class="main">
        <router-view />
      </el-main>
    </el-container>
  </el-container>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessageBox } from 'element-plus'
import { useAuthStore } from '@/stores/auth'
import { roleMap } from '@/utils/format'

interface MenuItem {
  title: string
  path?: string
  icon?: string
  roles?: string[]
  children?: MenuItem[]
}

/** 菜单配置:roles 缺省表示所有角色可见 */
const menus: MenuItem[] = [
  { title: '报表看板', path: '/dashboard', icon: 'DataBoard' },
  {
    title: '基础资料',
    icon: 'Files',
    children: [
      { title: '商品管理', path: '/product/list' },
      { title: '商品分类', path: '/product/category' },
      { title: '供应商管理', path: '/base/supplier', roles: ['ADMIN', 'BUYER'] },
      { title: '客户管理', path: '/base/customer', roles: ['ADMIN', 'SELLER'] },
      { title: '仓库管理', path: '/base/warehouse', roles: ['ADMIN', 'STOCKER'] },
    ],
  },
  {
    title: '采购管理',
    icon: 'ShoppingCart',
    roles: ['ADMIN', 'BUYER', 'STOCKER'],
    children: [{ title: '采购订单', path: '/purchase/list' }],
  },
  {
    title: '销售管理',
    icon: 'Sell',
    roles: ['ADMIN', 'SELLER', 'STOCKER'],
    children: [{ title: '销售订单', path: '/sale/list' }],
  },
  {
    title: '库存管理',
    icon: 'Box',
    children: [
      { title: '实时库存', path: '/stock/list' },
      { title: '库存流水', path: '/stock/flow' },
      { title: '库存盘点', path: '/stock/taking', roles: ['ADMIN', 'STOCKER'] },
      { title: '库存预警', path: '/stock/warning' },
    ],
  },
  {
    title: '财务管理',
    icon: 'Money',
    roles: ['ADMIN', 'BUYER', 'SELLER'],
    children: [
      { title: '应付账款', path: '/finance/payable', roles: ['ADMIN', 'BUYER'] },
      { title: '应收账款', path: '/finance/receivable', roles: ['ADMIN', 'SELLER'] },
    ],
  },
  {
    title: '系统管理',
    icon: 'Setting',
    roles: ['ADMIN'],
    children: [{ title: '用户管理', path: '/system/user' }],
  },
]

const route = useRoute()
const router = useRouter()
const auth = useAuthStore()

/** 按当前角色过滤菜单 */
const visibleMenus = computed(() =>
  menus
    .filter((m) => auth.hasRole(m.roles))
    .map((m) => ({
      ...m,
      children: m.children?.filter((c) => auth.hasRole(c.roles)),
    }))
    .filter((m) => !m.children || m.children.length > 0),
)

const activePath = computed(() => route.path)
const currentTitle = computed(() => (route.meta.title as string) || '')

function onCommand(command: string) {
  if (command === 'logout') {
    ElMessageBox.confirm('确定退出登录吗?', '提示', { type: 'warning' }).then(() => {
      auth.logout()
      router.push('/login')
    })
  }
}
</script>

<style scoped>
.layout {
  height: 100%;
}
.aside {
  background-color: #001529;
  overflow-x: hidden;
}
.logo {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  height: 56px;
  color: #fff;
  font-size: 17px;
  font-weight: 600;
  letter-spacing: 1px;
}
.aside :deep(.el-menu) {
  border-right: none;
}
.header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  background: #fff;
  border-bottom: 1px solid #e8e8e8;
  height: 56px;
}
.header-title {
  font-size: 16px;
  font-weight: 600;
  color: #303133;
}
.user-info {
  display: flex;
  align-items: center;
  gap: 6px;
  cursor: pointer;
  color: #303133;
  outline: none;
}
.main {
  overflow-y: auto;
  padding: 16px;
}
</style>
