import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

// https://vite.dev/config/
export default defineConfig({
  // Use a relative base so the built dist/ can be opened from any sub-path
  // (or even directly via file:// after a quick local server).
  base: './',
  plugins: [vue()],
  server: {
    host: true,
    port: process.env.PORT ? Number(process.env.PORT) : 5173
  },
  build: {
    outDir: 'dist',
    assetsDir: 'assets',
    chunkSizeWarningLimit: 1500
  }
})
