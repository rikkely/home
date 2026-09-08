<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import config from '../config.js'
import { bundledBackgrounds } from '../assets/media.js'
import { usePointer } from '../composables/usePointer.js'

// 内置极光渐变场景（无需任何外部图片即可漂亮运行）
const GRADIENT_SCENES = [
  'radial-gradient(120% 90% at 18% 12%, #1b3a6b 0%, transparent 55%), radial-gradient(100% 80% at 85% 20%, #6d4aa733 0%, transparent 50%), radial-gradient(120% 120% at 70% 90%, #2bd9c733 0%, transparent 55%), linear-gradient(160deg, #070b1a, #0c1430 60%, #07101e)',
  'radial-gradient(110% 90% at 80% 15%, #c2410c55 0%, transparent 55%), radial-gradient(120% 100% at 15% 85%, #7c3aed55 0%, transparent 55%), radial-gradient(90% 70% at 50% 50%, #f472b633 0%, transparent 60%), linear-gradient(160deg, #1a0b1e, #160d2e 60%, #0a0716)',
  'radial-gradient(120% 100% at 15% 20%, #0e7490 0%, transparent 55%), radial-gradient(100% 90% at 85% 80%, #1e3a8a 0%, transparent 55%), radial-gradient(80% 70% at 60% 40%, #22d3ee2e 0%, transparent 60%), linear-gradient(170deg, #04121f, #06182b 60%, #030d18)',
  'radial-gradient(120% 90% at 80% 18%, #a21caf55 0%, transparent 55%), radial-gradient(110% 100% at 20% 80%, #4338ca66 0%, transparent 55%), radial-gradient(70% 60% at 45% 45%, #e879f92e 0%, transparent 60%), linear-gradient(160deg, #0d0820, #150a2b 60%, #08050f)',
  'radial-gradient(120% 90% at 20% 20%, #047857 0%, transparent 55%), radial-gradient(100% 90% at 85% 75%, #0f766e 0%, transparent 55%), radial-gradient(80% 70% at 55% 45%, #34d39933 0%, transparent 60%), linear-gradient(165deg, #051712, #07241c 60%, #03130f)'
]

// 优先级：config 里手填的网络图片 > 打包进来的本地图片 > 内置渐变场景
const imageList = computed(() => {
  const cfg = config.background?.images
  if (Array.isArray(cfg) && cfg.length) return cfg
  if (bundledBackgrounds.length) return bundledBackgrounds
  return []
})
const useImages = computed(() => imageList.value.length > 0)

const scenes = computed(() =>
  useImages.value ? imageList.value : GRADIENT_SCENES
)

const active = ref(0)
// 已就绪可显示的场景索引。渐变是纯 CSS、无需网络，因此无所谓；
// 图片模式下只有「加载完成」的图片才会被赋上 background-image，
// 这样浏览器首屏只会请求第 1 张，其余按需逐张加载（移动端流量大幅降低）。
const loaded = ref(new Set([0]))
let timer = null

const { x, y } = usePointer()
const parallax = computed(() => ({
  transform: `scale(1.08) translate(${x.value * -14}px, ${y.value * -14}px)`
}))
const orbParallax = computed(() => ({
  transform: `translate(${x.value * 26}px, ${y.value * 26}px)`
}))

const isReady = (i) => !useImages.value || loaded.value.has(i)
const layerStyle = (scene, i) => {
  // 未就绪 → 不设置背景图，浏览器不会去下载这张图
  if (!isReady(i)) return {}
  return useImages.value
    ? { backgroundImage: `url("${scene}")` }
    : { backgroundImage: scene }
}

function markLoaded(i) {
  if (loaded.value.has(i)) return
  const s = new Set(loaded.value)
  s.add(i)
  loaded.value = s
}

// 先把下一张预加载好，再切换显示，避免淡入时图片还没下好导致「先黑后跳」
function preloadThenSwitch(i) {
  if (!useImages.value || loaded.value.has(i)) {
    active.value = i
    return
  }
  const img = new Image()
  img.onload = img.onerror = () => {
    markLoaded(i)
    active.value = i
  }
  img.src = scenes.value[i]
}

onMounted(() => {
  const interval = config.background?.interval || 11000
  if (scenes.value.length > 1) {
    timer = setInterval(() => {
      const next = (active.value + 1) % scenes.value.length
      preloadThenSwitch(next)
    }, interval)
  }
})
onUnmounted(() => clearInterval(timer))
</script>

<template>
  <div class="bg" aria-hidden="true">
    <div class="bg__parallax" :style="parallax">
      <div
        v-for="(scene, i) in scenes"
        :key="i"
        class="bg__layer"
        :class="{ 'is-active': i === active }"
        :style="layerStyle(scene, i)"
      />
    </div>

    <!-- 漂浮光球，制造景深 -->
    <div class="bg__orbs" :style="orbParallax">
      <span class="orb orb--a" />
      <span class="orb orb--b" />
      <span class="orb orb--c" />
    </div>

    <div class="bg__vignette" />
    <div class="bg__grid" />
    <div class="bg__grain" />
  </div>
</template>

<style scoped>
.bg {
  position: fixed;
  inset: 0;
  z-index: -1;
  overflow: hidden;
  background: var(--bg-0);
}

.bg__parallax {
  position: absolute;
  inset: -4%;
  will-change: transform;
  transition: transform 0.5s var(--ease-out);
}

.bg__layer {
  position: absolute;
  inset: 0;
  background-size: cover;
  background-position: center;
  opacity: 0;
  transform: scale(1.06);
  transition: opacity 2.2s var(--ease-in-out), transform 12s linear;
  will-change: opacity, transform;
}
.bg__layer.is-active {
  opacity: 1;
  transform: scale(1); /* slow ken-burns settle */
}

/* floating orbs */
.bg__orbs {
  position: absolute;
  inset: 0;
  transition: transform 0.6s var(--ease-out);
}
.orb {
  position: absolute;
  border-radius: 50%;
  filter: blur(60px);
  opacity: 0.5;
  mix-blend-mode: screen;
}
.orb--a {
  width: 42vw;
  height: 42vw;
  top: -10%;
  left: -6%;
  background: radial-gradient(circle, var(--accent-a), transparent 70%);
  animation: drift1 22s var(--ease-in-out) infinite;
}
.orb--b {
  width: 36vw;
  height: 36vw;
  bottom: -12%;
  right: -8%;
  background: radial-gradient(circle, var(--accent-c), transparent 70%);
  animation: drift2 26s var(--ease-in-out) infinite;
}
.orb--c {
  width: 28vw;
  height: 28vw;
  top: 40%;
  left: 55%;
  background: radial-gradient(circle, var(--accent-b), transparent 70%);
  animation: drift3 30s var(--ease-in-out) infinite;
}

@keyframes drift1 {
  50% {
    transform: translate(8vw, 6vh) scale(1.1);
  }
}
@keyframes drift2 {
  50% {
    transform: translate(-7vw, -5vh) scale(1.15);
  }
}
@keyframes drift3 {
  50% {
    transform: translate(-6vw, 7vh) scale(0.9);
  }
}

/* readability layers */
.bg__vignette {
  position: absolute;
  inset: 0;
  background: radial-gradient(
      120% 100% at 50% 30%,
      transparent 40%,
      rgba(0, 0, 0, 0.45) 100%
    ),
    linear-gradient(180deg, rgba(0, 0, 0, 0.25), rgba(0, 0, 0, 0.35));
}

/* 极淡的 HUD 网格，向边缘淡出 */
.bg__grid {
  position: absolute;
  inset: 0;
  background-image: linear-gradient(rgba(255, 255, 255, 0.028) 1px, transparent 1px),
    linear-gradient(90deg, rgba(255, 255, 255, 0.028) 1px, transparent 1px);
  background-size: 46px 46px;
  -webkit-mask: radial-gradient(125% 95% at 50% 42%, #000 28%, transparent 86%);
  mask: radial-gradient(125% 95% at 50% 42%, #000 28%, transparent 86%);
}

.bg__grain {
  position: absolute;
  inset: 0;
  opacity: 0.05;
  background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='160' height='160'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.85' numOctaves='2' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23n)'/%3E%3C/svg%3E");
}

/* 移动端降负载：光球的大半径模糊 + screen 混合在 X5/微信内核里很吃 GPU，
   缩小模糊半径、去掉混合与噪点，滚动与首帧都会明显更顺。 */
@media (max-width: 640px) {
  .orb {
    filter: blur(34px);
    opacity: 0.38;
    mix-blend-mode: normal;
  }
  .bg__grain {
    display: none;
  }
}

@media (prefers-reduced-motion: reduce) {
  .orb {
    animation: none;
  }
}
</style>
