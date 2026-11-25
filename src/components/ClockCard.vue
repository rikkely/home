<script setup>
import HudModule from './HudModule.vue'
import { useClock } from '../composables/useClock.js'

defineProps({ delay: { type: Number, default: 0 } })
const { hh, mm, ss, secPct, tz, date, week, colon } = useClock()
</script>

<template>
  <HudModule label="SYS.CHRONO" index="01" :delay="delay">
    <template #extra>
      <span class="clock__tz">{{ tz }}</span>
    </template>

    <div class="clock">
      <div class="clock__time tabular">
        <span>{{ hh }}</span>
        <span class="clock__colon" :class="{ dim: !colon }">:</span>
        <span>{{ mm }}</span>
        <span class="clock__colon" :class="{ dim: !colon }">:</span>
        <span class="clock__sec">{{ ss }}</span>
      </div>
      <div class="clock__date">{{ date }} · {{ week }}</div>
      <div class="clock__sweep" aria-hidden="true">
        <span :style="{ width: secPct + '%' }" />
      </div>
    </div>
  </HudModule>
</template>

<style scoped>
.clock__tz {
  padding: 1px 6px;
  border-radius: 5px;
  font-size: 0.56rem;
  letter-spacing: 0.8px;
  color: var(--accent-b);
  background: color-mix(in srgb, var(--accent-b) 12%, transparent);
  border: 1px solid color-mix(in srgb, var(--accent-b) 25%, transparent);
}
.clock {
  display: flex;
  flex-direction: column;
  gap: 8px;
}
.clock__time {
  display: flex;
  align-items: baseline;
  font-family: var(--font-led);
  font-weight: 400;
  font-size: clamp(2.4rem, 4.8vw, 3.5rem);
  line-height: 1;
  letter-spacing: 2px;
  text-shadow: 0 0 22px color-mix(in srgb, var(--accent-b) 48%, transparent);
}
.clock__colon {
  margin: 0 2px;
  transition: opacity 0.25s;
}
.clock__colon.dim {
  opacity: 0.22;
}
.clock__sec {
  font-size: 0.45em;
  align-self: flex-end;
  margin-left: 6px;
  margin-bottom: 0.16em;
  color: var(--accent-a);
}
.clock__date {
  font-size: 0.8rem;
  color: var(--text-soft);
  letter-spacing: 0.4px;
}
.clock__sweep {
  height: 2px;
  margin-top: 4px;
  border-radius: 99px;
  background: rgba(255, 255, 255, 0.08);
  overflow: hidden;
}
.clock__sweep span {
  display: block;
  height: 100%;
  border-radius: inherit;
  background: linear-gradient(90deg, var(--accent-a), var(--accent-b), var(--accent-c));
  box-shadow: 0 0 10px color-mix(in srgb, var(--accent-a) 75%, transparent);
  transition: width 0.35s var(--ease-out);
}
</style>
