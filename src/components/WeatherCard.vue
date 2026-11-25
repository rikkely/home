<script setup>
import { computed, ref } from 'vue'
import HudModule from './HudModule.vue'
import IconBase from './IconBase.vue'
import { useWeather } from '../composables/useWeather.js'

defineProps({ delay: { type: Number, default: 0 } })
const { cityName, desc, temp, tempNum, wind, humidity, series, icon, ready, reload } = useWeather()

const refreshing = ref(false)
async function handleReload() {
  if (refreshing.value) return
  refreshing.value = true
  try {
    await reload()
  } finally {
    refreshing.value = false
  }
}

// 温度曲线数据：有真实逐时数据就用真实的，否则用当前温度生成一条柔和示意曲线
const data = computed(() => {
  if (series.value && series.value.length >= 4) return series.value.slice(0, 8)
  const base = tempNum.value ?? 20
  return Array.from({ length: 8 }, (_, i) => base + Math.round(Math.sin(i / 1.4) * 2))
})

const W = 120
const H = 34
const PAD = 4

function smoothPath(points) {
  if (!points.length) return ''
  if (points.length === 1) return `M ${points[0].x.toFixed(1)},${points[0].y.toFixed(1)}`
  let path = `M ${points[0].x.toFixed(1)},${points[0].y.toFixed(1)}`
  for (let i = 0; i < points.length - 1; i++) {
    const p0 = points[i - 1] || points[i]
    const p1 = points[i]
    const p2 = points[i + 1]
    const p3 = points[i + 2] || p2
    const cp1x = p1.x + (p2.x - p0.x) / 6
    const cp1y = p1.y + (p2.y - p0.y) / 6
    const cp2x = p2.x - (p3.x - p1.x) / 6
    const cp2y = p2.y - (p3.y - p1.y) / 6
    path += ` C ${cp1x.toFixed(1)},${cp1y.toFixed(1)} ${cp2x.toFixed(1)},${cp2y.toFixed(1)} ${p2.x.toFixed(1)},${p2.y.toFixed(1)}`
  }
  return path
}

const geo = computed(() => {
  const d = data.value
  const n = d.length
  const min = Math.min(...d)
  const max = Math.max(...d)
  const range = max - min || 1
  const x = (i) => PAD + (i / (n - 1)) * (W - PAD * 2)
  const y = (v) => H - PAD - ((v - min) / range) * (H - PAD * 2)
  const pts = d.map((v, i) => ({ x: x(i), y: y(v) }))
  const line = smoothPath(pts)
  const first = pts[0]
  const last = pts[n - 1]
  return {
    line,
    area: `${line} L ${last.x.toFixed(1)},${H} L ${first.x.toFixed(1)},${H} Z`,
    last,
    min,
    max
  }
})
</script>

<template>
  <HudModule label="ATMOS.SCAN" index="02" :delay="delay">
    <template #extra>
      <button
        class="wx__btn"
        :class="{ 'is-spin': refreshing }"
        title="刷新天气"
        aria-label="刷新天气"
        @click="handleReload"
      >
        <IconBase name="refresh" :size="12" />
      </button>
    </template>

    <div class="wx">
      <div class="wx__main">
        <div class="wx__radar" :class="{ ready }">
          <span class="wx__sweep" />
          <IconBase :name="icon" :size="23" />
        </div>
        <div class="wx__data">
          <span class="wx__temp tabular">{{ ready ? temp || '—' : '··' }}</span>
          <span class="wx__desc">{{ ready ? desc : 'SCANNING…' }}</span>
        </div>
      </div>

      <!-- 温度平滑曲线 -->
      <div class="wx__chart">
        <span class="wx__axis wx__axis--hi">{{ geo.max }}°</span>
        <span class="wx__axis wx__axis--lo">{{ geo.min }}°</span>
        <svg class="wx__spark" :viewBox="`0 0 ${W} ${H}`" preserveAspectRatio="none">
          <defs>
            <linearGradient id="wxfill" x1="0" y1="0" x2="0" y2="1">
              <stop offset="0" stop-color="var(--accent-a)" stop-opacity="0.32" />
              <stop offset="1" stop-color="var(--accent-a)" stop-opacity="0" />
            </linearGradient>
          </defs>
          <path :d="geo.area" fill="url(#wxfill)" />
          <path
            :d="geo.line"
            fill="none"
            stroke="var(--accent-a)"
            stroke-width="1.5"
            stroke-linecap="round"
            vector-effect="non-scaling-stroke"
          />
          <circle class="wx__dot" :cx="geo.last.x" :cy="geo.last.y" r="2.2" fill="var(--accent-c)" />
        </svg>
      </div>

      <!-- 湿度 + 位置 -->
      <div class="wx__bars">
        <div class="wx__hum" v-if="humidity != null">
          <span class="wx__hk">HUM</span>
          <span class="wx__htrack"><i :style="{ width: humidity + '%' }" /></span>
          <span class="wx__hv tabular">{{ humidity }}%</span>
        </div>
        <div class="wx__meta">
          <span class="wx__pill"><IconBase name="map-pin" :size="11" />{{ cityName || 'LOCATION' }}</span>
          <span v-if="wind" class="wx__pill"><IconBase name="wind" :size="11" />{{ wind }}</span>
        </div>
      </div>
    </div>
  </HudModule>
</template>

<style scoped>
.wx__btn {
  display: grid;
  place-items: center;
  width: 22px;
  height: 22px;
  border-radius: 6px;
  color: var(--text-dim);
  transition: color 0.25s, background 0.25s, transform 0.45s var(--ease-out);
}
.wx__btn:hover {
  color: var(--accent-a);
  background: rgba(255, 255, 255, 0.08);
  transform: rotate(90deg);
}
.wx__btn.is-spin :deep(.icon) {
  animation: wxspin 0.8s linear infinite;
}
@keyframes wxspin {
  to {
    transform: rotate(360deg);
  }
}

.wx {
  display: flex;
  flex-direction: column;
  gap: 11px;
}
.wx__main {
  display: flex;
  align-items: center;
  gap: 14px;
}
.wx__radar {
  position: relative;
  display: grid;
  place-items: center;
  width: 48px;
  height: 48px;
  flex: none;
  border-radius: 50%;
  color: var(--accent-a);
  background: radial-gradient(circle, color-mix(in srgb, var(--accent-a) 14%, transparent), transparent 72%);
  box-shadow: inset 0 0 0 1px color-mix(in srgb, var(--accent-a) 26%, transparent);
  opacity: 0.65;
  transition: opacity 0.5s;
  overflow: hidden;
}
.wx__radar.ready {
  opacity: 1;
}
.wx__sweep {
  position: absolute;
  inset: 0;
  border-radius: 50%;
  background: conic-gradient(from 0deg, color-mix(in srgb, var(--accent-a) 50%, transparent), transparent 70deg);
  -webkit-mask: radial-gradient(circle, #000 62%, transparent 63%);
  mask: radial-gradient(circle, #000 62%, transparent 63%);
  animation: sweep 3.2s linear infinite;
}
@keyframes sweep {
  to {
    transform: rotate(360deg);
  }
}
.wx__data {
  display: flex;
  flex-direction: column;
  min-width: 0;
}
.wx__temp {
  font-family: var(--font-mono);
  font-size: clamp(1.6rem, 3vw, 2.05rem);
  font-weight: 700;
  line-height: 1.05;
}
.wx__desc {
  font-size: 0.84rem;
  color: var(--text-soft);
}

/* 温度曲线 */
.wx__chart {
  position: relative;
  height: 36px;
}
.wx__spark {
  width: 100%;
  height: 100%;
  overflow: visible;
  filter: drop-shadow(0 0 5px color-mix(in srgb, var(--accent-a) 36%, transparent));
}
.wx__dot {
  filter: drop-shadow(0 0 5px var(--accent-c));
  animation: dotPulse 1.8s ease-in-out infinite;
}
@keyframes dotPulse {
  50% {
    r: 3.1;
  }
}
.wx__axis {
  position: absolute;
  right: 0;
  font-family: var(--font-mono);
  font-size: 0.56rem;
  color: var(--text-dim);
}
.wx__axis--hi {
  top: -2px;
}
.wx__axis--lo {
  bottom: -2px;
}

/* 湿度 + 位置 */
.wx__bars {
  display: flex;
  flex-direction: column;
  gap: 8px;
}
.wx__hum {
  display: flex;
  align-items: center;
  gap: 8px;
  font-family: var(--font-mono);
  font-size: 0.62rem;
  letter-spacing: 0.5px;
  color: var(--text-dim);
}
.wx__hk {
  color: var(--accent-a);
}
.wx__htrack {
  flex: 1;
  height: 6px;
  background: rgba(255, 255, 255, 0.1);
  -webkit-mask: repeating-linear-gradient(90deg, #000 0 7px, transparent 7px 10px);
  mask: repeating-linear-gradient(90deg, #000 0 7px, transparent 7px 10px);
}
.wx__htrack i {
  display: block;
  height: 100%;
  background: linear-gradient(90deg, var(--accent-a), var(--accent-b));
  box-shadow: 0 0 10px color-mix(in srgb, var(--accent-a) 55%, transparent);
  transition: width 0.9s var(--ease-out);
}
.wx__meta {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
}
.wx__pill {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  padding: 2px 8px;
  border-radius: 999px;
  font-family: var(--font-mono);
  font-size: 0.62rem;
  color: var(--text-soft);
  background: rgba(255, 255, 255, 0.05);
  border: 1px solid rgba(255, 255, 255, 0.08);
}
</style>
