import { ref } from 'vue'

// 当前正在「建立链接」的目标（点击导航项时触发数据流过场）
export const linking = ref(null)

export function launchLink(url, name) {
  if (linking.value) return
  linking.value = { url, name }
  // 过场进行到尾声时打开链接（新标签页）
  setTimeout(() => {
    try {
      window.open(url, '_blank', 'noopener')
    } catch (e) {
      location.href = url
    }
  }, 720)
  // 收场
  setTimeout(() => {
    linking.value = null
  }, 1050)
}
