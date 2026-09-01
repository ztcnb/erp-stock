<template>
  <el-card shadow="never" v-loading="loading">
    <template #header>
      <div style="display: flex; align-items: center; gap: 12px">
        <el-button :icon="Back" @click="router.push('/stock/taking')">返回</el-button>
        <span style="font-weight: 600">
          盘点明细
          <span style="color: #909399; margin-left: 8px">{{ detail.takingNo }}</span>
        </span>
        <el-tag :type="finished ? 'success' : 'warning'">{{ finished ? '已完成' : '盘点中' }}</el-tag>
        <span style="color: #909399">仓库:{{ detail.warehouseName }}</span>
      </div>
    </template>

    <el-table :data="items" border size="small" stripe>
      <el-table-column type="index" label="#" width="50" align="center" />
      <el-table-column prop="productCode" label="商品编码" width="110" />
      <el-table-column prop="productName" label="商品名称" min-width="220" show-overflow-tooltip />
      <el-table-column prop="unit" label="单位" width="70" align="center" />
      <el-table-column label="账面数量" width="110" align="right">
        <template #default="{ row }">{{ fmtQty(row.bookQty) }}</template>
      </el-table-column>
      <el-table-column label="实盘数量" width="170" align="right">
        <template #default="{ row }">
          <template v-if="finished">{{ row.actualQty == null ? '-' : fmtQty(row.actualQty) }}</template>
          <el-input-number
            v-else
            v-model="row.actualQty"
            :min="0"
            :precision="0"
            controls-position="right"
            placeholder="未盘不调整"
            style="width: 100%"
          />
        </template>
      </el-table-column>
      <el-table-column label="盈亏" width="110" align="right">
        <template #default="{ row }">
          <span v-if="diffOf(row) !== 0" :style="{ color: diffOf(row) > 0 ? '#67c23a' : '#f56c6c' }">
            {{ diffOf(row) > 0 ? '+' : '' }}{{ fmtQty(diffOf(row)) }}
          </span>
          <span v-else style="color: #c0c4cc">0</span>
        </template>
      </el-table-column>
    </el-table>

    <div v-if="!finished" style="margin-top: 20px; text-align: right">
      <el-button :loading="saving" @click="onSave">保存实盘</el-button>
      <el-button type="primary" :loading="saving" @click="onFinish">完成盘点</el-button>
    </div>
  </el-card>
</template>

<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Back } from '@element-plus/icons-vue'
import { takingApi } from '@/api/stock'
import type { Row } from '@/api/base'
import { fmtQty } from '@/utils/format'

const route = useRoute()
const router = useRouter()
const takingId = Number(route.params.id)

const loading = ref(false)
const saving = ref(false)
const detail = ref<Row>({})
const items = ref<Row[]>([])

const finished = computed(() => detail.value.status === 'FINISHED')

function diffOf(row: Row): number {
  if (row.actualQty == null) return 0
  return Number(row.actualQty) - Number(row.bookQty)
}

async function load() {
  loading.value = true
  try {
    const data = await takingApi.detail(takingId)
    detail.value = data
    items.value = (data.items || []).map((i: Row) => ({
      ...i,
      actualQty: i.actualQty == null ? undefined : Number(i.actualQty),
      bookQty: Number(i.bookQty),
    }))
  } finally {
    loading.value = false
  }
}

/** 收集已录入实盘的行 */
function collectEntered() {
  return items.value
    .filter((i) => i.actualQty != null)
    .map((i) => ({ id: i.id as number, actualQty: Number(i.actualQty) }))
}

async function onSave() {
  const entered = collectEntered()
  if (entered.length === 0) return ElMessage.warning('尚未录入任何实盘数量')
  saving.value = true
  try {
    await takingApi.saveItems(takingId, entered)
    ElMessage.success('保存成功')
    load()
  } finally {
    saving.value = false
  }
}

async function onFinish() {
  const entered = collectEntered()
  if (entered.length === 0) return ElMessage.warning('尚未录入任何实盘数量')
  await ElMessageBox.confirm(
    '完成盘点后将按 实盘 - 账面 生成盘盈/盘亏调整流水并更新库存,未录入实盘的行不调整。确定完成吗?',
    '完成确认',
    { type: 'warning' },
  )
  saving.value = true
  try {
    await takingApi.saveItems(takingId, entered)
    await takingApi.finish(takingId)
    ElMessage.success('盘点完成,盈亏已调整入库存流水')
    load()
  } finally {
    saving.value = false
  }
}

onMounted(load)
</script>
