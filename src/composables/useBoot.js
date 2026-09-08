import { ref, onUnmounted } from 'vue'

const SESSION_KEY = 'aurora:home-boot:v1'

export function useBoot() {
  let seen = window.matchMedia('(prefers-reduced-motion: reduce)').matches
  try {
    seen ||= sessionStorage.getItem(SESSION_KEY) === 'done'
  } catch {
    // 存储不可用时仍允许正常进入主页。
  }

  const stage = ref(seen ? 'ready' : 'loading')
  const loaderMounted = ref(!seen)
  let handoffTimer

  function onBootDone() {
    clearTimeout(handoffTimer)
    loaderMounted.value = false
    stage.value = 'ready'
    try {
      sessionStorage.setItem(SESSION_KEY, 'done')
    } catch {
      // 隐私模式禁用存储时，本次跳过仍然生效。
    }
  }

  function onLoaderDone() {
    if (stage.value !== 'loading') return
    stage.value = 'boot'
    // 等自检画面覆盖加载页后再卸载，避免交接时露出空白。
    handoffTimer = setTimeout(() => { loaderMounted.value = false }, 520)
  }

  onUnmounted(() => clearTimeout(handoffTimer))
  return { stage, loaderMounted, onLoaderDone, onBootDone }
}
