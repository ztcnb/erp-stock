import { createRouter, createWebHistory, type RouteRecordRaw } from 'vue-router'

/**
 * 路由定义:meta.title 用于面包屑与标签,meta.roles 控制可访问角色(缺省为全部角色)
 */
const routes: RouteRecordRaw[] = [
  {
    path: '/login',
    name: 'Login',
    component: () => import('@/views/Login.vue'),
    meta: { title: '登录' },
  },
  {
    path: '/',
    component: () => import('@/layout/Layout.vue'),
    redirect: '/dashboard',
    children: [
      { path: 'dashboard', component: () => import('@/views/Dashboard.vue'), meta: { title: '报表看板' } },
      { path: 'product/list', component: () => import('@/views/product/ProductList.vue'), meta: { title: '商品管理' } },
      { path: 'product/category', component: () => import('@/views/product/CategoryList.vue'), meta: { title: '商品分类' } },
      { path: 'base/supplier', component: () => import('@/views/base/SupplierList.vue'), meta: { title: '供应商管理', roles: ['ADMIN', 'BUYER'] } },
      { path: 'base/customer', component: () => import('@/views/base/CustomerList.vue'), meta: { title: '客户管理', roles: ['ADMIN', 'SELLER'] } },
      { path: 'base/warehouse', component: () => import('@/views/base/WarehouseList.vue'), meta: { title: '仓库管理', roles: ['ADMIN', 'STOCKER'] } },
      { path: 'purchase/list', component: () => import('@/views/purchase/PurchaseList.vue'), meta: { title: '采购订单', roles: ['ADMIN', 'BUYER', 'STOCKER'] } },
      { path: 'purchase/edit/:id?', component: () => import('@/views/purchase/PurchaseEdit.vue'), meta: { title: '采购单编辑', roles: ['ADMIN', 'BUYER', 'STOCKER'] } },
      { path: 'sale/list', component: () => import('@/views/sale/SaleList.vue'), meta: { title: '销售订单', roles: ['ADMIN', 'SELLER', 'STOCKER'] } },
      { path: 'sale/edit/:id?', component: () => import('@/views/sale/SaleEdit.vue'), meta: { title: '销售单编辑', roles: ['ADMIN', 'SELLER', 'STOCKER'] } },
      { path: 'stock/list', component: () => import('@/views/stock/StockList.vue'), meta: { title: '实时库存' } },
      { path: 'stock/flow', component: () => import('@/views/stock/StockFlow.vue'), meta: { title: '库存流水' } },
      { path: 'stock/taking', component: () => import('@/views/stock/TakingList.vue'), meta: { title: '库存盘点', roles: ['ADMIN', 'STOCKER'] } },
      { path: 'stock/taking/:id', component: () => import('@/views/stock/TakingDetail.vue'), meta: { title: '盘点明细', roles: ['ADMIN', 'STOCKER'] } },
      { path: 'stock/warning', component: () => import('@/views/stock/StockWarning.vue'), meta: { title: '库存预警' } },
      { path: 'finance/payable', component: () => import('@/views/finance/PayableList.vue'), meta: { title: '应付账款', roles: ['ADMIN', 'BUYER'] } },
      { path: 'finance/receivable', component: () => import('@/views/finance/ReceivableList.vue'), meta: { title: '应收账款', roles: ['ADMIN', 'SELLER'] } },
      { path: 'system/user', component: () => import('@/views/system/UserList.vue'), meta: { title: '用户管理', roles: ['ADMIN'] } },
    ],
  },
  { path: '/:pathMatch(.*)*', redirect: '/dashboard' },
]

const router = createRouter({
  history: createWebHistory(),
  routes,
})

// 全局前置守卫:未登录跳转登录页,无权限跳转看板
router.beforeEach((to) => {
  const token = localStorage.getItem('erp_token')
  if (to.path !== '/login' && !token) {
    return '/login'
  }
  if (to.path === '/login' && token) {
    return '/dashboard'
  }
  const roles = to.meta.roles as string[] | undefined
  if (roles && roles.length > 0) {
    const user = JSON.parse(localStorage.getItem('erp_user') || 'null')
    if (!user || !roles.includes(user.role)) {
      return '/dashboard'
    }
  }
  return true
})

router.afterEach((to) => {
  document.title = to.meta.title ? `${to.meta.title} - 云仓进销存` : '云仓进销存'
})

export default router
