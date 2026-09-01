<template>
  <el-card shadow="never">
    <div class="query-bar">
      <el-select v-model="query.warehouseId" placeholder="全部仓库" clearable style="width: 160px">
        <el-option v-for="w in warehouses" :key="w.id" :label="w.name" :value="w.id" />
      </el-select>
      <el-input v-model="query.keyword" placeholder="商品名称/编码" clearable style="width: 220px" @keyup.enter="load(1)" />
      <el-button type="primary" :icon="Search" @click="load(1)">查询</el-button>
    </div>

    <el-table v-loading="loading" :data="rows" stripe>
      <el-table-column prop="warehouseName" label="仓库" width="120" />
      <el-table-column prop="productCode" label="商品编码" width="110" />
      <el-table-column prop="productName" label="商品名称" min-width="220" show-overflow-tooltip />
      <el-table-column prop="unit" label="单位" width="70" />
      <el-table-column label="库存数量" width="110" align="right">
        <template #default="{ row }">
          <span :style="{ color: isWarn(row) ? '#f56c6c' : undefined, fontWeight: isWarn(row) ? 600 : undefined }">
            {{ fmtQty(row.qty) }}
          </span>
        </template>
      </el-table-column>
      <el-table-column label="加权平均成本" width="130" align="right">
        <template #default="{ row }">{{ Number(row.avgCost).toFixed(4) }}</template>
      </el-table-column>
      <el-table-column label="库存金额" width="130" align="right">
        <template #default="{ row }">{{ fmtMoney(row.amount) }}</template>
      </el-table-column>
      <el-table-column label="预警线" width="90" align="right">
        <template #default="{ row }">{{ fmtQty(row.warnQty) }}</template>
      </el-table-column>
      <el-table-column prop="updatedAt" label="最近变动时间" width="170" />
    </el-table>

    <div class="pager">
      <el-pagination
        v-model:current-page="query.page"
        v-model:page-size="query.size"
        :total="total"
        :page-sizes="[10, 20, 50]"
        layout="total, sizes, prev, pager, next, jumper"
        @current-change="load()"
        @size-change="load(1)"
      />
    </div>
  </el-card>
</template>

<script setup lang="ts">
import { onMounted, reactive, ref } from 'vue'
import { Search } from '@element-plus/icons-vue'
import { warehouseApi, type Row } from '@/api/base'
import { stockApi } from '@/api/stock'
import { fmtMoney, fmtQty } from '@/utils/format'

const loading = ref(false)
const rows = ref<Row[]>([])
const total = ref(0)
const warehouses = ref<Row[]>([])

const query = reactive({ page: 1, size: 10, warehouseId: undefined as number | undefined, keyword: '' })

/** 单仓数量低于预警线时标红(总量口径见"库存预警"页) */
function isWarn(row: Row) {
  return Number(row.warnQty) > 0 && Number(row.qty) < Number(row.warnQty)
}

async function load(page?: number) {
  if (page) query.page = page
  loading.value = true
  try {
    const data = await stockApi.page({ ...query })
    rows.value = data.records
    total.value = data.total
  } finally {
    loading.value = false
  }
}

onMounted(async () => {
  warehouses.value = await warehouseApi.all()
  load()
})
</script>
