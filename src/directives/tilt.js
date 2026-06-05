/**
 * v-tilt —— 鼠标悬停时的 3D 倾斜 + 跟随光晕。
 *
 * 用法：  <div v-tilt> ... </div>
 *         <div v-tilt="{ max: 6, glare: false }"> ... </div>
 *
 * 自动跳过触摸屏与「减少动态效果」偏好。
 */

const reduceMotion =
  typeof window !== 'undefined' &&
  window.matchMedia &&
  window.matchMedia('(prefers-reduced-motion: reduce)').matches

const isTouch =
  typeof window !== 'undefined' && window.matchMedia('(hover: none)').matches

export default {
  mounted(el, binding) {
    if (reduceMotion || isTouch) return

    const opts = Object.assign(
      { max: 8, scale: 1.012, glare: true, perspective: 900 },
      binding.value || {}
    )

    el.style.transformStyle = 'preserve-3d'
    el.style.transition =
      'transform 0.5s var(--ease-out), box-shadow 0.5s var(--ease-out)'
    el.style.willChange = 'transform'

    let glare = null
    if (opts.glare) {
      glare = document.createElement('span')
      Object.assign(glare.style, {
        position: 'absolute',
        inset: '0',
        borderRadius: 'inherit',
        pointerEvents: 'none',
        opacity: '0',
        transition: 'opacity 0.4s var(--ease-out)',
        background:
          'radial-gradient(circle at 50% 50%, rgba(255,255,255,0.28), rgba(255,255,255,0) 45%)',
        zIndex: '4'
      })
      // make sure children stay above the glare unless they opt in
      if (getComputedStyle(el).position === 'static') el.style.position = 'relative'
      el.appendChild(glare)
    }

    let raf = 0
    let pending = null

    const apply = () => {
      raf = 0
      if (!pending) return
      const { rx, ry, gx, gy } = pending
      el.style.transform = `perspective(${opts.perspective}px) rotateX(${rx}deg) rotateY(${ry}deg) scale(${opts.scale})`
      if (glare) {
        glare.style.opacity = '1'
        glare.style.background = `radial-gradient(circle at ${gx}% ${gy}%, rgba(255,255,255,0.28), rgba(255,255,255,0) 45%)`
      }
    }

    const onMove = (e) => {
      const r = el.getBoundingClientRect()
      const px = (e.clientX - r.left) / r.width // 0..1
      const py = (e.clientY - r.top) / r.height
      pending = {
        rx: (0.5 - py) * 2 * opts.max,
        ry: (px - 0.5) * 2 * opts.max,
        gx: px * 100,
        gy: py * 100
      }
      if (!raf) raf = requestAnimationFrame(apply)
    }

    const onLeave = () => {
      if (raf) cancelAnimationFrame(raf)
      raf = 0
      pending = null
      el.style.transform = ''
      if (glare) glare.style.opacity = '0'
    }

    el.addEventListener('mousemove', onMove)
    el.addEventListener('mouseleave', onLeave)

    el.__tiltCleanup = () => {
      el.removeEventListener('mousemove', onMove)
      el.removeEventListener('mouseleave', onLeave)
      if (raf) cancelAnimationFrame(raf)
      if (glare && glare.parentNode) glare.parentNode.removeChild(glare)
    }
  },

  unmounted(el) {
    if (el.__tiltCleanup) el.__tiltCleanup()
  }
}
