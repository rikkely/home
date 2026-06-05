import { ref, onMounted, onUnmounted } from 'vue'

const reduceMotion =
  typeof window !== 'undefined' &&
  window.matchMedia &&
  window.matchMedia('(prefers-reduced-motion: reduce)').matches

/** 归一化的指针位置，范围 -1 ~ 1，用于背景视差。 */
export function usePointer() {
  const x = ref(0)
  const y = ref(0)
  let raf = 0
  let next = { x: 0, y: 0 }

  const flush = () => {
    raf = 0
    x.value = next.x
    y.value = next.y
  }

  const onMove = (e) => {
    next = {
      x: (e.clientX / window.innerWidth - 0.5) * 2,
      y: (e.clientY / window.innerHeight - 0.5) * 2
    }
    if (!raf) raf = requestAnimationFrame(flush)
  }

  onMounted(() => {
    if (reduceMotion) return
    window.addEventListener('mousemove', onMove, { passive: true })
  })
  onUnmounted(() => {
    window.removeEventListener('mousemove', onMove)
    if (raf) cancelAnimationFrame(raf)
  })

  return { x, y }
}
