<template>
  <el-card shadow="never">
    <div class="query-bar">
      <el-input v-model="query.keyword" placeholder="采购单号/供应商" clearable style="width: 210px" @keyup.enter="load(1)" />
      <el-select v-model="query.status" placeholder="全部状态" clearable style="width: 140px">
        <el-option label="未付款" value="UNPAID" />
        <el-option label="部分付款" value="PARTIAL" />
        <el-option label="已结清" value="PAID" />
      </el-select>
      <el-button type="primary" :icon="Search" @click="load(1)">查询</el-button>
    </div>

    <el-table v-loading="loading" :data="rows" stripe>
      <el-table-column prop="orderNo" label="采购单号" width="150" />
      <el-table-column prop="supplierName" label="供应商" min-width="200" show-overflow-tooltip />
      <el-table-column label="应付金额" width="130" align="right">
        <template #default="{ row }">{{ fmtMoney(row.totalAmount) }}</template>
      </el-table-column>
      <el-table-column label="已付金额" width="130" align="right">
        <template #default="{ row }">{{ fmtMoney(row.paidAmount) }}</template>
      </el-table-column>
      <el-table-column label="未付余额" width="130" align="right">
        <template #default="{ row }">
          <span :style="{ color: Number(row.balance) > 0 ? '#f56c6c' : '#67c23a', fontWeight: 600 }">{{ fmtMoney(row.balance) }}</span>
        </template>
      </el-table-column>
      <el-table-column label="状态" width="100" align="center">
        <template #default="{ row }">
          <el-tag :type="settleStatusMap[row.status]?.type" size="small">{{ settleStatusMap[row.status]?.text }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column prop="createdAt" label="入账时间" width="165" />
      <el-table-column label="操作" width="170" fixed="right">
        <template #default="{ row }">
          <el-button v-if="row.status !== 'PAID'" link type="primary" @click="openSettle(row)">付款登记</el-button>
          <el-button link type="info" @click="openRecords(row)">付款记录</el-button>
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

    <!-- 付款登记弹窗 -->
    <el-dialog v-model="settleVisible" title="付款登记" width="440px">
      <el-descriptions :column="1" border size="small" style="margin-bottom: 16px">
        <el-descriptions-item label="采购单号">{{ current?.orderNo }}</el-descriptions-item>
        <el-descriptions-item label="供应商">{{ current?.supplierName }}</el-descriptions-item>
        <el-descriptions-item label="未付余额">¥ {{ fmtMoney(current?.balance) }}</el-descriptions-item>
      </el-descriptions>
      <el-form label-width="90px">
        <el-form-item label="付款金额" required>
          <el-input-number v-model="settleForm.amount" :min="0.01" :max="Number(current?.balance || 0)" :precision="2" style="width: 100%" />
        </el-form-item>
        <el-form-item label="付款方式">
          <el-select v-model="settleForm.method" style="width: 100%">
            <el-option label="银行转账" value="银行转账" />
            <el-option label="承兑汇票" value="承兑汇票" />
            <el-option label="现金" value="现金" />
          </el-select>
        </el-form-item>
        <el-form-item label="备注">
          <el-input v-model="settleForm.remark" type="textarea" :rows="2" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="settleVisible = false">取消</el-button>
        <el-button type="primary" :loading="saving" @click="onSettle">确认付款</el-button>
      </template>
    </el-dialog>

    <!-- 付款记录弹窗 -->
    <el-dialog v-model="recordsVisible" :title="`付款记录 - ${current?.orderNo || ''}`" width="640px">
      <el-table :data="records" size="small" stripe>
        <el-table-column prop="createdAt" label="付款时间" width="165" />
        <el-table-column label="金额" width="120" align="right">
          <template #default="{ row }">{{ fmtMoney(row.amount) }}</template>
        </el-table-column>
        <el-table-column prop="payMethod" label="方式" width="110" />
        <el-table-column prop="remark" label="备注" min-width="150" />
      </el-table>
    </el-dialog>
  </el-card>
</template>

<script setup lang="ts">
import { onMounted, reactive, ref } from 'vue'
import { ElMessage } from 'element-plus'
import { Search } from '@element-plus/icons-vue'
import { payableApi } from '@/api/finance'
import type { Row } from '@/api/base'
import { fmtMoney, settleStatusMap } from '@/utils/format'

const loading = ref(false)
const saving = ref(false)
const rows = ref<Row[]>([])
const total = ref(0)
const records = ref<Row[]>([])
const current = ref<Row | null>(null)
const settleVisible = ref(false)
const recordsVisible = ref(false)

const query = reactive({ page: 1, size: 10, keyword: '', status: '' })
const settleForm = reactive({ amount: 0, method: '银行转账', remark: '' })

async function load(page?: number) {
  if (page) query.page = page
  loading.value = true
  try {
    const data = await payableApi.page({ ...query })
    rows.value = data.records
    total.value = data.total
  } finally {
    loading.value = false
  }
}

function openSettle(row: Row) {
  current.value = row
  settleForm.amount = Number(row.balance)
  settleForm.method = '银行转账'
  settleForm.remark = ''
  settleVisible.value = true
}

async function onSettle() {
  if (!current.value) return
  if (!settleForm.amount || settleForm.amount <= 0) return ElMessage.warning('请输入付款金额')
  saving.value = true
  try {
    await payableApi.pay(current.value.id, { ...settleForm })
    ElMessage.success('付款登记成功')
    settleVisible.value = false
    load()
  } finally {
    saving.value = false
  }
}

async function openRecords(row: Row) {
  current.value = row
  records.value = await payableApi.records(row.id)
  recordsVisible.value = true
}

onMounted(() => load())
</script>
