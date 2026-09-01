<template>
  <el-card shadow="never">
    <div class="query-bar">
      <el-alert
        type="warning"
        :closable="false"
        show-icon
        title="以下商品的总库存(各仓合计)已低于预警线,请及时补货"
        style="flex: 1"
      />
      <el-button :icon="Refresh" @click="load">刷新</el-button>
    </div>

    <el-table v-loading="loading" :data="rows" stripe>
      <el-table-column type="index" label="#" width="60" align="center" />
      <el-table-column prop="code" label="商品编码" width="120" />
      <el-table-column prop="name" label="商品名称" min-width="240" show-overflow-tooltip />
      <el-table-column prop="unit" label="单位" width="80" align="center" />
      <el-table-column label="当前总库存" width="130" align="right">
        <template #default="{ row }">
          <span style="color: #f56c6c; font-weight: 600">{{ fmtQty(row.total_qty) }}</span>
        </template>
      </el-table-column>
      <el-table-column label="预警线" width="110" align="right">
        <template #default="{ row }">{{ fmtQty(row.warn_qty) }}</template>
      </el-table-column>
      <el-table-column label="缺口数量" width="110" align="right">
        <template #default="{ row }">{{ fmtQty(Number(row.warn_qty) - Number(row.total_qty)) }}</template>
      </el-table-column>
      <el-table-column label="达成率" min-width="180">
        <template #default="{ row }">
          <el-progress
            :percentage="Math.min(100, Math.round((Number(row.total_qty) / Number(row.warn_qty)) * 100))"
            :status="Number(row.total_qty) === 0 ? 'exception' : 'warning'"
          />
        </template>
      </el-table-column>
      <el-table-column label="库存金额" width="130" align="right">
        <template #default="{ row }">{{ fmtMoney(row.total_amount) }}</template>
      </el-table-column>
    </el-table>
  </el-card>
</template>

<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { Refresh } from '@element-plus/icons-vue'
import { stockApi } from '@/api/stock'
import type { Row } from '@/api/base'
import { fmtMoney, fmtQty } from '@/utils/format'

const loading = ref(false)
const rows = ref<Row[]>([])

async function load() {
  loading.value = true
  try {
    rows.value = await stockApi.warnings()
  } finally {
    loading.value = false
  }
}

onMounted(load)
</script>
