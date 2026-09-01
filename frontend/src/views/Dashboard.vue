<template>
  <div>
    <!-- 核心指标卡 -->
    <el-row :gutter="16">
      <el-col v-for="card in cards" :key="card.label" :span="4">
        <el-card shadow="hover" class="stat-card">
          <div class="stat-icon" :style="{ backgroundColor: card.color + '1a', color: card.color }">
            <el-icon :size="24"><component :is="card.icon" /></el-icon>
          </div>
          <div class="stat-body">
            <div class="stat-label">{{ card.label }}</div>
            <div class="stat-value money">¥ {{ fmtMoney(card.value) }}</div>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 趋势双折线 -->
    <el-card shadow="never" class="chart-card">
      <template #header>近 30 天销售与采购趋势</template>
      <div ref="trendRef" class="chart-lg"></div>
    </el-card>

    <el-row :gutter="16">
      <!-- 热销 TOP10 -->
      <el-col :span="14">
        <el-card shadow="never" class="chart-card">
          <template #header>热销商品 TOP10(近 30 天,按销售额)</template>
          <div ref="topRef" class="chart-md"></div>
        </el-card>
      </el-col>
      <!-- 分类占比 -->
      <el-col :span="10">
        <el-card shadow="never" class="chart-card">
          <template #header>分类销售占比(近 30 天)</template>
          <div ref="shareRef" class="chart-md"></div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 库存预警 -->
    <el-card shadow="never" class="chart-card">
      <template #header>
        <span>库存预警<el-tag v-if="warnings.length" type="danger" size="small" style="margin-left: 8px">{{ warnings.length }}</el-tag></span>
      </template>
      <el-table :data="warnings" size="small" stripe>
        <el-table-column prop="code" label="商品编码" width="110" />
        <el-table-column prop="name" label="商品名称" min-width="200" />
        <el-table-column prop="unit" label="单位" width="70" />
        <el-table-column label="当前总库存" width="120" align="right">
          <template #default="{ row }">{{ fmtQty(row.total_qty) }}</template>
        </el-table-column>
        <el-table-column label="预警线" width="100" align="right">
          <template #default="{ row }">{{ fmtQty(row.warn_qty) }}</template>
        </el-table-column>
        <el-table-column label="缺口" width="100" align="right">
          <template #default="{ row }">
            <span style="color: #f56c6c">{{ fmtQty(Number(row.warn_qty) - Number(row.total_qty)) }}</span>
          </template>
        </el-table-column>
        <el-table-column label="库存金额" width="120" align="right">
          <template #default="{ row }">{{ fmtMoney(row.total_amount) }}</template>
        </el-table-column>
      </el-table>
    </el-card>
  </div>
</template>

<script setup lang="ts">
import { computed, onBeforeUnmount, onMounted, ref } from 'vue'
import * as echarts from 'echarts'
import { dashboardApi } from '@/api/dashboard'
import type { Row } from '@/api/base'
import { fmtMoney, fmtQty } from '@/utils/format'

const summary = ref<Row>({})
const warnings = ref<Row[]>([])
const trendRef = ref<HTMLDivElement>()
const topRef = ref<HTMLDivElement>()
const shareRef = ref<HTMLDivElement>()
const charts: echarts.ECharts[] = []

const cards = computed(() => [
  { label: '本月销售额', value: summary.value.monthSaleAmount, icon: 'Sell', color: '#409eff' },
  { label: '本月毛利', value: summary.value.monthProfit, icon: 'TrendCharts', color: '#67c23a' },
  { label: '本月采购额', value: summary.value.monthPurchaseAmount, icon: 'ShoppingCart', color: '#e6a23c' },
  { label: '库存总额', value: summary.value.stockAmount, icon: 'Box', color: '#909399' },
  { label: '应收余额', value: summary.value.receivableBalance, icon: 'Wallet', color: '#f56c6c' },
  { label: '应付余额', value: summary.value.payableBalance, icon: 'CreditCard', color: '#8e44ad' },
])

function initChart(el: HTMLDivElement | undefined, option: echarts.EChartsOption) {
  if (!el) return
  const chart = echarts.init(el)
  chart.setOption(option)
  charts.push(chart)
}

function onResize() {
  charts.forEach((c) => c.resize())
}

onMounted(async () => {
  window.addEventListener('resize', onResize)
  const [sum, trend, top, share, warns] = await Promise.all([
    dashboardApi.summary(),
    dashboardApi.trend(),
    dashboardApi.topProducts(),
    dashboardApi.categoryShare(),
    dashboardApi.warnings(),
  ])
  summary.value = sum
  warnings.value = warns

  // 趋势双折线
  initChart(trendRef.value, {
    tooltip: { trigger: 'axis' },
    legend: { data: ['销售额', '采购额'] },
    grid: { left: 60, right: 24, top: 40, bottom: 30 },
    xAxis: { type: 'category', data: trend.map((t) => String(t.day)) },
    yAxis: { type: 'value', name: '金额(元)' },
    series: [
      { name: '销售额', type: 'line', smooth: true, data: trend.map((t) => Number(t.sale_amount)), itemStyle: { color: '#409eff' }, areaStyle: { opacity: 0.08 } },
      { name: '采购额', type: 'line', smooth: true, data: trend.map((t) => Number(t.purchase_amount)), itemStyle: { color: '#e6a23c' }, areaStyle: { opacity: 0.08 } },
    ],
  })

  // 热销 TOP10 柱状图(倒序展示,第一名在最上)
  const topSorted = [...top].reverse()
  initChart(topRef.value, {
    tooltip: { trigger: 'axis', axisPointer: { type: 'shadow' } },
    grid: { left: 8, right: 60, top: 16, bottom: 30, containLabel: true },
    xAxis: { type: 'value', name: '销售额(元)' },
    yAxis: { type: 'category', data: topSorted.map((t) => String(t.name)), axisLabel: { width: 150, overflow: 'truncate' } },
    series: [
      {
        type: 'bar',
        data: topSorted.map((t) => Number(t.amount)),
        itemStyle: { color: '#409eff', borderRadius: [0, 4, 4, 0] },
        label: { show: true, position: 'right', formatter: (p) => fmtMoney(p.value) },
      },
    ],
  })

  // 分类占比饼图
  initChart(shareRef.value, {
    tooltip: { trigger: 'item', formatter: '{b}: ¥{c} ({d}%)' },
    legend: { bottom: 0 },
    series: [
      {
        type: 'pie',
        radius: ['42%', '68%'],
        center: ['50%', '44%'],
        itemStyle: { borderRadius: 6, borderColor: '#fff', borderWidth: 2 },
        label: { formatter: '{b}\n{d}%' },
        data: share.map((s) => ({ name: String(s.name), value: Number(s.value) })),
      },
    ],
  })
})

onBeforeUnmount(() => {
  window.removeEventListener('resize', onResize)
  charts.forEach((c) => c.dispose())
})
</script>

<style scoped>
.stat-card :deep(.el-card__body) {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 16px;
}
.stat-icon {
  width: 46px;
  height: 46px;
  border-radius: 10px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}
.stat-label {
  color: #909399;
  font-size: 13px;
}
.stat-value {
  font-size: 17px;
  font-weight: 600;
  color: #303133;
  margin-top: 4px;
  white-space: nowrap;
}
.chart-card {
  margin-top: 16px;
}
.chart-lg {
  height: 320px;
}
.chart-md {
  height: 360px;
}
</style>
