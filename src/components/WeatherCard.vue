<script setup>
import { computed } from 'vue'
import HudModule from './HudModule.vue'
import IconBase from './IconBase.vue'
import { useWeather } from '../composables/useWeather.js'

defineProps({ delay: { type: Number, default: 0 } })
const { cityName, desc, temp, tempNum, wind, humidity, series, icon, ready } = useWeather()

// 温度曲线数据：有真实逐时数据就用真实的，否则用当前温度生成一条柔和示意曲线
const data = computed(() => {
  if (series.value && series.value.length >= 4) return series.value.slice(0, 8)
  const base = tempNum.value ?? 20
  return Array.from({ length: 8 }, (_, i) => base + Math.round(Math.sin(i / 1.4) * 2))
})

const W = 120
const H = 32
const PAD = 3

const geo = computed(() => {
  const d = data.value
  const n = d.length
  const min = Math.min(...d)
  const max = Math.max(...d)
  const range = max - min || 1
  const x = (i) => PAD + (i / (n - 1)) * (W - PAD * 2)
  const y = (v) => H - PAD - ((v - min) / range) * (H - PAD * 2)
  const pts = d.map((v, i) => `${x(i).toFixed(1)},${y(v).toFixed(1)}`)
  return {
    line: pts.join(' '),
    area: `M ${x(0).toFixed(1)},${H} L ${pts.join(' L ')} L ${x(n - 1).toFixed(1)},${H} Z`,
    last: { x: x(n - 1), y: y(d[n - 1]) },
    min,
    max
  }
})
</script>

<template>
  <HudModule label="ATMOS.SCAN" index="02" :delay="delay">
    <div class="wx">
      <div class="wx__main">
        <div class="wx__radar" :class="{ ready }">
          <span class="wx__sweep" />
          <IconBase :name="icon" :size="24" />
        </div>
        <div class="wx__data">
          <span class="wx__temp">{{ ready ? temp || '—' : '··' }}</span>
          <span class="wx__desc">{{ ready ? desc : 'SCANNING…' }}</span>
        </div>
      </div>

      <!-- 温度曲线 -->
      <div class="wx__chart">
        <span class="wx__axis wx__axis--hi">{{ geo.max }}°</span>
        <span class="wx__axis wx__axis--lo">{{ geo.min }}°</span>
        <svg class="wx__spark" :viewBox="`0 0 ${W} ${H}`" preserveAspectRatio="none">
          <defs>
            <linearGradient id="wxfill" x1="0" y1="0" x2="0" y2="1">
              <stop offset="0" stop-color="var(--accent-a)" stop-opacity="0.35" />
              <stop offset="1" stop-color="var(--accent-a)" stop-opacity="0" />
            </linearGradient>
          </defs>
          <path :d="geo.area" fill="url(#wxfill)" />
          <polyline
            :points="geo.line"
            fill="none"
            stroke="var(--accent-a)"
            stroke-width="1.4"
            stroke-linecap="round"
            stroke-linejoin="round"
            vector-effect="non-scaling-stroke"
          />
          <circle class="wx__dot" :cx="geo.last.x" :cy="geo.last.y" r="2" fill="var(--accent-c)" />
        </svg>
      </div>

      <!-- 湿度 + 位置 -->
      <div class="wx__bars">
        <div class="wx__hum" v-if="humidity != null">
          <span class="wx__hk">HUM</span>
          <span class="wx__htrack"><i :style="{ width: humidity + '%' }" /></span>
          <span class="wx__hv">{{ humidity }}%</span>
        </div>
        <div class="wx__meta">
          <span class="wx__loc"><IconBase name="map-pin" :size="12" />{{ cityName || 'LOCATION' }}</span>
          <span v-if="wind" class="wx__wind"><IconBase name="wind" :size="12" />{{ wind }}</span>
        </div>
      </div>
    </div>
  </HudModule>
</template>

<style scoped>
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
  width: 50px;
  height: 50px;
  flex: none;
  border-radius: 50%;
  color: var(--accent-a);
  background: radial-gradient(circle, color-mix(in srgb, var(--accent-a) 12%, transparent), transparent 70%);
  box-shadow: inset 0 0 0 1px color-mix(in srgb, var(--accent-a) 25%, transparent);
  opacity: 0.6;
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
  background: conic-gradient(from 0deg, color-mix(in srgb, var(--accent-a) 55%, transparent), transparent 70deg);
  -webkit-mask: radial-gradient(circle, #000 60%, transparent 61%);
  mask: radial-gradient(circle, #000 60%, transparent 61%);
  animation: sweep 3s linear infinite;
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
  font-size: clamp(1.6rem, 3vw, 2.1rem);
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
  height: 34px;
}
.wx__spark {
  width: 100%;
  height: 100%;
  overflow: visible;
  filter: drop-shadow(0 0 4px color-mix(in srgb, var(--accent-a) 40%, transparent));
}
.wx__dot {
  filter: drop-shadow(0 0 4px var(--accent-c));
  animation: dotPulse 1.6s ease-in-out infinite;
}
@keyframes dotPulse {
  50% {
    r: 3;
  }
}
.wx__axis {
  position: absolute;
  right: 0;
  font-family: var(--font-mono);
  font-size: 0.58rem;
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
  box-shadow: 0 0 10px color-mix(in srgb, var(--accent-a) 60%, transparent);
  transition: width 0.9s var(--ease-out);
}
.wx__meta {
  display: flex;
  flex-wrap: wrap;
  gap: 5px 16px;
  font-family: var(--font-mono);
  font-size: 0.66rem;
  color: var(--text-dim);
}
.wx__loc,
.wx__wind {
  display: inline-flex;
  align-items: center;
  gap: 5px;
}
</style>
