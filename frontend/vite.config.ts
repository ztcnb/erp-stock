import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import { fileURLToPath, URL } from 'node:url'

// https://vite.dev/config/
export default defineConfig({
  plugins: [vue()],
  resolve: {
    alias: {
      '@': fileURLToPath(new URL('./src', import.meta.url)),
    },
  },
  server: {
    port: 5302,
    proxy: {
      // 开发环境代理到后端(context-path 为 /api)
      '/api': {
        target: 'http://127.0.0.1:9102',
        changeOrigin: true,
      },
    },
  },
})
