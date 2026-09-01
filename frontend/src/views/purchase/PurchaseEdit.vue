<template>
  <el-card shadow="never" v-loading="loading">
    <template #header>
      <div style="display: flex; align-items: center; gap: 12px">
        <el-button :icon="Back" @click="router.push('/purchase/list')">返回</el-button>
        <span style="font-weight: 600">
          {{ orderId ? (readonly ? '采购单详情' : '编辑采购单') : '新建采购单' }}
          <span v-if="detail.orderNo" style="color: #909399; margin-left: 8px">{{ detail.orderNo }}</span>
        </span>
        <el-tag v-if="detail.status" :type="orderStatusMap[detail.status]?.type">{{ orderStatusMap[detail.status]?.text }}</el-tag>
      </div>
    </template>

    <!-- 单头 -->
    <el-form label-width="90px" :disabled="readonly">
      <el-row :gutter="16">
        <el-col :span="8">
          <el-form-item label="供应商" required>
            <el-select v-model="form.supplierId" filterable placeholder="请选择供应商" style="width: 100%">
              <el-option v-for="s in suppliers" :key="s.id" :label="s.name" :value="s.id" />
            </el-select>
          </el-form-item>
        </el-col>
        <el-col :span="8">
          <el-form-item label="入库仓库" required>
            <el-select v-model="form.warehouseId" placeholder="请选择仓库" style="width: 100%">
              <el-option v-for="w in warehouses" :key="w.id" :label="w.name" :value="w.id" />
            </el-select>
          </el-form-item>
        </el-col>
        <el-col :span="8">
          <el-form-item label="备注">
            <el-input v-model="form.remark" placeholder="选填" />
          </el-form-item>
        </el-col>
      </el-row>
    </el-form>

    <!-- 明细表格 -->
    <el-table :data="items" border size="small">
      <el-table-column type="index" label="#" width="50" align="center" />
      <el-table-column label="商品" min-width="260">
        <template #default="{ row }">
          <template v-if="readonly">{{ row.productName }}</template>
          <el-select v-else v-model="row.productId" filterable placeholder="选择商品" style="width: 100%" @change="onProductChange(row)">
            <el-option v-for="p in products" :key="p.id" :label="`${p.code} ${p.name}`" :value="p.id" />
          </el-select>
        </template>
      </el-table-column>
      <el-table-column label="单位" width="80" align="center">
        <template #default="{ row }">{{ row.unit || '-' }}</template>
      </el-table-column>
      <el-table-column label="数量" width="150" align="right">
        <template #default="{ row }">
          <template v-if="readonly">{{ fmtQty(row.qty) }}</template>
          <el-input-number v-else v-model="row.qty" :min="0.01" :precision="0" controls-position="right" style="width: 100%" />
        </template>
      </el-table-column>
      <el-table-column label="采购单价" width="160" align="right">
        <template #default="{ row }">
          <template v-if="readonly">{{ fmtMoney(row.price) }}</template>
          <el-input-number v-else v-model="row.price" :min="0" :precision="2" controls-position="right" style="width: 100%" />
        </template>
      </el-table-column>
      <el-table-column label="金额" width="130" align="right">
        <template #default="{ row }">
          <span class="money">{{ fmtMoney(row.qty * row.price) }}</span>
        </template>
      </el-table-column>
      <el-table-column v-if="!readonly" label="操作" width="70" align="center">
        <template #default="{ $index }">
          <el-button link type="danger" @click="items.splice($index, 1)">移除</el-button>
        </template>
      </el-table-column>
    </el-table>

    <div style="display: flex; align-items: center; margin-top: 12px">
      <el-button v-if="!readonly" :icon="Plus" @click="addRow">添加明细行</el-button>
      <div style="flex: 1"></div>
      <div style="font-size: 15px">
        合计数量:<b>{{ fmtQty(totalQty) }}</b>
        <span style="margin-left: 24px">合计金额:<b style="color: #f56c6c">¥ {{ fmtMoney(totalAmount) }}</b></span>
      </div>
    </div>

    <div v-if="!readonly" style="margin-top: 20px; text-align: right">
      <el-button @click="router.push('/purchase/list')">取消</el-button>
      <el-button type="primary" :loading="saving" @click="onSave">保存草稿</el-button>
    </div>
  </el-card>
</template>

<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { Back, Plus } from '@element-plus/icons-vue'
import { productApi, supplierApi, warehouseApi, type Row } from '@/api/base'
import { purchaseApi } from '@/api/order'
import { fmtMoney, fmtQty, orderStatusMap } from '@/utils/format'

interface ItemRow {
  productId: number | null
  productName?: string
  unit?: string
  qty: number
  price: number
}

const route = useRoute()
const router = useRouter()
const orderId = computed(() => (route.params.id ? Number(route.params.id) : null))

const loading = ref(false)
const saving = ref(false)
const suppliers = ref<Row[]>([])
const warehouses = ref<Row[]>([])
const products = ref<Row[]>([])
const detail = ref<Row>({})
const items = ref<ItemRow[]>([])
const form = reactive({ supplierId: undefined as number | undefined, warehouseId: undefined as number | undefined, remark: '' })

/** 非草稿单据只读 */
const readonly = computed(() => !!detail.value.status && detail.value.status !== 'DRAFT')

const totalQty = computed(() => items.value.reduce((s, i) => s + (i.qty || 0), 0))
const totalAmount = computed(() => items.value.reduce((s, i) => s + (i.qty || 0) * (i.price || 0), 0))

function addRow() {
  items.value.push({ productId: null, qty: 1, price: 0 })
}

/** 选择商品后带出单位与参考进价 */
function onProductChange(row: ItemRow) {
  const p = products.value.find((x) => x.id === row.productId)
  if (p) {
    row.unit = p.unit
    row.price = Number(p.purchasePrice)
    row.productName = p.name
  }
}

async function onSave() {
  if (!form.supplierId) return ElMessage.warning('请选择供应商')
  if (!form.warehouseId) return ElMessage.warning('请选择入库仓库')
  const valid = items.value.filter((i) => i.productId && i.qty > 0)
  if (valid.length === 0) return ElMessage.warning('请至少添加一行有效明细')
  saving.value = true
  try {
    const payload = {
      supplierId: form.supplierId,
      warehouseId: form.warehouseId,
      remark: form.remark,
      items: valid.map((i) => ({ productId: i.productId as number, qty: i.qty, price: i.price })),
    }
    if (orderId.value) {
      await purchaseApi.update(orderId.value, payload)
      ElMessage.success('保存成功')
    } else {
      const orderNo = await purchaseApi.create(payload)
      ElMessage.success(`创建成功,单号 ${orderNo}`)
    }
    router.push('/purchase/list')
  } finally {
    saving.value = false
  }
}

onMounted(async () => {
  loading.value = true
  try {
    const [ss, ws, ps] = await Promise.all([supplierApi.all(), warehouseApi.all(), productApi.all()])
    suppliers.value = ss
    warehouses.value = ws
    products.value = ps
    if (orderId.value) {
      const data = await purchaseApi.detail(orderId.value)
      detail.value = data
      form.supplierId = data.supplierId
      form.warehouseId = data.warehouseId
      form.remark = data.remark || ''
      items.value = (data.items || []).map((i: Row) => ({
        productId: i.productId,
        productName: i.productName,
        unit: i.unit,
        qty: Number(i.qty),
        price: Number(i.price),
      }))
    } else {
      addRow()
    }
  } finally {
    loading.value = false
  }
})
</script>
