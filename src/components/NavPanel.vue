<script setup>
import { ref, computed, onUnmounted } from 'vue'
import config from '../config.js'
import { socialIcons } from '../assets/media.js'
import IconBase from './IconBase.vue'
import { launchLink, isInternalUrl } from '../composables/useLink.js'
import { triggerNextBackground } from './BackgroundScene.vue'

defineProps({ delay: { type: Number, default: 0 } })
const emit = defineEmits(['open-cmd'])

const links = config.links || []
const panelRef = ref(null)
const mx = ref('50%')
const my = ref('50%')
const spot = ref(0)
const tilt = ref({ rx: 0, ry: 0 })

let raf = 0
let pending = null

function flush() {
  raf = 0
  if (!pending) return
  mx.value = pending.mx
  my.value = pending.my
  tilt.value = pending.tilt
  spot.value = 1
}

function onMove(e) {
  const el = panelRef.value
  if (!el) return
  const r = el.getBoundingClientRect()
  const px = (e.clientX - r.left) / r.width
  const py = (e.clientY - r.top) / r.height
  pending = {
    mx: `${(px * 100).toFixed(1)}%`,
    my: `${(py * 100).toFixed(1)}%`,
    tilt: {
      rx: Number(((0.5 - py) * 3.2).toFixed(2)),
      ry: Number(((px - 0.5) * 3.2).toFixed(2))
    }
  }
  if (!raf) raf = requestAnimationFrame(flush)
}

function onLeave() {
  if (raf) cancelAnimationFrame(raf)
  raf = 0
  pending = null
  spot.value = 0
  tilt.value = { rx: 0, ry: 0 }
}

onUnmounted(() => {
  if (raf) cancelAnimationFrame(raf)
})

const panelStyle = computed(() => ({
  '--mx': mx.value,
  '--my': my.value,
  '--spot': spot.value,
  transform: spot.value
    ? `perspective(1200px) rotateX(${tilt.value.rx}deg) rotateY(${tilt.value.ry}deg)`
    : 'perspective(1200px) rotateX(0deg) rotateY(0deg)'
}))

const hasImg = (name) => !!socialIcons[name]
const routeTag = (url) => url.replace(/^\/|\/$/g, '').toUpperCase() || 'LINK'
</script>

<template>
  <div class="nav reveal" :style="{ '--delay': delay + 's' }">
    <div
      ref="panelRef"
      class="nav__panel"
      :class="{ 'is-hot': spot > 0 }"
      :style="panelStyle"
      @mousemove="onMove"
      @mouseleave="onLeave"
    >
      <div class="nav__spot" aria-hidden="true" />
      <div class="nav__scan" aria-hidden="true" />
      <span class="nav__br nav__br--tl" aria-hidden="true" />
      <span class="nav__br nav__br--br" aria-hidden="true" />

      <div class="nav__head">
        <span class="nav__code"><i />NAV.SYS</span>
        <button class="nav__cmd" title="打开命令面板 (Ctrl+K)" @click="emit('open-cmd')">
          <IconBase name="command" :size="11" />
          <span>K</span>
        </button>
      </div>

      <div class="nav__list">
        <a
          v-for="(l, i) in links"
          :key="l.name"
          class="nav__item"
          :style="{ '--i': i }"
          :href="l.url"
          :target="isInternalUrl(l.url) ? '_self' : '_blank'"
          rel="noopener"
          @click="launchLink(l.url, l.name, $event)"
        >
          <span class="nav__bar" />
          <span class="nav__idx tabular">{{ String(i + 1).padStart(2, '0') }}</span>
          <span class="nav__icon">
            <img v-if="hasImg(l.icon)" :src="socialIcons[l.icon]" :alt="l.name" />
            <IconBase v-else :name="l.icon" :size="17" />
          </span>
          <span class="nav__text">
            <span class="nav__top">
              <span class="nav__name">{{ l.name }}</span>
              <span class="nav__route">/{{ routeTag(l.url).toLowerCase() }}</span>
            </span>
            <span class="nav__desc">{{ l.desc }}</span>
          </span>
          <span class="nav__kbd" aria-hidden="true">{{ i + 1 }}</span>
          <span class="nav__go"><IconBase name="arrow-up-right" :size="14" /></span>
        </a>
      </div>

      <div class="nav__foot">
        <span class="nav__sig"><i />SIGNAL</span>
        <span class="nav__wave" aria-hidden="true"><i /><i /><i /><i /><i /></span>
        <button class="nav__bgbtn" title="切换背景壁纸" @click="triggerNextBackground">
          <IconBase name="image" :size="12" />
          <span>换壁纸</span>
        </button>
      </div>
    </div>
  </div>
</template>

<style scoped>
.nav {
  height: 100%;
  min-width: 0;
}

.nav__panel {
  position: relative;
  height: 100%;
  padding: 18px 16px 15px;
  display: flex;
  flex-direction: column;
  gap: 8px;
  border-radius: 20px;
  background: linear-gradient(155deg, rgba(10, 15, 32, 0.72), rgba(7, 11, 22, 0.48));
  border: 1px solid rgba(255, 255, 255, 0.095);
  box-shadow: 0 20px 50px -22px rgba(0, 0, 0, 0.72),
    inset 0 1px 0 rgba(255, 255, 255, 0.14);
  -webkit-backdrop-filter: blur(22px) saturate(170%);
  backdrop-filter: blur(22px) saturate(170%);
  overflow: hidden;
  transition: transform 0.45s var(--ease-out), border-color 0.4s var(--ease-out),
    box-shadow 0.4s var(--ease-out);
}
.nav__panel.is-hot {
  border-color: color-mix(in srgb, var(--accent-a) 30%, rgba(255, 255, 255, 0.14));
  box-shadow: 0 26px 60px -20px rgba(0, 0, 0, 0.85),
    0 0 34px -14px color-mix(in srgb, var(--accent-a) 40%, transparent),
    inset 0 1px 0 rgba(255, 255, 255, 0.2);
}

.nav__spot {
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
.nav__scan {
  position: absolute;
  inset: 0;
  pointer-events: none;
  opacity: 0.3;
  background: repeating-linear-gradient(
    0deg,
    rgba(255, 255, 255, 0.025) 0 1px,
    transparent 1px 4px
  );
}

/* 光学角标 */
.nav__br {
  position: absolute;
  width: 10px;
  height: 10px;
  z-index: 3;
  pointer-events: none;
  border: 0 solid color-mix(in srgb, var(--accent-a) 50%, transparent);
  transition: width 0.35s var(--ease-out), height 0.35s var(--ease-out), border-color 0.35s;
}
.nav__br--tl {
  top: 7px;
  left: 7px;
  border-top-width: 1.5px;
  border-left-width: 1.5px;
  border-top-left-radius: 4px;
}
.nav__br--br {
  bottom: 7px;
  right: 7px;
  border-bottom-width: 1.5px;
  border-right-width: 1.5px;
  border-bottom-right-radius: 4px;
}
.nav__panel.is-hot .nav__br {
  width: 14px;
  height: 14px;
  border-color: var(--accent-a);
}

.nav__head {
  position: relative;
  z-index: 2;
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 6px 10px;
  border-bottom: 1px solid rgba(255, 255, 255, 0.08);
  font-family: var(--font-mono);
  font-size: 0.62rem;
  letter-spacing: 1.6px;
  text-transform: uppercase;
  color: var(--text-dim);
}
.nav__code {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  color: var(--accent-a);
}
.nav__code i {
  width: 5px;
  height: 5px;
  border-radius: 1px;
  background: var(--accent-a);
  box-shadow: 0 0 7px var(--accent-a);
  animation: blink 1.8s ease-in-out infinite;
}
@keyframes blink {
  50% {
    opacity: 0.32;
  }
}

.nav__cmd {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  padding: 3px 8px;
  border-radius: 6px;
  font-size: 0.6rem;
  color: var(--text-soft);
  background: rgba(255, 255, 255, 0.05);
  border: 1px solid rgba(255, 255, 255, 0.1);
  transition: color 0.25s, border-color 0.25s, background 0.25s;
}
.nav__cmd:hover {
  color: var(--accent-a);
  border-color: color-mix(in srgb, var(--accent-a) 45%, transparent);
  background: color-mix(in srgb, var(--accent-a) 10%, transparent);
}

.nav__list {
  position: relative;
  z-index: 2;
  flex: 1;
  min-height: 0;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  gap: 5px;
}

.nav__item {
  position: relative;
  z-index: 2;
  display: flex;
  align-items: center;
  gap: 11px;
  padding: 10px 10px;
  border-radius: 12px;
  border: 1px solid transparent;
  overflow: hidden;
  transition: background 0.3s var(--ease-out), border-color 0.3s,
    transform 0.3s var(--ease-out);
  animation: itemIn 0.55s var(--ease-out) backwards;
  animation-delay: calc(var(--delay, 0s) + var(--i) * 0.06s);
}
@keyframes itemIn {
  from {
    opacity: 0;
    transform: translateX(12px);
  }
}
.nav__item:hover {
  background: rgba(255, 255, 255, 0.065);
  border-color: color-mix(in srgb, var(--accent-a) 22%, rgba(255, 255, 255, 0.08));
  transform: translateX(3px);
}
.nav__item > * {
  pointer-events: none;
}
.nav__bar {
  position: absolute;
  left: 0;
  top: 20%;
  bottom: 20%;
  width: 2px;
  border-radius: 2px;
  background: linear-gradient(var(--accent-a), var(--accent-c));
  transform: scaleY(0);
  transform-origin: center;
  transition: transform 0.3s var(--ease-out);
}
.nav__item:hover .nav__bar {
  transform: scaleY(1);
}

.nav__idx {
  font-family: var(--font-mono);
  font-size: 0.58rem;
  color: var(--text-dim);
  width: 16px;
  flex: none;
}
.nav__item:hover .nav__idx {
  color: var(--accent-a);
}

.nav__icon {
  display: grid;
  place-items: center;
  width: 34px;
  height: 34px;
  flex: none;
  border-radius: 10px;
  color: var(--accent-a);
  background: color-mix(in srgb, var(--accent-a) 11%, rgba(255, 255, 255, 0.03));
  border: 1px solid color-mix(in srgb, var(--accent-a) 22%, transparent);
  transition: border-color 0.3s, box-shadow 0.3s, transform 0.3s var(--ease-out);
}
.nav__icon img {
  width: 17px;
  height: 17px;
  object-fit: contain;
}
.nav__item:hover .nav__icon {
  transform: scale(1.05);
  border-color: color-mix(in srgb, var(--accent-a) 55%, transparent);
  box-shadow: 0 0 14px -2px color-mix(in srgb, var(--accent-a) 55%, transparent);
}

.nav__text {
  display: flex;
  flex-direction: column;
  gap: 2px;
  min-width: 0;
  flex: 1;
}
.nav__top {
  display: flex;
  align-items: baseline;
  gap: 7px;
}
.nav__name {
  font-size: 0.94rem;
  font-weight: 600;
  color: var(--text);
}
.nav__route {
  font-family: var(--font-mono);
  font-size: 0.58rem;
  color: var(--text-dim);
  opacity: 0.8;
}
.nav__desc {
  font-size: 0.7rem;
  color: var(--text-dim);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.nav__kbd {
  font-family: var(--font-mono);
  font-size: 0.56rem;
  padding: 2px 6px;
  border-radius: 5px;
  color: var(--text-dim);
  background: rgba(255, 255, 255, 0.04);
  border: 1px solid rgba(255, 255, 255, 0.08);
  transition: opacity 0.25s;
}
.nav__go {
  color: var(--accent-a);
  opacity: 0;
  width: 0;
  overflow: hidden;
  transform: translate(-4px, 4px);
  transition: opacity 0.25s, transform 0.25s var(--ease-out), width 0.25s;
}
.nav__item:hover .nav__kbd {
  display: none;
}
.nav__item:hover .nav__go {
  opacity: 1;
  width: 14px;
  transform: translate(0, 0);
}

/* 底部状态 */
.nav__foot {
  position: relative;
  z-index: 2;
  display: flex;
  align-items: center;
  gap: 10px;
  margin-top: 4px;
  padding: 10px 6px 2px;
  border-top: 1px solid rgba(255, 255, 255, 0.08);
  font-family: var(--font-mono);
  font-size: 0.6rem;
  letter-spacing: 1.2px;
  color: var(--text-dim);
}
.nav__sig {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  color: var(--accent-a);
}
.nav__sig i {
  width: 5px;
  height: 5px;
  border-radius: 50%;
  background: var(--accent-a);
  box-shadow: 0 0 7px var(--accent-a);
  animation: blink 1.8s ease-in-out infinite;
}
.nav__wave {
  flex: 1;
  display: flex;
  align-items: flex-end;
  justify-content: center;
  gap: 3px;
  height: 14px;
}
.nav__wave i {
  width: 2.5px;
  border-radius: 1px;
  background: linear-gradient(var(--accent-a), var(--accent-c));
  animation: navwave 1.1s ease-in-out infinite;
}
.nav__wave i:nth-child(1) { height: 40%; animation-delay: -0.1s; }
.nav__wave i:nth-child(2) { height: 80%; animation-delay: -0.5s; }
.nav__wave i:nth-child(3) { height: 100%; animation-delay: -0.2s; }
.nav__wave i:nth-child(4) { height: 65%; animation-delay: -0.7s; }
.nav__wave i:nth-child(5) { height: 35%; animation-delay: -0.3s; }
@keyframes navwave {
  50% {
    transform: scaleY(0.35);
  }
}

.nav__bgbtn {
  display: inline-flex;
  align-items: center;
  gap: 5px;
  padding: 4px 9px;
  border-radius: 7px;
  font-family: var(--font-sans);
  font-size: 0.66rem;
  letter-spacing: 0.4px;
  color: var(--text-soft);
  background: rgba(255, 255, 255, 0.05);
  border: 1px solid rgba(255, 255, 255, 0.09);
  transition: color 0.25s, border-color 0.25s, background 0.25s;
}
.nav__bgbtn:hover {
  color: var(--accent-a);
  border-color: color-mix(in srgb, var(--accent-a) 40%, transparent);
  background: color-mix(in srgb, var(--accent-a) 10%, transparent);
}

@media (max-width: 900px) {
  .nav__panel {
    transform: none !important;
  }
  .nav__kbd {
    display: none;
  }
}
</style>
