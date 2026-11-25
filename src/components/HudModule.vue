<script setup>
import { ref, onUnmounted } from 'vue'

/**
 * 「全息读数」—— 黑曜星轨玻璃材质：
 *   · 边缘锐利的深色毛玻璃 + 1px 顶部高光棱线
 *   · 指针追踪的径向聚光灯微光（rAF 节流）
 *   · 左侧能量脊 + 10px 精密光学角标
 */
defineProps({
  label: { type: String, default: '' },
  index: { type: String, default: '' },
  delay: { type: Number, default: 0 },
  tilt: { type: Boolean, default: true }
})

const innerRef = ref(null)
const mx = ref('50%')
const my = ref('50%')
const spot = ref(0)

let raf = 0
let pending = null

function flush() {
  raf = 0
  if (!pending) return
  mx.value = pending.x
  my.value = pending.y
  spot.value = 1
}

function onMove(e) {
  const el = innerRef.value
  if (!el) return
  const r = el.getBoundingClientRect()
  pending = {
    x: `${(((e.clientX - r.left) / r.width) * 100).toFixed(1)}%`,
    y: `${(((e.clientY - r.top) / r.height) * 100).toFixed(1)}%`
  }
  if (!raf) raf = requestAnimationFrame(flush)
}

function onLeave() {
  if (raf) cancelAnimationFrame(raf)
  raf = 0
  pending = null
  spot.value = 0
}

onUnmounted(() => {
  if (raf) cancelAnimationFrame(raf)
})
</script>

<template>
  <div class="hr reveal" :style="{ '--delay': delay + 's' }">
    <div
      ref="innerRef"
      class="hr__inner"
      :style="{ '--mx': mx, '--my': my, '--spot': spot }"
      v-tilt="tilt ? { max: 2, scale: 1.004, glare: false } : { max: 0, glare: false }"
      @mousemove="onMove"
      @mouseleave="onLeave"
    >
      <div class="hr__spot" aria-hidden="true" />
      <div class="hr__scan" aria-hidden="true" />
      <span class="hr__br hr__br--tl" aria-hidden="true" />
      <span class="hr__br hr__br--br" aria-hidden="true" />

      <header class="hr__head">
        <span class="hr__label"><i />{{ label }}</span>
        <span class="hr__head-r">
          <slot name="extra" />
          <span class="hr__idx">{{ index }}</span>
        </span>
      </header>
      <div class="hr__rule" />

      <div class="hr__body"><slot /></div>
    </div>
  </div>
</template>

<style scoped>
.hr {
  height: 100%;
  min-width: 0;
}
.hr__inner {
  position: relative;
  height: 100%;
  padding: clamp(16px, 2vw, 22px) clamp(17px, 2.2vw, 24px);
  display: flex;
  flex-direction: column;
  border-radius: 18px;
  background: linear-gradient(155deg, rgba(10, 15, 30, 0.66), rgba(7, 11, 22, 0.44));
  border: 1px solid rgba(255, 255, 255, 0.085);
  box-shadow: 0 18px 44px -20px rgba(0, 0, 0, 0.65),
    inset 0 1px 0 rgba(255, 255, 255, 0.12);
  -webkit-backdrop-filter: blur(20px) saturate(165%);
  backdrop-filter: blur(20px) saturate(165%);
  overflow: hidden;
  transition: transform 0.5s var(--ease-out), border-color 0.4s var(--ease-out),
    box-shadow 0.4s var(--ease-out);
}
.hr__inner:hover {
  border-color: color-mix(in srgb, var(--accent-a) 26%, rgba(255, 255, 255, 0.12));
  box-shadow: 0 22px 52px -20px rgba(0, 0, 0, 0.78),
    0 0 28px -14px color-mix(in srgb, var(--accent-a) 35%, transparent),
    inset 0 1px 0 rgba(255, 255, 255, 0.18);
}

/* 指针追踪聚光灯 */
.hr__spot {
  position: absolute;
  inset: 0;
  pointer-events: none;
  opacity: var(--spot, 0);
  background: radial-gradient(
    280px circle at var(--mx, 50%) var(--my, 50%),
    color-mix(in srgb, var(--accent-a) 13%, transparent),
    transparent 68%
  );
  transition: opacity 0.35s var(--ease-out);
}

.hr__scan {
  position: absolute;
  inset: 0;
  pointer-events: none;
  opacity: 0.32;
  background: repeating-linear-gradient(
    0deg,
    rgba(255, 255, 255, 0.025) 0 1px,
    transparent 1px 4px
  );
}

/* 左侧能量脊 */
.hr__inner::before {
  content: '';
  position: absolute;
  left: 0;
  top: 18px;
  bottom: 18px;
  width: 2px;
  border-radius: 2px;
  background: linear-gradient(180deg, var(--accent-a), var(--accent-b) 55%, transparent);
  opacity: 0.55;
  transition: opacity 0.4s, box-shadow 0.4s;
}
.hr__inner:hover::before {
  opacity: 1;
  box-shadow: 0 0 12px color-mix(in srgb, var(--accent-a) 75%, transparent);
}

/* 精密光学角标 */
.hr__br {
  position: absolute;
  width: 10px;
  height: 10px;
  border: 0 solid color-mix(in srgb, var(--accent-a) 48%, transparent);
  transition: width 0.35s var(--ease-out), height 0.35s var(--ease-out),
    border-color 0.35s;
  z-index: 3;
}
.hr__br--tl {
  top: 7px;
  left: 7px;
  border-top-width: 1.5px;
  border-left-width: 1.5px;
  border-top-left-radius: 4px;
}
.hr__br--br {
  bottom: 7px;
  right: 7px;
  border-bottom-width: 1.5px;
  border-right-width: 1.5px;
  border-bottom-right-radius: 4px;
}
.hr__inner:hover .hr__br {
  width: 13px;
  height: 13px;
  border-color: var(--accent-a);
}

.hr__head {
  position: relative;
  z-index: 2;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 8px;
  font-family: var(--font-mono);
  font-size: 0.62rem;
  letter-spacing: 1.6px;
  text-transform: uppercase;
  color: var(--text-dim);
}
.hr__label {
  display: inline-flex;
  align-items: center;
  gap: 7px;
  color: var(--accent-a);
}
.hr__label i {
  width: 5px;
  height: 5px;
  border-radius: 1px;
  background: var(--accent-a);
  box-shadow: 0 0 7px var(--accent-a);
  animation: blink 2s ease-in-out infinite;
}
@keyframes blink {
  50% {
    opacity: 0.32;
  }
}
.hr__head-r {
  display: inline-flex;
  align-items: center;
  gap: 8px;
}
.hr__idx {
  font-variant-numeric: tabular-nums;
  opacity: 0.72;
}
.hr__rule {
  position: relative;
  z-index: 2;
  height: 1px;
  margin: 9px 0 14px;
  background: linear-gradient(
    90deg,
    color-mix(in srgb, var(--accent-a) 55%, transparent),
    rgba(255, 255, 255, 0.06) 55%,
    transparent
  );
}
.hr__body {
  position: relative;
  z-index: 2;
  flex: 1;
  min-height: 0;
  display: flex;
  flex-direction: column;
  justify-content: center;
}

@media (prefers-reduced-motion: reduce) {
  .hr__spot {
    display: none;
  }
}
</style>
