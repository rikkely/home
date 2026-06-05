import { ref } from 'vue'

// 当前正在「建立链接」的目标（点击导航项时触发数据流过场）
export const linking = ref(null)

// 判断是否为「站内链接」：
//   · 以 / 或 ./ 开头的路径（如 /blog/）
//   · 或与当前页面同域名的完整地址（如 https://你的域名/lab/）
// 站内 → 当前标签页跳转（跟随当前域名，沉浸式「进入」子站）
// 站外 → 新标签页打开（保留主页）
function isInternalUrl(url) {
  if (/^\.?\//.test(url)) return true
  try {
    return new URL(url, location.href).origin === location.origin
  } catch (e) {
    return false
  }
}

export function launchLink(url, name) {
  if (linking.value) return
  linking.value = { url, name }
  const internal = isInternalUrl(url)
  // 过场进行到尾声时再真正跳转
  setTimeout(() => {
    try {
      if (internal) {
        location.href = url
      } else {
        window.open(url, '_blank', 'noopener')
      }
    } catch (e) {
      location.href = url
    }
  }, 720)
  // 收场（站内跳转时页面已在卸载，这里仅对站外/异常情况生效）
  setTimeout(() => {
    linking.value = null
  }, 1050)
}
