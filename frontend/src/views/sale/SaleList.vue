<template>
  <el-card shadow="never">
    <div class="query-bar">
      <el-input v-model="query.keyword" placeholder="单号/客户" clearable style="width: 200px" @keyup.enter="load(1)" />
      <el-select v-model="query.status" placeholder="状态" clearable style="width: 130px">
        <el-option label="草稿" value="DRAFT" />
        <el-option label="已审核" value="APPROVED" />
        <el-option label="已出库" value="SHIPPED" />
        <el-option label="已作废" value="CANCELED" />
      </el-select>
      <el-date-picker
        v-model="dateRange"
        type="daterange"
        value-format="YYYY-MM-DD"
        start-placeholder="开始日期"
        end-placeholder="结束日期"
        style="width: 240px"
      />
      <el-button type="primary" :icon="Search" @click="load(1)">查询</el-button>
      <div style="flex: 1"></div>
      <el-button type="primary" :icon="Plus" @click="router.push('/sale/edit')">新建销售单</el-button>
    </div>

    <el-table v-loading="loading" :data="rows" stripe>
      <el-table-column prop="orderNo" label="单号" width="150">
        <template #default="{ row }">
          <el-link type="primary" @click="router.push(`/sale/edit/${row.id}`)">{{ row.orderNo }}</el-link>
        </template>
      </el-table-column>
      <el-table-column prop="customerName" label="客户" min-width="170" show-overflow-tooltip />
      <el-table-column prop="warehouseName" label="发货仓库" width="110" />
      <el-table-column label="数量" width="80" align="right">
        <template #default="{ row }">{{ fmtQty(row.totalQty) }}</template>
      </el-table-column>
      <el-table-column label="金额" width="110" align="right">
        <template #default="{ row }">{{ fmtMoney(row.totalAmount) }}</template>
      </el-table-column>
      <el-table-column label="毛利" width="110" align="right">
        <template #default="{ row }">
          <span v-if="row.status === 'SHIPPED'" :style="{ color: Number(row.grossProfit) >= 0 ? '#67c23a' : '#f56c6c' }">
            {{ fmtMoney(row.grossProfit) }}
          </span>
          <span v-else style="color: #c0c4cc">-</span>
        </template>
      </el-table-column>
      <el-table-column label="状态" width="90" align="center">
        <template #default="{ row }">
          <el-tag :type="orderStatusMap[row.status]?.type" size="small">{{ orderStatusMap[row.status]?.text }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column prop="createdByName" label="制单人" width="90" />
      <el-table-column prop="createdAt" label="制单时间" width="165" />
      <el-table-column label="操作" width="220" fixed="right">
        <template #default="{ row }">
          <template v-if="row.status === 'DRAFT'">
            <el-button link type="primary" @click="router.push(`/sale/edit/${row.id}`)">编辑</el-button>
            <el-button link type="success" @click="onApprove(row)">审核</el-button>
            <el-button link type="warning" @click="onCancel(row)">作废</el-button>
          </template>
          <template v-else-if="row.status === 'APPROVED'">
            <el-button link type="success" @click="onOutbound(row)">出库</el-button>
          </template>
          <el-popconfirm v-if="row.status === 'DRAFT' || row.status === 'CANCELED'" title="确定删除该单据吗?" @confirm="onDelete(row.id)">
            <template #reference>
              <el-button link type="danger">删除</el-button>
            </template>
          </el-popconfirm>
        </template>
      </el-table-column>
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
import { useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Plus, Search } from '@element-plus/icons-vue'
import { saleApi } from '@/api/order'
import type { Row } from '@/api/base'
import { fmtMoney, fmtQty, orderStatusMap } from '@/utils/format'

const router = useRouter()
const loading = ref(false)
const rows = ref<Row[]>([])
const total = ref(0)
const dateRange = ref<[string, string] | null>(null)

const query = reactive({ page: 1, size: 10, keyword: '', status: '' })

async function load(page?: number) {
  if (page) query.page = page
  loading.value = true
  try {
    const data = await saleApi.page({
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

async function onApprove(row: Row) {
  await ElMessageBox.confirm(`确定审核销售单 ${row.orderNo} 吗?审核时将校验库存是否充足。`, '审核确认', { type: 'warning' })
  await saleApi.approve(row.id)
  ElMessage.success('审核成功')
  load()
}

async function onCancel(row: Row) {
  await ElMessageBox.confirm(`确定作废销售单 ${row.orderNo} 吗?`, '作废确认', { type: 'warning' })
  await saleApi.cancel(row.id)
  ElMessage.success('已作废')
  load()
}

async function onOutbound(row: Row) {
  await ElMessageBox.confirm(
    `确定对销售单 ${row.orderNo} 执行出库吗?出库将扣减库存,按加权平均成本核算毛利,并生成应收账款。`,
    '出库确认',
    { type: 'warning' },
  )
  await saleApi.outbound(row.id)
  ElMessage.success('出库成功')
  load()
}

async function onDelete(id: number) {
  await saleApi.remove(id)
  ElMessage.success('删除成功')
  load()
}

onMounted(() => load())
</script>
