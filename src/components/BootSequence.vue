<script setup>
import { ref, onMounted, onUnmounted } from 'vue'
import config from '../config.js'

const emit = defineEmits(['done'])

const host = `${config.site.name}${config.site.suffix || ''}`.toUpperCase()

const LINES = [
  { t: 'header', text: `AURORA OS // COLD BOOT — ${host}` },
  { t: 'task', label: 'POWER CORE', status: 'ONLINE' },
  { t: 'task', label: 'REACTOR LINK', status: 'STABLE' },
  { t: 'task', label: 'CHRONO SYNC', status: 'OK' },
  { t: 'task', label: 'ATMOS SENSORS', status: 'OK' },
  { t: 'task', label: 'NAV SUBSYSTEM', status: 'OK' },
  { t: 'task', label: 'MEMORY BANKS', status: '4096 MB' },
  { t: 'task', label: 'SECURE UPLINK', status: 'ESTABLISHED' },
  { t: 'final', text: 'ALL SYSTEMS NOMINAL — SYSTEM READY' }
]

const visible = ref(0)
let timer = null
let finishTimer = null
let done = false

const finish = () => {
  if (done) return
  done = true
  // 直接交棒，淡出由父级 <Transition> 负责（淡出时控制台已在其下方就位）
  emit('done')
}

const skip = () => {
  clearInterval(timer)
  visible.value = LINES.length
  finish()
}

onMounted(() => {
  timer = setInterval(() => {
    visible.value += 1
    if (visible.value >= LINES.length) {
      clearInterval(timer)
      finishTimer = setTimeout(finish, 180)
    }
  }, 95)
})
onUnmounted(() => {
  clearInterval(timer)
  clearTimeout(finishTimer)
})
</script>

<template>
  <div class="boot" @click="skip">
    <div class="boot__grid" />
    <div class="boot__win">
      <div class="boot__bar">
        <span><i />SELF-CHECK</span>
        <span class="boot__skip">CLICK TO SKIP →</span>
      </div>
      <div class="boot__log">
        <template v-for="(l, i) in LINES" :key="i">
          <div v-if="i < visible" class="boot__line" :class="'boot__line--' + l.t">
            <template v-if="l.t === 'task'">
              <span class="boot__label">&gt; {{ l.label }}</span>
              <span class="boot__dots" />
              <span class="boot__status">{{ l.status }}</span>
            </template>
            <span v-else>{{ l.text }}<i v-if="l.t === 'final'" class="boot__caret" /></span>
          </div>
        </template>
      </div>
    </div>
    <div class="scan" />
  </div>
</template>

<style scoped>
.boot {
  position: fixed;
  inset: 0;
  z-index: 1000;
  display: grid;
  place-items: center;
  background: radial-gradient(130% 120% at 50% 30%, #0a0f1f, #04060e 75%);
  color: var(--text);
  cursor: pointer;
  overflow: hidden;
}
.boot__grid {
  position: absolute;
  inset: 0;
  background-image: linear-gradient(rgba(255, 255, 255, 0.03) 1px, transparent 1px),
    linear-gradient(90deg, rgba(255, 255, 255, 0.03) 1px, transparent 1px);
  background-size: 40px 40px;
  -webkit-mask: radial-gradient(120% 100% at 50% 40%, #000 30%, transparent 85%);
  mask: radial-gradient(120% 100% at 50% 40%, #000 30%, transparent 85%);
}

.boot__win {
  position: relative;
  width: min(560px, 88vw);
  font-family: var(--font-mono);
  border: 1px solid color-mix(in srgb, var(--accent-a) 30%, transparent);
  box-shadow: 0 0 40px -8px color-mix(in srgb, var(--accent-a) 45%, transparent);
  background: rgba(6, 10, 22, 0.5);
  -webkit-backdrop-filter: blur(6px);
  backdrop-filter: blur(6px);
}
.boot__bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 8px 12px;
  font-size: 0.62rem;
  letter-spacing: 1.6px;
  color: var(--accent-a);
  border-bottom: 1px solid color-mix(in srgb, var(--accent-a) 22%, transparent);
}
.boot__bar span {
  display: inline-flex;
  align-items: center;
  gap: 7px;
}
.boot__bar i {
  width: 6px;
  height: 6px;
  background: var(--accent-a);
  box-shadow: 0 0 7px var(--accent-a);
  animation: caretBlink 1s steps(1) infinite;
}
.boot__skip {
  color: var(--text-dim);
}

.boot__log {
  padding: 16px 16px 20px;
  font-size: 0.82rem;
  line-height: 1.85;
}
.boot__line {
  display: flex;
  align-items: baseline;
  animation: lineIn 0.25s var(--ease-out);
}
@keyframes lineIn {
  from {
    opacity: 0;
    transform: translateX(-8px);
  }
}
.boot__line--header {
  color: var(--text-soft);
  margin-bottom: 8px;
  letter-spacing: 1px;
}
.boot__line--final {
  margin-top: 8px;
  color: #fff;
  font-weight: 700;
  letter-spacing: 1px;
}
.boot__label {
  color: var(--text-soft);
}
.boot__dots {
  flex: 1;
  margin: 0 8px;
  border-bottom: 1px dotted rgba(255, 255, 255, 0.22);
  transform: translateY(-3px);
}
.boot__status {
  color: var(--accent-a);
  text-shadow: 0 0 8px color-mix(in srgb, var(--accent-a) 60%, transparent);
}
.boot__caret {
  display: inline-block;
  width: 8px;
  height: 1em;
  margin-left: 6px;
  vertical-align: text-bottom;
  background: var(--accent-c);
  box-shadow: 0 0 8px var(--accent-c);
  animation: caretBlink 0.7s steps(1) infinite;
}
@keyframes caretBlink {
  50% {
    opacity: 0.25;
  }
}

.scan {
  position: absolute;
  inset: 0;
  pointer-events: none;
  background: repeating-linear-gradient(0deg, rgba(255, 255, 255, 0.025) 0 1px, transparent 1px 3px);
}

@media (prefers-reduced-motion: reduce) {
  .boot__bar i,
  .boot__caret {
    animation: none;
  }
}
</style>
