<template>
  <el-card shadow="never">
    <div class="query-bar">
      <el-select v-model="query.status" placeholder="全部状态" clearable style="width: 140px" @change="load(1)">
        <el-option label="盘点中" value="DRAFT" />
        <el-option label="已完成" value="FINISHED" />
      </el-select>
      <el-button type="primary" :icon="Search" @click="load(1)">查询</el-button>
      <div style="flex: 1"></div>
      <el-button type="primary" :icon="Plus" @click="createVisible = true">新建盘点单</el-button>
    </div>

    <el-table v-loading="loading" :data="rows" stripe>
      <el-table-column prop="takingNo" label="盘点单号" width="150">
        <template #default="{ row }">
          <el-link type="primary" @click="router.push(`/stock/taking/${row.id}`)">{{ row.takingNo }}</el-link>
        </template>
      </el-table-column>
      <el-table-column prop="warehouseName" label="仓库" width="140" />
      <el-table-column label="状态" width="100" align="center">
        <template #default="{ row }">
          <el-tag :type="row.status === 'FINISHED' ? 'success' : 'warning'" size="small">
            {{ row.status === 'FINISHED' ? '已完成' : '盘点中' }}
          </el-tag>
        </template>
      </el-table-column>
      <el-table-column prop="remark" label="备注" min-width="160" show-overflow-tooltip />
      <el-table-column prop="createdByName" label="制单人" width="100" />
      <el-table-column prop="createdAt" label="创建时间" width="165" />
      <el-table-column prop="finishedAt" label="完成时间" width="165" />
      <el-table-column label="操作" width="160" fixed="right">
        <template #default="{ row }">
          <el-button link type="primary" @click="router.push(`/stock/taking/${row.id}`)">
            {{ row.status === 'DRAFT' ? '录入实盘' : '查看' }}
          </el-button>
          <el-popconfirm v-if="row.status === 'DRAFT'" title="确定删除该盘点单吗?" @confirm="onDelete(row.id)">
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
        layout="total, prev, pager, next"
        @current-change="load()"
      />
    </div>

    <!-- 新建盘点弹窗 -->
    <el-dialog v-model="createVisible" title="新建盘点单" width="420px">
      <el-form label-width="90px">
        <el-form-item label="盘点仓库" required>
          <el-select v-model="createForm.warehouseId" placeholder="请选择仓库" style="width: 100%">
            <el-option v-for="w in warehouses" :key="w.id" :label="w.name" :value="w.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="备注">
          <el-input v-model="createForm.remark" type="textarea" :rows="2" />
        </el-form-item>
      </el-form>
      <el-alert type="info" :closable="false" title="创建后将对该仓库当前所有库存记录生成账面快照,请在明细页录入实盘数量。" />
      <template #footer>
        <el-button @click="createVisible = false">取消</el-button>
        <el-button type="primary" :loading="saving" @click="onCreate">创建</el-button>
      </template>
    </el-dialog>
  </el-card>
</template>

<script setup lang="ts">
import { onMounted, reactive, ref } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { Plus, Search } from '@element-plus/icons-vue'
import { warehouseApi, type Row } from '@/api/base'
import { takingApi } from '@/api/stock'

const router = useRouter()
const loading = ref(false)
const saving = ref(false)
const rows = ref<Row[]>([])
const total = ref(0)
const warehouses = ref<Row[]>([])
const createVisible = ref(false)

const query = reactive({ page: 1, size: 10, status: '' })
const createForm = reactive({ warehouseId: undefined as number | undefined, remark: '' })

async function load(page?: number) {
  if (page) query.page = page
  loading.value = true
  try {
    const data = await takingApi.page({ ...query })
    rows.value = data.records
    total.value = data.total
  } finally {
    loading.value = false
  }
}

async function onCreate() {
  if (!createForm.warehouseId) return ElMessage.warning('请选择盘点仓库')
  saving.value = true
  try {
    const no = await takingApi.create({ warehouseId: createForm.warehouseId, remark: createForm.remark })
    ElMessage.success(`盘点单 ${no} 创建成功`)
    createVisible.value = false
    load(1)
  } finally {
    saving.value = false
  }
}

async function onDelete(id: number) {
  await takingApi.remove(id)
  ElMessage.success('删除成功')
  load()
}

onMounted(async () => {
  warehouses.value = await warehouseApi.all()
  load()
})
</script>
