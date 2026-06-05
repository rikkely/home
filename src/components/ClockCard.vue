<script setup>
import HudModule from './HudModule.vue'
import { useClock } from '../composables/useClock.js'

defineProps({ delay: { type: Number, default: 0 } })
const { hh, mm, ss, date, week, colon } = useClock()
</script>

<template>
  <HudModule label="SYS.CHRONO" index="01" :delay="delay">
    <div class="clock">
      <div class="clock__time">
        <span>{{ hh }}</span>
        <span class="clock__colon" :class="{ dim: !colon }">:</span>
        <span>{{ mm }}</span>
        <span class="clock__colon" :class="{ dim: !colon }">:</span>
        <span class="clock__sec">{{ ss }}</span>
      </div>
      <div class="clock__date">{{ date }} · {{ week }}</div>
    </div>
  </HudModule>
</template>

<style scoped>
.clock {
  display: flex;
  flex-direction: column;
  gap: 6px;
}
.clock__time {
  display: flex;
  align-items: baseline;
  font-family: var(--font-led);
  font-weight: 400;
  font-size: clamp(2.4rem, 5vw, 3.6rem);
  line-height: 1;
  letter-spacing: 2px;
  text-shadow: 0 0 22px color-mix(in srgb, var(--accent-b) 55%, transparent);
}
.clock__colon {
  margin: 0 2px;
  transition: opacity 0.25s;
}
.clock__colon.dim {
  opacity: 0.22;
}
.clock__sec {
  font-size: 0.46em;
  align-self: flex-end;
  margin-left: 6px;
  margin-bottom: 0.18em;
  color: var(--accent-a);
}
.clock__date {
  font-size: 0.8rem;
  color: var(--text-soft);
  letter-spacing: 0.4px;
}
</style>
