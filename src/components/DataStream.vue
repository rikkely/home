<script setup>
import { ref, watch } from 'vue'
import { linking } from '../composables/useLink.js'

const CHARS = 'アイウエオカキクケコサシスセソタチツテト0123456789ABCDEF<>/'
const cols = ref([])

function build() {
  const n = Math.min(26, Math.floor(window.innerWidth / 34)) || 14
  cols.value = Array.from({ length: n }, (_, i) => {
    const len = 16 + Math.floor(Math.random() * 18)
    let s = ''
    for (let k = 0; k < len; k++) s += CHARS[Math.floor(Math.random() * CHARS.length)] + '\n'
    return {
      text: s,
      left: (i / n) * 100 + Math.random() * 1.5,
      dur: (0.6 + Math.random() * 0.7).toFixed(2),
      delay: (-Math.random() * 0.8).toFixed(2),
      dim: Math.random() < 0.5
    }
  })
}

watch(linking, (v) => {
  if (v) build()
})
</script>

<template>
  <Transition name="ds">
    <div v-if="linking" class="ds" aria-hidden="true">
      <div class="ds__rain">
        <span
          v-for="(c, i) in cols"
          :key="i"
          :class="{ dim: c.dim }"
          :style="{ left: c.left + '%', animationDuration: c.dur + 's', animationDelay: c.delay + 's' }"
          >{{ c.text }}</span
        >
      </div>
      <div class="ds__center">
        <div class="ds__title">ESTABLISHING LINK</div>
        <div class="ds__target">▶ {{ linking.name }}</div>
        <div class="ds__bar"><span /></div>
        <div class="ds__hint">DECRYPTING ROUTE…</div>
      </div>
    </div>
  </Transition>
</template>

<style scoped>
.ds {
  position: fixed;
  inset: 0;
  z-index: 800;
  pointer-events: none;
  display: grid;
  place-items: center;
  background: radial-gradient(120% 120% at 50% 50%, rgba(4, 7, 16, 0.82), rgba(4, 7, 16, 0.94));
  overflow: hidden;
}

.ds__rain {
  position: absolute;
  inset: 0;
}
.ds__rain span {
  position: absolute;
  top: -45vh;
  font-family: var(--font-mono);
  font-size: 14px;
  line-height: 1.15;
  white-space: pre;
  text-align: center;
  color: var(--accent-a);
  text-shadow: 0 0 8px var(--accent-a);
  animation-name: fall;
  animation-timing-function: linear;
  animation-iteration-count: infinite;
  opacity: 0.85;
}
.ds__rain span.dim {
  color: var(--accent-c);
  text-shadow: 0 0 8px var(--accent-c);
  opacity: 0.5;
}
@keyframes fall {
  to {
    transform: translateY(170vh);
  }
}

.ds__center {
  position: relative;
  text-align: center;
  font-family: var(--font-mono);
  letter-spacing: 2px;
}
.ds__title {
  font-size: 0.8rem;
  color: var(--text-dim);
  text-transform: uppercase;
}
.ds__target {
  margin: 8px 0 14px;
  font-size: 1.5rem;
  font-weight: 700;
  color: #fff;
  text-shadow: 0 0 16px color-mix(in srgb, var(--accent-a) 80%, transparent);
}
.ds__bar {
  width: 220px;
  height: 3px;
  margin: 0 auto;
  background: rgba(255, 255, 255, 0.14);
  overflow: hidden;
}
.ds__bar span {
  display: block;
  height: 100%;
  width: 0;
  background: linear-gradient(90deg, var(--accent-a), var(--accent-b), var(--accent-c));
  box-shadow: 0 0 12px var(--accent-a);
  animation: load 0.95s var(--ease-out) forwards;
}
@keyframes load {
  to {
    width: 100%;
  }
}
.ds__hint {
  margin-top: 10px;
  font-size: 0.62rem;
  color: var(--accent-a);
  animation: caretBlink 0.5s steps(1) infinite;
}
@keyframes caretBlink {
  50% {
    opacity: 0.3;
  }
}

/* enter / leave */
.ds-enter-active,
.ds-leave-active {
  transition: opacity 0.25s ease;
}
.ds-enter-from,
.ds-leave-to {
  opacity: 0;
}
</style>
