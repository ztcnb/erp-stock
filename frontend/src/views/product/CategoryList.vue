<template>
  <el-card shadow="never">
    <div class="query-bar">
      <span style="color: #909399; font-size: 13px">商品分类支持三级树形结构,拖动无效,请通过"新增子分类"维护层级</span>
      <div style="flex: 1"></div>
      <el-button type="primary" :icon="Plus" @click="openDialog(0)">新增根分类</el-button>
    </div>

    <el-table v-loading="loading" :data="tree" row-key="id" default-expand-all>
      <el-table-column prop="name" label="分类名称" min-width="240" />
      <el-table-column prop="sort" label="排序" width="90" align="center" />
      <el-table-column prop="createdAt" label="创建时间" width="180" />
      <el-table-column label="操作" width="240" fixed="right">
        <template #default="{ row }">
          <el-button link type="primary" @click="openDialog(row.id)">新增子分类</el-button>
          <el-button link type="primary" @click="openDialog(undefined, row)">编辑</el-button>
          <el-popconfirm title="确定删除该分类吗?" @confirm="onDelete(row.id)">
            <template #reference>
              <el-button link type="danger">删除</el-button>
            </template>
          </el-popconfirm>
        </template>
      </el-table-column>
    </el-table>

    <el-dialog v-model="dialogVisible" :title="form.id ? '编辑分类' : '新增分类'" width="420px">
      <el-form ref="formRef" :model="form" :rules="rules" label-width="90px">
        <el-form-item label="上级分类">
          <el-tree-select
            v-model="form.parentId"
            :data="parentOptions"
            :props="{ value: 'id', label: 'name', children: 'children' }"
            check-strictly
            style="width: 100%"
          />
        </el-form-item>
        <el-form-item label="分类名称" prop="name">
          <el-input v-model="form.name" />
        </el-form-item>
        <el-form-item label="排序">
          <el-input-number v-model="form.sort" :min="0" style="width: 100%" />
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
import { computed, onMounted, reactive, ref } from 'vue'
import { ElMessage, type FormInstance, type FormRules } from 'element-plus'
import { Plus } from '@element-plus/icons-vue'
import { categoryApi, type Row } from '@/api/base'

const loading = ref(false)
const saving = ref(false)
const tree = ref<Row[]>([])
const dialogVisible = ref(false)
const formRef = ref<FormInstance>()

const form = reactive<Row>({ id: undefined, name: '', parentId: 0, sort: 0 })

const rules: FormRules = {
  name: [{ required: true, message: '请输入分类名称', trigger: 'blur' }],
}

/** 上级分类选项:附加"根分类"虚拟节点 */
const parentOptions = computed(() => [{ id: 0, name: '(根分类)', children: [] }, ...tree.value])

async function load() {
  loading.value = true
  try {
    tree.value = await categoryApi.tree()
  } finally {
    loading.value = false
  }
}

function openDialog(parentId?: number, row?: Row) {
  if (row) {
    Object.assign(form, { id: row.id, name: row.name, parentId: row.parentId, sort: row.sort })
  } else {
    Object.assign(form, { id: undefined, name: '', parentId: parentId ?? 0, sort: 0 })
  }
  dialogVisible.value = true
}

async function onSave() {
  if (!formRef.value) return
  await formRef.value.validate()
  saving.value = true
  try {
    if (form.id) {
      await categoryApi.update(form.id, form)
    } else {
      await categoryApi.create(form)
    }
    ElMessage.success('保存成功')
    dialogVisible.value = false
    load()
  } finally {
    saving.value = false
  }
}

async function onDelete(id: number) {
  await categoryApi.remove(id)
  ElMessage.success('删除成功')
  load()
}

onMounted(load)
</script>
