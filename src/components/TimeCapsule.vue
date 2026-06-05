<script setup>
import HudModule from './HudModule.vue'
import { useTimeCapsule } from '../composables/useTimeCapsule.js'

defineProps({ delay: { type: Number, default: 0 } })
const { items } = useTimeCapsule()

const CODES = ['DAY', 'WEEK', 'MONTH', 'YEAR']
</script>

<template>
  <HudModule label="TEMPORAL.LOAD" index="04" :delay="delay">
    <div class="tl">
      <div v-for="(it, i) in items" :key="it.label" class="tl__row">
        <div class="tl__head">
          <span class="tl__code">{{ CODES[i] }}</span>
          <span class="tl__label">{{ it.label }}</span>
          <span class="tl__pct">{{ Math.round(it.pct) }}%</span>
        </div>
        <div class="tl__track">
          <span class="tl__fill" :style="{ width: it.pct + '%' }" />
        </div>
      </div>
    </div>
  </HudModule>
</template>

<style scoped>
.tl {
  display: flex;
  flex-direction: column;
  gap: 11px;
}
.tl__head {
  display: flex;
  align-items: baseline;
  gap: 8px;
  margin-bottom: 5px;
  font-size: 0.78rem;
  color: var(--text-soft);
}
.tl__code {
  font-family: var(--font-mono);
  font-size: 0.6rem;
  letter-spacing: 1px;
  color: var(--accent-a);
  width: 42px;
  flex: none;
}
.tl__label {
  min-width: 0;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.tl__pct {
  margin-left: auto;
  font-family: var(--font-mono);
  font-size: 0.68rem;
  color: var(--text-dim);
}
.tl__track {
  height: 8px;
  background: rgba(255, 255, 255, 0.09);
  /* 机甲能量格 */
  -webkit-mask: repeating-linear-gradient(90deg, #000 0 8px, transparent 8px 11px);
  mask: repeating-linear-gradient(90deg, #000 0 8px, transparent 8px 11px);
}
.tl__fill {
  display: block;
  height: 100%;
  background: linear-gradient(90deg, var(--accent-a), var(--accent-b), var(--accent-c));
  box-shadow: 0 0 12px color-mix(in srgb, var(--accent-b) 60%, transparent);
  transition: width 0.9s var(--ease-out);
}
</style>
