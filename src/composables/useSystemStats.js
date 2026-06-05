import { ref, onMounted, onUnmounted } from 'vue'

const pad = (n) => String(n).padStart(2, '0')
const fmt = (s) => `${pad(Math.floor(s / 3600))}:${pad(Math.floor((s % 3600) / 60))}:${pad(s % 60)}`

/** 实时 FPS 与在线时长（自页面加载起）。 */
export function useSystemStats() {
  const fps = ref(60)
  const uptime = ref('00:00:00')

  let raf = 0
  let frames = 0
  let last = performance.now()
  const start = Date.now()
  let timer = null

  const loop = (now) => {
    frames += 1
    if (now - last >= 1000) {
      fps.value = Math.round((frames * 1000) / (now - last))
      frames = 0
      last = now
    }
    raf = requestAnimationFrame(loop)
  }

  onMounted(() => {
    raf = requestAnimationFrame(loop)
    timer = setInterval(() => {
      uptime.value = fmt(Math.floor((Date.now() - start) / 1000))
    }, 1000)
  })
  onUnmounted(() => {
    cancelAnimationFrame(raf)
    clearInterval(timer)
  })

  return { fps, uptime }
}
