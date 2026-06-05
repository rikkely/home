<script setup>
import { ref } from 'vue'
import config from './config.js'
import { useSystemStats } from './composables/useSystemStats.js'
import { useTheme } from './composables/useTheme.js'

import LoadingScreen from './components/LoadingScreen.vue'
import BootSequence from './components/BootSequence.vue'
import BackgroundScene from './components/BackgroundScene.vue'
import SiteIdentity from './components/SiteIdentity.vue'
import ClockCard from './components/ClockCard.vue'
import WeatherCard from './components/WeatherCard.vue'
import QuoteCard from './components/QuoteCard.vue'
import TimeCapsule from './components/TimeCapsule.vue'
import NavPanel from './components/NavPanel.vue'
import DataStream from './components/DataStream.vue'
import SysMonitor from './components/SysMonitor.vue'

// 主题色（青/红/绿），立即应用
const { active, palettes, setTheme, initTheme } = useTheme()
initTheme()

document.title = `${config.site.name}${config.site.suffix || ''} · 主页`

// 用头像作为浏览器标签页图标
const fav = document.querySelector("link[rel='icon']") || document.createElement('link')
fav.setAttribute('rel', 'icon')
fav.removeAttribute('type')
fav.setAttribute('href', config.site.avatar)
if (!fav.parentNode) document.head.appendChild(fav)

const { fps, uptime } = useSystemStats()

// 阶段：加载页 → 开机自检 → 控制台
// loaderMounted 在 boot 淡入覆盖之后才卸载，保证全程无「只剩背景」的空档
const stage = ref('loading')
const loaderMounted = ref(true)
const onLoaderDone = () => {
  stage.value = 'boot'
  // 自检画面在 ~0.45s 内淡入覆盖加载页后，再卸载加载页（确定性，不依赖过渡事件）
  setTimeout(() => { loaderMounted.value = false }, 520)
}
const onBootDone = () => { stage.value = 'ready' }

const f = config.footer || {}
const year = new Date().getFullYear()
</script>

<template>
  <BackgroundScene />

  <!-- 加载页保持不透明，直到自检画面在它上方淡入覆盖后再卸载 -->
  <LoadingScreen v-if="loaderMounted" @done="onLoaderDone" />
  <Transition name="boot">
    <BootSequence v-if="stage === 'boot'" @done="onBootDone" />
  </Transition>

  <template v-if="stage === 'ready'">
    <!-- 全局座舱框 -->
    <div class="frame" aria-hidden="true">
      <span class="frame__b frame__b--tl" />
      <span class="frame__b frame__b--tr" />
      <span class="frame__b frame__b--bl" />
      <span class="frame__b frame__b--br" />
    </div>

    <main class="console">
      <div class="console__inner">
        <!-- 顶部状态条 -->
        <header class="topbar reveal" style="--delay: 0.04s">
          <span class="topbar__tag">
            <i class="topbar__diam" />AURORA<b>//</b>OS
            <span class="topbar__ver">v1.0</span>
          </span>

          <span class="topbar__status">
            <span class="eq"><i /><i /><i /><i /><i /></span>
            <span class="topbar__stat">FPS<b>{{ fps }}</b></span>
            <span class="topbar__sep">/</span>
            <span class="topbar__stat">UPTIME<b>{{ uptime }}</b></span>
          </span>

          <span class="topbar__right">
            <span class="theme">
              <button
                v-for="(p, key) in palettes"
                :key="key"
                class="theme__sw"
                :class="{ 'is-on': active === key }"
                :style="{ '--sw': p.a }"
                :title="p.label"
                @click="setTheme(key)"
              />
            </span>
            <span class="topbar__link"><i class="topbar__live" />ONLINE</span>
          </span>
        </header>

        <!-- HUD 主区 -->
        <section class="hud">
          <SiteIdentity class="z-core" :delay="0.08" />
          <ClockCard class="z-chrono" :delay="0.16" />
          <WeatherCard class="z-atmos" :delay="0.22" />
          <QuoteCard class="z-trans" :delay="0.28" />
          <TimeCapsule class="z-load" :delay="0.34" />
          <NavPanel class="z-nav" :delay="0.2" />
        </section>

        <!-- 底部条 -->
        <footer class="botbar reveal" style="--delay: 0.5s">
          <span class="botbar__seg">© {{ f.startYear }}–{{ year }} {{ f.author }}</span>
          <span class="botbar__seg botbar__scan">▚ SCANNING SECTOR…</span>
          <span class="botbar__seg" v-if="f.icp">
            <a :href="f.icpLink" target="_blank" rel="noopener">{{ f.icp }}</a>
          </span>
          <span class="botbar__seg" v-else>BUILT WITH VUE · VITE</span>
        </footer>
      </div>
    </main>

    <!-- 右下角系统监视器（雷达 + 负载） -->
    <SysMonitor />

    <!-- 全页扫描线（极淡） -->
    <div class="scanlines" aria-hidden="true"><span class="scanlines__sweep" /></div>
  </template>

  <!-- 导航点击：数据流过场 -->
  <DataStream />
</template>

<style scoped>
.console {
  position: fixed;
  inset: 0;
  overflow-y: auto;
  overflow-x: hidden;
  display: flex;
  flex-direction: column;
}
.console__inner {
  width: min(1180px, 94vw);
  margin: auto;
  padding: 4.4vh 0 2rem;
}

/* ---------- top / bottom HUD strips ---------- */
.topbar,
.botbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  font-family: var(--font-mono);
  font-size: 0.66rem;
  letter-spacing: 1.6px;
  text-transform: uppercase;
  color: var(--text-dim);
}
.topbar {
  margin-bottom: 16px;
  padding: 0 4px 12px;
  border-bottom: 1px solid rgba(255, 255, 255, 0.08);
}
.botbar {
  margin-top: 18px;
  padding: 12px 4px 0;
  border-top: 1px solid rgba(255, 255, 255, 0.08);
  flex-wrap: wrap;
}
.topbar__tag {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  color: var(--text-soft);
}
.topbar__tag b {
  color: var(--accent-b);
}
.topbar__ver {
  color: var(--text-dim);
}
.topbar__diam {
  width: 7px;
  height: 7px;
  background: var(--accent-c);
  box-shadow: 0 0 8px var(--accent-c);
  transform: rotate(45deg);
}
.topbar__status {
  display: inline-flex;
  align-items: center;
  gap: 8px;
}
.topbar__link {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  color: var(--accent-a);
}
.topbar__live {
  width: 6px;
  height: 6px;
  border-radius: 50%;
  background: var(--accent-a);
  box-shadow: 0 0 8px var(--accent-a);
  animation: pulse 1.6s ease-in-out infinite;
}
@keyframes pulse {
  50% {
    opacity: 0.3;
  }
}

.topbar__stat {
  display: inline-flex;
  align-items: center;
  gap: 6px;
}
.topbar__stat b {
  color: var(--accent-a);
  font-weight: 700;
  min-width: 26px;
}
.topbar__sep {
  opacity: 0.4;
}

.topbar__right {
  display: inline-flex;
  align-items: center;
  gap: 14px;
}
/* 主题切换 */
.theme {
  display: inline-flex;
  align-items: center;
  gap: 7px;
}
.theme__sw {
  width: 13px;
  height: 13px;
  padding: 0;
  border-radius: 50%;
  background: var(--sw);
  box-shadow: 0 0 7px var(--sw);
  outline: 1.5px solid transparent;
  outline-offset: 2px;
  opacity: 0.5;
  transform: rotate(45deg);
  border-radius: 3px;
  transition: opacity 0.25s, outline-color 0.25s, transform 0.25s var(--ease-out);
}
.theme__sw:hover {
  opacity: 0.85;
  transform: rotate(45deg) scale(1.12);
}
.theme__sw.is-on {
  opacity: 1;
  outline-color: var(--sw);
}

/* mini equalizer */
.eq {
  display: inline-flex;
  align-items: flex-end;
  gap: 2px;
  height: 12px;
}
.eq i {
  width: 2.5px;
  background: var(--accent-a);
  border-radius: 1px;
  animation: eq 1s ease-in-out infinite;
}
.eq i:nth-child(1) { height: 40%; animation-delay: -0.1s; }
.eq i:nth-child(2) { height: 75%; animation-delay: -0.4s; }
.eq i:nth-child(3) { height: 100%; animation-delay: -0.7s; }
.eq i:nth-child(4) { height: 60%; animation-delay: -0.2s; }
.eq i:nth-child(5) { height: 85%; animation-delay: -0.5s; }
@keyframes eq {
  50% {
    transform: scaleY(0.35);
  }
}
.botbar__scan {
  color: var(--accent-b);
  opacity: 0.8;
}
.botbar a:hover {
  color: var(--text-soft);
}

/* ---------- HUD grid ---------- */
.hud {
  display: grid;
  gap: 16px;
  grid-template-columns: 1.05fr 1.2fr 0.95fr;
  grid-template-areas:
    'core   chrono  nav'
    'core   atmos   nav'
    'trans  trans   nav'
    'load   load    nav';
}
.z-core {
  grid-area: core;
}
.z-chrono {
  grid-area: chrono;
}
.z-atmos {
  grid-area: atmos;
}
.z-trans {
  grid-area: trans;
}
.z-load {
  grid-area: load;
}
.z-nav {
  grid-area: nav;
}

/* ---------- cockpit frame ---------- */
.frame {
  position: fixed;
  inset: 12px;
  z-index: 40;
  pointer-events: none;
  border: 1px solid rgba(255, 255, 255, 0.06);
}
.frame__b {
  position: absolute;
  width: 26px;
  height: 26px;
  border: 0 solid var(--accent-a);
  filter: drop-shadow(0 0 5px color-mix(in srgb, var(--accent-a) 55%, transparent));
}
.frame__b--tl { top: -1px; left: -1px; border-top-width: 2px; border-left-width: 2px; }
.frame__b--tr { top: -1px; right: -1px; border-top-width: 2px; border-right-width: 2px; }
.frame__b--bl { bottom: -1px; left: -1px; border-bottom-width: 2px; border-left-width: 2px; }
.frame__b--br { bottom: -1px; right: -1px; border-bottom-width: 2px; border-right-width: 2px; }

/* ---------- scanlines (very faint) ---------- */
.scanlines {
  position: fixed;
  inset: 0;
  z-index: 60;
  pointer-events: none;
  background: repeating-linear-gradient(
    0deg,
    rgba(255, 255, 255, 0.02) 0 1px,
    transparent 1px 3px
  );
  overflow: hidden;
}
.scanlines__sweep {
  position: absolute;
  left: 0;
  right: 0;
  height: 28%;
  top: -28%;
  background: linear-gradient(
    180deg,
    transparent,
    color-mix(in srgb, var(--accent-a) 6%, transparent) 60%,
    color-mix(in srgb, var(--accent-a) 9%, transparent)
  );
  animation: sweepDown 7s linear infinite;
}
@keyframes sweepDown {
  to {
    transform: translateY(460%);
  }
}

/* ---------- responsive ---------- */
@media (max-width: 900px) {
  .hud {
    grid-template-columns: 1fr 1fr;
    grid-template-areas:
      'core   core'
      'chrono atmos'
      'trans  trans'
      'load   load'
      'nav    nav';
  }
}
@media (max-width: 600px) {
  .console__inner {
    width: 92vw;
  }
  .topbar__status {
    display: none;
  }
  .hud {
    grid-template-columns: 1fr;
    grid-template-areas:
      'core'
      'chrono'
      'atmos'
      'trans'
      'load'
      'nav';
  }
}

/* 自检画面淡入（覆盖在加载页之上）/ 淡出（露出控制台） */
.boot-enter-active {
  transition: opacity 0.45s var(--ease-out);
}
.boot-leave-active {
  transition: opacity 0.6s var(--ease-out);
}
.boot-enter-from,
.boot-leave-to {
  opacity: 0;
}

@media (prefers-reduced-motion: reduce) {
  .scanlines__sweep,
  .eq i {
    animation: none;
  }
}
</style>
