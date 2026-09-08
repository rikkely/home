<script setup>
import { ref, computed } from 'vue'
import config from '../config.js'
import { socialIcons } from '../assets/media.js'
import IconBase from './IconBase.vue'
import { usePointer } from '../composables/usePointer.js'
import { launchLink, isInternalUrl } from '../composables/useLink.js'

defineProps({ delay: { type: Number, default: 0 } })
const links = config.links || []

const hot = ref(false)

const { x, y } = usePointer()
const panelStyle = computed(() => {
  const lift = hot.value ? ' translateY(-12px) translateZ(40px) scale(1.025)' : ''
  return {
    transform: `perspective(1300px) rotateY(${-15 + x.value * 5}deg) rotateX(${
      3 - y.value * 4
    }deg)${lift}`
  }
})

const hasImg = (name) => !!socialIcons[name]
</script>

<template>
  <div class="nav reveal" :style="{ '--delay': delay + 's' }">
    <div class="nav__stage">
      <div
        class="nav__panel"
        :class="{ 'is-hot': hot }"
        :style="panelStyle"
        @mouseenter="hot = true"
        @mouseleave="hot = false"
      >
        <!-- 向边缘溶解的弱背衬（非卡片） -->
        <div class="nav__scrim" />
        <span class="nav__br nav__br--tl" />
        <span class="nav__br nav__br--tr" />
        <span class="nav__br nav__br--bl" />
        <span class="nav__br nav__br--br" />

        <div class="nav__head">
          <span class="nav__code"><i />NAV.SYS</span>
          <span class="nav__count">{{ links.length }} LINKS</span>
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
            <span class="nav__icon">
              <img v-if="hasImg(l.icon)" :src="socialIcons[l.icon]" :alt="l.name" />
              <IconBase v-else :name="l.icon" :size="18" />
            </span>
            <span class="nav__text">
              <span class="nav__name">{{ l.name }}</span>
              <span class="nav__desc">{{ l.desc }}</span>
            </span>
            <span class="nav__go"><IconBase name="arrow-up-right" :size="15" /></span>
          </a>
        </div>

        <div class="nav__foot">
          <span class="nav__sig"><i />SIGNAL</span>
          <span class="nav__wave"><i /><i /><i /><i /><i /><i /><i /></span>
          <span class="nav__sigval">STABLE</span>
        </div>
      </div>
      <div class="nav__glow" />
    </div>
  </div>
</template>

<style scoped>
.nav {
  height: 100%;
  min-width: 0;
}
.nav__stage {
  position: relative;
  height: 100%;
  display: flex;
  align-items: stretch;
  justify-content: center;
}

.nav__panel {
  position: relative;
  width: 100%;
  padding: 18px 16px;
  display: flex;
  flex-direction: column;
  gap: 6px;
  /* 无实心填充、无包边，仅靠双色霓虹辉光 + 取景括号成形 */
  box-shadow: -14px 22px 60px -18px color-mix(in srgb, var(--accent-a) 52%, transparent),
    14px -12px 60px -18px color-mix(in srgb, var(--accent-c) 48%, transparent),
    0 30px 60px -28px rgba(0, 0, 0, 0.55);
  transition: transform 0.45s var(--ease-out), box-shadow 0.45s var(--ease-out),
    filter 0.45s var(--ease-out);
}
.nav__scrim {
  position: absolute;
  inset: 0;
  pointer-events: none;
  border-radius: 8px;
  background: linear-gradient(155deg, rgba(8, 12, 26, 0.5), rgba(8, 12, 26, 0.16));
  -webkit-backdrop-filter: blur(11px) saturate(150%);
  backdrop-filter: blur(11px) saturate(150%);
  -webkit-mask: radial-gradient(150% 150% at 50% 38%, #000 72%, transparent 100%);
  mask: radial-gradient(150% 150% at 50% 38%, #000 72%, transparent 100%);
}
.nav__panel.is-hot {
  filter: brightness(1.1) saturate(1.12);
  box-shadow: -20px 30px 80px -16px color-mix(in srgb, var(--accent-a) 72%, transparent),
    20px -16px 80px -16px color-mix(in srgb, var(--accent-c) 66%, transparent),
    0 0 30px -4px color-mix(in srgb, var(--accent-b) 55%, transparent),
    0 40px 70px -24px rgba(0, 0, 0, 0.7);
}

/* 取景括号 */
.nav__br {
  position: absolute;
  width: 16px;
  height: 16px;
  z-index: 3;
  pointer-events: none;
  border: 0 solid color-mix(in srgb, var(--accent-a) 60%, transparent);
  transition: width 0.45s var(--ease-out), height 0.45s var(--ease-out), border-color 0.45s;
}
.nav__br--tl { top: -2px; left: -2px; border-top-width: 2px; border-left-width: 2px; }
.nav__br--tr { top: -2px; right: -2px; border-top-width: 2px; border-right-width: 2px; }
.nav__br--bl { bottom: -2px; left: -2px; border-bottom-width: 2px; border-left-width: 2px; }
.nav__br--br { bottom: -2px; right: -2px; border-bottom-width: 2px; border-right-width: 2px; }
.nav__panel.is-hot .nav__br {
  width: 22px;
  height: 22px;
  border-color: var(--accent-a);
}

.nav__head {
  position: relative;
  z-index: 2;
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 8px 10px;
  margin-bottom: 4px;
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
  background: var(--accent-a);
  box-shadow: 0 0 7px var(--accent-a);
  animation: blink 1.7s ease-in-out infinite;
}
@keyframes blink {
  50% {
    opacity: 0.3;
  }
}

/* 让列表填满整列，把空旷的右侧撑起来 */
.nav__list {
  position: relative;
  z-index: 2;
  flex: 1;
  min-height: 0;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  gap: 4px;
}

.nav__item {
  position: relative;
  z-index: 2;
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 11px 12px;
  border-radius: 9px;
  overflow: hidden;
  transition: background 0.35s var(--ease-out), transform 0.35s var(--ease-out);
  animation: itemIn 0.6s var(--ease-out) backwards;
  animation-delay: calc(var(--delay, 0s) + var(--i) * 0.07s);
}
@keyframes itemIn {
  from {
    opacity: 0;
    transform: translateX(14px);
  }
}
.nav__item:hover {
  background: rgba(255, 255, 255, 0.07);
  transform: translateX(4px);
}
/* 整行 <a> 作为唯一点击目标，避免 3D 叠层下子元素拦截/错位点击 */
.nav__item > * {
  pointer-events: none;
}
.nav__bar {
  position: absolute;
  left: 0;
  top: 18%;
  bottom: 18%;
  width: 2px;
  border-radius: 2px;
  background: linear-gradient(var(--accent-a), var(--accent-c));
  transform: scaleY(0);
  transform-origin: center;
  transition: transform 0.35s var(--ease-out);
}
.nav__item:hover .nav__bar {
  transform: scaleY(1);
}

.nav__icon {
  display: grid;
  place-items: center;
  width: 34px;
  height: 34px;
  flex: none;
  border-radius: 8px;
  color: var(--accent-a);
  background: color-mix(in srgb, var(--accent-a) 10%, transparent);
  box-shadow: inset 0 0 0 1px color-mix(in srgb, var(--accent-a) 20%, transparent),
    0 0 10px -2px color-mix(in srgb, var(--accent-a) 50%, transparent);
  transition: box-shadow 0.35s, transform 0.35s var(--ease-out);
}
.nav__icon img {
  width: 18px;
  height: 18px;
  object-fit: contain;
}
.nav__item:hover .nav__icon {
  transform: scale(1.06);
  box-shadow: inset 0 0 0 1px color-mix(in srgb, var(--accent-b) 40%, transparent),
    0 0 16px -1px color-mix(in srgb, var(--accent-b) 70%, transparent);
}

.nav__text {
  display: flex;
  flex-direction: column;
  min-width: 0;
}
.nav__name {
  font-size: 0.95rem;
  font-weight: 600;
}
.nav__desc {
  font-size: 0.7rem;
  color: var(--text-dim);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}
.nav__go {
  margin-left: auto;
  color: var(--text-dim);
  opacity: 0;
  transform: translate(-5px, 5px);
  transition: opacity 0.3s, transform 0.3s var(--ease-out);
}
.nav__item:hover .nav__go {
  opacity: 1;
  transform: translate(0, 0);
  color: var(--accent-a);
}

/* 底部信号读数 */
.nav__foot {
  position: relative;
  z-index: 2;
  display: flex;
  align-items: center;
  gap: 10px;
  margin-top: 8px;
  padding: 10px 8px 2px;
  border-top: 1px solid rgba(255, 255, 255, 0.08);
  font-family: var(--font-mono);
  font-size: 0.6rem;
  letter-spacing: 1.4px;
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
  background: var(--accent-a);
  box-shadow: 0 0 7px var(--accent-a);
  animation: blink 1.7s ease-in-out infinite;
}
.nav__wave {
  flex: 1;
  display: flex;
  align-items: flex-end;
  justify-content: center;
  gap: 3px;
  height: 16px;
}
.nav__wave i {
  width: 3px;
  border-radius: 1px;
  background: linear-gradient(var(--accent-a), var(--accent-c));
  animation: navwave 1.1s ease-in-out infinite;
}
.nav__wave i:nth-child(1) { height: 35%; animation-delay: -0.1s; }
.nav__wave i:nth-child(2) { height: 65%; animation-delay: -0.5s; }
.nav__wave i:nth-child(3) { height: 90%; animation-delay: -0.2s; }
.nav__wave i:nth-child(4) { height: 100%; animation-delay: -0.7s; }
.nav__wave i:nth-child(5) { height: 75%; animation-delay: -0.3s; }
.nav__wave i:nth-child(6) { height: 50%; animation-delay: -0.6s; }
.nav__wave i:nth-child(7) { height: 30%; animation-delay: -0.15s; }
@keyframes navwave {
  50% {
    transform: scaleY(0.4);
  }
}
.nav__sigval {
  color: var(--accent-a);
}

.nav__glow {
  position: absolute;
  pointer-events: none;
  left: 8%;
  right: 8%;
  bottom: -6%;
  height: 22%;
  border-radius: 50%;
  background: radial-gradient(ellipse at center, color-mix(in srgb, var(--accent-b) 45%, transparent), transparent 70%);
  filter: blur(18px);
  transform: translateZ(-40px);
}

@media (max-width: 900px) {
  .nav__panel {
    transform: none !important;
  }
}
</style>
