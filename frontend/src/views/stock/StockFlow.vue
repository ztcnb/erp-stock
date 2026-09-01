<template>
  <el-card shadow="never">
    <div class="query-bar">
      <el-select v-model="query.warehouseId" placeholder="全部仓库" clearable style="width: 150px">
        <el-option v-for="w in warehouses" :key="w.id" :label="w.name" :value="w.id" />
      </el-select>
      <el-select v-model="query.bizType" placeholder="全部类型" clearable style="width: 140px">
        <el-option label="采购入库" value="PURCHASE_IN" />
        <el-option label="销售出库" value="SALE_OUT" />
        <el-option label="盘盈" value="TAKING_GAIN" />
        <el-option label="盘亏" value="TAKING_LOSS" />
      </el-select>
      <el-input v-model="query.keyword" placeholder="商品/单号" clearable style="width: 190px" @keyup.enter="load(1)" />
      <el-date-picker
        v-model="dateRange"
        type="daterange"
        value-format="YYYY-MM-DD"
        start-placeholder="开始日期"
        end-placeholder="结束日期"
        style="width: 240px"
      />
      <el-button type="primary" :icon="Search" @click="load(1)">查询</el-button>
    </div>

    <el-table v-loading="loading" :data="rows" stripe>
      <el-table-column prop="createdAt" label="时间" width="165" />
      <el-table-column label="类型" width="100" align="center">
        <template #default="{ row }">
          <el-tag :type="flowTypeMap[row.bizType]?.type" size="small">{{ flowTypeMap[row.bizType]?.text }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column prop="bizNo" label="来源单号" width="150" />
      <el-table-column prop="warehouseName" label="仓库" width="110" />
      <el-table-column prop="productCode" label="商品编码" width="100" />
      <el-table-column prop="productName" label="商品名称" min-width="190" show-overflow-tooltip />
      <el-table-column label="变动数量" width="100" align="right">
        <template #default="{ row }">
          <span :style="{ color: Number(row.qtyChange) >= 0 ? '#67c23a' : '#f56c6c' }">
            {{ Number(row.qtyChange) >= 0 ? '+' : '' }}{{ fmtQty(row.qtyChange) }}
          </span>
        </template>
      </el-table-column>
      <el-table-column label="结存数量" width="100" align="right">
        <template #default="{ row }">{{ fmtQty(row.qtyAfter) }}</template>
      </el-table-column>
      <el-table-column label="单价" width="100" align="right">
        <template #default="{ row }">{{ fmtMoney(row.price) }}</template>
      </el-table-column>
      <el-table-column label="金额" width="110" align="right">
        <template #default="{ row }">{{ fmtMoney(row.amount) }}</template>
      </el-table-column>
      <el-table-column prop="remark" label="备注" width="110" show-overflow-tooltip />
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
import { flowTypeMap, fmtMoney, fmtQty } from '@/utils/format'

const loading = ref(false)
const rows = ref<Row[]>([])
const total = ref(0)
const warehouses = ref<Row[]>([])
const dateRange = ref<[string, string] | null>(null)

const query = reactive({
  page: 1,
  size: 10,
  warehouseId: undefined as number | undefined,
  bizType: '',
  keyword: '',
})

async function load(page?: number) {
  if (page) query.page = page
  loading.value = true
  try {
    const data = await stockApi.flows({
      ...query,
      startDate: dateRange.value?.[0],
      endDate: dateRange.value?.[1],
    })
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
