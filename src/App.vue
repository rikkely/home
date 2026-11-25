<script setup>
import { ref, onMounted, onUnmounted } from 'vue'
import config from './config.js'
import { useBoot } from './composables/useBoot.js'
import { useSystemStats } from './composables/useSystemStats.js'
import { useTheme } from './composables/useTheme.js'
import { launchLink, isInternalUrl } from './composables/useLink.js'

import LoadingScreen from './components/LoadingScreen.vue'
import BootSequence from './components/BootSequence.vue'
import BackgroundScene, { triggerNextBackground } from './components/BackgroundScene.vue'
import SiteIdentity from './components/SiteIdentity.vue'
import ClockCard from './components/ClockCard.vue'
import WeatherCard from './components/WeatherCard.vue'
import QuoteCard from './components/QuoteCard.vue'
import TimeCapsule from './components/TimeCapsule.vue'
import NavPanel from './components/NavPanel.vue'
import DataStream from './components/DataStream.vue'
import SysMonitor from './components/SysMonitor.vue'
import CommandPalette from './components/CommandPalette.vue'
import IconBase from './components/IconBase.vue'

// 主题色，立即应用
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
const { stage, loaderMounted, onLoaderDone, onBootDone } = useBoot()
const cmdOpen = ref(false)

const f = config.footer || {}
const year = new Date().getFullYear()

function onKeydown(e) {
  if (stage.value !== 'ready') {
    if (e.key === 'Escape' || e.key === ' ') {
      e.preventDefault()
      onBootDone()
    }
    return
  }

  if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === 'k') {
    e.preventDefault()
    cmdOpen.value = !cmdOpen.value
    return
  }

  if (cmdOpen.value || e.metaKey || e.ctrlKey || e.altKey) return
  const tag = e.target?.tagName
  if (tag === 'INPUT' || tag === 'TEXTAREA' || e.target?.isContentEditable) return

  const num = Number(e.key)
  if (num >= 1 && num <= 6) {
    const target = (config.links || [])[num - 1]
    if (!target) return
    e.preventDefault()
    if (isInternalUrl(target.url)) {
      launchLink(target.url, target.name, {
        defaultPrevented: false,
        button: 0,
        preventDefault() {}
      })
    } else {
      window.open(target.url, '_blank', 'noopener')
    }
  }
}

onMounted(() => window.addEventListener('keydown', onKeydown))
onUnmounted(() => window.removeEventListener('keydown', onKeydown))
</script>

<template>
  <BackgroundScene />

  <button v-if="stage !== 'ready'" class="skip-intro" @click="onBootDone">
    跳过动画 · ESC →
  </button>

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
            <span class="topbar__ver">v2.0</span>
          </span>

          <span class="topbar__status tabular">
            <span class="eq" aria-hidden="true"><i /><i /><i /><i /><i /></span>
            <span class="topbar__stat">FPS<b>{{ fps }}</b></span>
            <span class="topbar__sep">/</span>
            <span class="topbar__stat">UPTIME<b>{{ uptime }}</b></span>
          </span>

          <span class="topbar__right">
            <button
              class="topbar__pill"
              title="切换背景壁纸"
              aria-label="切换背景壁纸"
              @click="triggerNextBackground"
            >
              <IconBase name="image" :size="12" />
            </button>

            <button
              class="topbar__pill topbar__cmd"
              title="快捷命令面板 (Ctrl+K)"
              @click="cmdOpen = true"
            >
              <IconBase name="command" :size="11" />
              <span>K</span>
            </button>

            <span class="theme" role="group" aria-label="主题切换">
              <button
                v-for="(p, key) in palettes"
                :key="key"
                class="theme__sw"
                :class="{ 'is-on': active === key }"
                :style="{ '--sw': p.a }"
                :title="p.label"
                :aria-label="`切换主题：${p.label}`"
                @click="setTheme(key)"
              />
            </span>
            <span class="topbar__link"><i class="topbar__live" />ONLINE</span>
          </span>
        </header>

        <!-- HUD 主区 -->
        <section class="hud">
          <SiteIdentity class="z-core" :delay="0.08" />
          <ClockCard class="z-chrono" :delay="0.14" />
          <WeatherCard class="z-atmos" :delay="0.19" />
          <QuoteCard class="z-trans" :delay="0.24" />
          <TimeCapsule class="z-load" :delay="0.29" />
          <NavPanel class="z-nav" :delay="0.16" @open-cmd="cmdOpen = true" />
        </section>

        <!-- 底部条 -->
        <footer class="botbar reveal" style="--delay: 0.42s">
          <span class="botbar__seg">© {{ f.startYear }}–{{ year }} {{ f.author }}</span>
          <span class="botbar__seg botbar__hint">按 1–6 直达舱室 · Ctrl+K 命令面板</span>
          <span class="botbar__seg" v-if="f.icp">
            <a :href="f.icpLink" target="_blank" rel="noopener">{{ f.icp }}</a>
          </span>
          <span class="botbar__seg" v-else>AURORA OBSIDIAN · VUE 3</span>
        </footer>
      </div>
    </main>

    <!-- 右下角系统监视器（雷达 + 负载） -->
    <SysMonitor />

    <!-- 全页扫描线（极淡） -->
    <div class="scanlines" aria-hidden="true"><span class="scanlines__sweep" /></div>
  </template>

  <!-- 命令面板 -->
  <CommandPalette :open="cmdOpen" @close="cmdOpen = false" />

  <!-- 导航点击：数据流过场 -->
  <DataStream />
</template>

<style scoped>
.skip-intro {
  position: fixed;
  top: 20px;
  right: 22px;
  z-index: 1100;
  padding: 8px 15px;
  font-family: var(--font-mono);
  font-size: 0.72rem;
  letter-spacing: 0.8px;
  color: var(--text);
  background: rgba(10, 15, 30, 0.72);
  border: 1px solid color-mix(in srgb, var(--accent-a) 45%, rgba(255, 255, 255, 0.14));
  border-radius: 999px;
  -webkit-backdrop-filter: blur(14px);
  backdrop-filter: blur(14px);
  box-shadow: 0 10px 28px -10px rgba(0, 0, 0, 0.7);
  transition: transform 0.25s var(--ease-out), border-color 0.25s, box-shadow 0.25s;
}
.skip-intro:hover {
  transform: translateY(-1px);
  border-color: var(--accent-a);
  box-shadow: 0 10px 28px -8px color-mix(in srgb, var(--accent-a) 45%, transparent);
}

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
  padding: 3.8vh 0 2rem;
}

/* ---------- top / bottom HUD strips ---------- */
.topbar,
.botbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  font-family: var(--font-mono);
  font-size: 0.65rem;
  letter-spacing: 1.5px;
  text-transform: uppercase;
  color: var(--text-dim);
}
.topbar {
  margin-bottom: 16px;
  padding: 8px 14px;
  border-radius: 14px;
  background: rgba(10, 15, 30, 0.56);
  border: 1px solid rgba(255, 255, 255, 0.08);
  -webkit-backdrop-filter: blur(16px) saturate(150%);
  backdrop-filter: blur(16px) saturate(150%);
}
.botbar {
  margin-top: 16px;
  padding: 12px 4px 0;
  border-top: 1px solid rgba(255, 255, 255, 0.08);
  flex-wrap: wrap;
}
.topbar__tag {
  display: inline-flex;
  align-items: center;
  gap: 7px;
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
  animation: pulse 1.8s ease-in-out infinite;
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
  min-width: 24px;
}
.topbar__sep {
  opacity: 0.4;
}

.topbar__right {
  display: inline-flex;
  align-items: center;
  gap: 11px;
}
.topbar__pill {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  padding: 4px 8px;
  border-radius: 8px;
  color: var(--text-soft);
  background: rgba(255, 255, 255, 0.05);
  border: 1px solid rgba(255, 255, 255, 0.09);
  transition: color 0.25s, border-color 0.25s, background 0.25s;
}
.topbar__pill:hover {
  color: var(--accent-a);
  border-color: color-mix(in srgb, var(--accent-a) 42%, transparent);
  background: color-mix(in srgb, var(--accent-a) 10%, transparent);
}
.topbar__cmd {
  font-size: 0.58rem;
  letter-spacing: 0.5px;
}

/* 主题切换 */
.theme {
  display: inline-flex;
  align-items: center;
  gap: 7px;
  padding: 4px 8px;
  border-radius: 999px;
  background: rgba(255, 255, 255, 0.04);
  border: 1px solid rgba(255, 255, 255, 0.07);
}
.theme__sw {
  width: 11px;
  height: 11px;
  padding: 0;
  border-radius: 50%;
  background: var(--sw);
  box-shadow: 0 0 6px color-mix(in srgb, var(--sw) 60%, transparent);
  outline: 1.5px solid transparent;
  outline-offset: 2px;
  opacity: 0.52;
  transition: opacity 0.25s, outline-color 0.25s, transform 0.25s var(--ease-out);
}
.theme__sw:hover {
  opacity: 0.9;
  transform: scale(1.15);
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
  height: 11px;
}
.eq i {
  width: 2px;
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

.botbar__hint {
  color: var(--text-dim);
  text-transform: none;
  letter-spacing: 0.8px;
}
.botbar a:hover {
  color: var(--text-soft);
}

/* ---------- HUD grid ---------- */
.hud {
  display: grid;
  gap: 16px;
  grid-template-columns: 1.04fr 1.18fr 0.98fr;
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
  inset: 10px;
  z-index: 40;
  pointer-events: none;
  border-radius: 18px;
  border: 1px solid rgba(255, 255, 255, 0.045);
}
.frame__b {
  position: absolute;
  width: 18px;
  height: 18px;
  border: 0 solid color-mix(in srgb, var(--accent-a) 70%, transparent);
}
.frame__b--tl { top: -1px; left: -1px; border-top-width: 1.5px; border-left-width: 1.5px; border-top-left-radius: 10px; }
.frame__b--tr { top: -1px; right: -1px; border-top-width: 1.5px; border-right-width: 1.5px; border-top-right-radius: 10px; }
.frame__b--bl { bottom: -1px; left: -1px; border-bottom-width: 1.5px; border-left-width: 1.5px; border-bottom-left-radius: 10px; }
.frame__b--br { bottom: -1px; right: -1px; border-bottom-width: 1.5px; border-right-width: 1.5px; border-bottom-right-radius: 10px; }

/* ---------- scanlines (ultra subtle) ---------- */
.scanlines {
  position: fixed;
  inset: 0;
  z-index: 60;
  pointer-events: none;
  background: repeating-linear-gradient(
    0deg,
    rgba(255, 255, 255, 0.012) 0 1px,
    transparent 1px 4px
  );
  overflow: hidden;
}
.scanlines__sweep {
  position: absolute;
  left: 0;
  right: 0;
  height: 22%;
  top: -22%;
  background: linear-gradient(
    180deg,
    transparent,
    color-mix(in srgb, var(--accent-a) 3.5%, transparent) 60%,
    color-mix(in srgb, var(--accent-a) 5.5%, transparent)
  );
  animation: sweepDown 9s linear infinite;
}
@keyframes sweepDown {
  to {
    transform: translateY(560%);
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
@media (max-width: 640px) {
  .console__inner {
    width: 92vw;
  }
  .topbar__status,
  .topbar__cmd,
  .botbar__hint {
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

/* 自检画面淡入 / 淡出 */
.boot-enter-active {
  transition: opacity 0.4s var(--ease-out);
}
.boot-leave-active {
  transition: opacity 0.55s var(--ease-out);
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
