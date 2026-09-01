<template>
  <div class="login-page">
    <el-card class="login-card">
      <div class="login-title">
        <el-icon :size="28" color="#409eff"><Box /></el-icon>
        <h2>云仓进销存管理系统</h2>
        <p>面向中小贸易企业的进销存一体化解决方案</p>
      </div>
      <el-form ref="formRef" :model="form" :rules="rules" size="large" @keyup.enter="onSubmit">
        <el-form-item prop="username">
          <el-input v-model="form.username" placeholder="用户名" :prefix-icon="User" />
        </el-form-item>
        <el-form-item prop="password">
          <el-input v-model="form.password" type="password" placeholder="密码" show-password :prefix-icon="Lock" />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" class="login-btn" :loading="loading" @click="onSubmit">登 录</el-button>
        </el-form-item>
      </el-form>
      <el-alert type="info" :closable="false">
        <template #title>
          演示账号:admin / buyer01 / seller01 / stocker01,密码均为 123456
        </template>
      </el-alert>
    </el-card>
  </div>
</template>

<script setup lang="ts">
import { reactive, ref } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage, type FormInstance, type FormRules } from 'element-plus'
import { User, Lock } from '@element-plus/icons-vue'
import { useAuthStore } from '@/stores/auth'

const router = useRouter()
const auth = useAuthStore()
const formRef = ref<FormInstance>()
const loading = ref(false)

const form = reactive({ username: 'admin', password: '123456' })

const rules: FormRules = {
  username: [{ required: true, message: '请输入用户名', trigger: 'blur' }],
  password: [{ required: true, message: '请输入密码', trigger: 'blur' }],
}

async function onSubmit() {
  if (!formRef.value) return
  await formRef.value.validate()
  loading.value = true
  try {
    await auth.login(form.username, form.password)
    ElMessage.success('登录成功')
    router.push('/dashboard')
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
.login-page {
  height: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(135deg, #1f3b73 0%, #2b5aa6 50%, #3a7bd5 100%);
}
.login-card {
  width: 400px;
  padding: 8px 12px;
}
.login-title {
  text-align: center;
  margin-bottom: 16px;
}
.login-title h2 {
  margin: 8px 0 4px;
  color: #303133;
}
.login-title p {
  margin: 0 0 8px;
  color: #909399;
  font-size: 13px;
}
.login-btn {
  width: 100%;
}
</style>
