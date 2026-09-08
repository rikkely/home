import { ref } from 'vue'

export const linking = ref(null)
let navigationTimer
let resetTimer

export function isInternalUrl(value) {
  try {
    const url = new URL(value, location.href)
    return ['http:', 'https:'].includes(url.protocol) && url.origin === location.origin
  } catch {
    return false
  }
}

function resetLink() {
  clearTimeout(navigationTimer)
  clearTimeout(resetTimer)
  linking.value = null
}

export function launchLink(url, name, event) {
  // 保留浏览器原生的新标签页和外部协议处理，避免延迟弹窗被拦截。
  if (event.defaultPrevented || event.button !== 0 || event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) return
  if (!isInternalUrl(url)) return
  const target = new URL(url, location.href)
  if (target.pathname === location.pathname && target.search === location.search) return
  if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) return

  event.preventDefault()
  if (linking.value) return
  linking.value = { url: target.href, name }
  navigationTimer = setTimeout(() => location.assign(target.href), 200)
  resetTimer = setTimeout(resetLink, 1500)
}

// 后退缓存可能保留离开时的遮罩，恢复页面时必须清理。
window.addEventListener('pageshow', resetLink)
window.addEventListener('pagehide', resetLink)
if (import.meta.hot) {
  import.meta.hot.dispose(() => {
    resetLink()
    window.removeEventListener('pageshow', resetLink)
    window.removeEventListener('pagehide', resetLink)
  })
}
