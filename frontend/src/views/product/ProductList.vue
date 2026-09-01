<template>
  <el-card shadow="never">
    <!-- 查询栏 -->
    <div class="query-bar">
      <el-input v-model="query.keyword" placeholder="商品名称/编码" clearable style="width: 220px" @keyup.enter="load(1)" />
      <el-tree-select
        v-model="query.categoryId"
        :data="categoryTree"
        :props="{ value: 'id', label: 'name', children: 'children' }"
        placeholder="按分类筛选(含子分类)"
        clearable
        check-strictly
        style="width: 220px"
      />
      <el-button type="primary" :icon="Search" @click="load(1)">查询</el-button>
      <el-button :icon="Refresh" @click="onReset">重置</el-button>
      <div style="flex: 1"></div>
      <el-button type="primary" :icon="Plus" @click="openDialog()">新增商品</el-button>
    </div>

    <el-table v-loading="loading" :data="rows" stripe>
      <el-table-column prop="code" label="编码" width="100" />
      <el-table-column prop="name" label="商品名称" min-width="200" show-overflow-tooltip />
      <el-table-column prop="categoryName" label="分类" width="110" />
      <el-table-column prop="unit" label="单位" width="70" />
      <el-table-column prop="spec" label="规格" width="110" show-overflow-tooltip />
      <el-table-column label="参考进价" width="100" align="right">
        <template #default="{ row }">{{ fmtMoney(row.purchasePrice) }}</template>
      </el-table-column>
      <el-table-column label="参考售价" width="100" align="right">
        <template #default="{ row }">{{ fmtMoney(row.salePrice) }}</template>
      </el-table-column>
      <el-table-column label="预警线" width="90" align="right">
        <template #default="{ row }">{{ fmtQty(row.warnQty) }}</template>
      </el-table-column>
      <el-table-column label="状态" width="80" align="center">
        <template #default="{ row }">
          <el-tag :type="row.status === 1 ? 'success' : 'info'" size="small">{{ row.status === 1 ? '在售' : '停售' }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column label="操作" width="140" fixed="right">
        <template #default="{ row }">
          <el-button link type="primary" @click="openDialog(row)">编辑</el-button>
          <el-popconfirm title="确定删除该商品吗?" @confirm="onDelete(row.id)">
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

    <!-- 编辑弹窗 -->
    <el-dialog v-model="dialogVisible" :title="form.id ? '编辑商品' : '新增商品'" width="560px">
      <el-form ref="formRef" :model="form" :rules="rules" label-width="90px">
        <el-form-item label="商品编码" prop="code">
          <el-input v-model="form.code" placeholder="如 P0043" />
        </el-form-item>
        <el-form-item label="商品名称" prop="name">
          <el-input v-model="form.name" />
        </el-form-item>
        <el-form-item label="商品分类" prop="categoryId">
          <el-tree-select
            v-model="form.categoryId"
            :data="categoryTree"
            :props="{ value: 'id', label: 'name', children: 'children' }"
            check-strictly
            style="width: 100%"
          />
        </el-form-item>
        <el-row>
          <el-col :span="12">
            <el-form-item label="计量单位" prop="unit">
              <el-input v-model="form.unit" placeholder="如 箱/瓶/台" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="规格">
              <el-input v-model="form.spec" />
            </el-form-item>
          </el-col>
        </el-row>
        <el-row>
          <el-col :span="12">
            <el-form-item label="参考进价" prop="purchasePrice">
              <el-input-number v-model="form.purchasePrice" :min="0" :precision="2" style="width: 100%" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="参考售价" prop="salePrice">
              <el-input-number v-model="form.salePrice" :min="0" :precision="2" style="width: 100%" />
            </el-form-item>
          </el-col>
        </el-row>
        <el-row>
          <el-col :span="12">
            <el-form-item label="预警线">
              <el-input-number v-model="form.warnQty" :min="0" :precision="0" style="width: 100%" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="状态">
              <el-switch v-model="form.status" :active-value="1" :inactive-value="0" active-text="在售" inactive-text="停售" />
            </el-form-item>
          </el-col>
        </el-row>
        <el-form-item label="备注">
          <el-input v-model="form.remark" type="textarea" :rows="2" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" :loading="saving" @click="onSave">保存</el-button>
      </template>
    </el-dialog>
  </el-card>
</template>

<script setup lang="ts">
import { onMounted, reactive, ref } from 'vue'
import { ElMessage, type FormInstance, type FormRules } from 'element-plus'
import { Plus, Refresh, Search } from '@element-plus/icons-vue'
import { categoryApi, productApi, type Row } from '@/api/base'
import { fmtMoney, fmtQty } from '@/utils/format'

const loading = ref(false)
const saving = ref(false)
const rows = ref<Row[]>([])
const total = ref(0)
const categoryTree = ref<Row[]>([])
const dialogVisible = ref(false)
const formRef = ref<FormInstance>()

const query = reactive({ page: 1, size: 10, keyword: '', categoryId: undefined as number | undefined })

const emptyForm = (): Row => ({
  id: undefined, code: '', name: '', categoryId: undefined, unit: '',
  spec: '', purchasePrice: 0, salePrice: 0, warnQty: 0, status: 1, remark: '',
})
const form = reactive<Row>(emptyForm())

const rules: FormRules = {
  code: [{ required: true, message: '请输入商品编码', trigger: 'blur' }],
  name: [{ required: true, message: '请输入商品名称', trigger: 'blur' }],
  categoryId: [{ required: true, message: '请选择商品分类', trigger: 'change' }],
  unit: [{ required: true, message: '请输入计量单位', trigger: 'blur' }],
  purchasePrice: [{ required: true, message: '请输入参考进价', trigger: 'blur' }],
  salePrice: [{ required: true, message: '请输入参考售价', trigger: 'blur' }],
}

async function load(page?: number) {
  if (page) query.page = page
  loading.value = true
  try {
    const data = await productApi.page({ ...query })
    rows.value = data.records
    total.value = data.total
  } finally {
    loading.value = false
  }
}

function onReset() {
  query.keyword = ''
  query.categoryId = undefined
  load(1)
}

function openDialog(row?: Row) {
  Object.assign(form, emptyForm(), row || {})
  dialogVisible.value = true
}

async function onSave() {
  if (!formRef.value) return
  await formRef.value.validate()
  saving.value = true
  try {
    if (form.id) {
      await productApi.update(form.id, form)
    } else {
      await productApi.create(form)
    }
    ElMessage.success('保存成功')
    dialogVisible.value = false
    load()
  } finally {
    saving.value = false
  }
}

async function onDelete(id: number) {
  await productApi.remove(id)
  ElMessage.success('删除成功')
  load()
}

onMounted(async () => {
  categoryTree.value = await categoryApi.tree()
  load()
})
</script>
