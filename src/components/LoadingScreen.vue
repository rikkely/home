<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import config from '../config.js'

const emit = defineEmits(['done'])

const progress = ref(0)
const ignited = ref(false)
const site = config.site
let timer

// 一段随机会话 ID，纯装饰（科幻味）
const sid = Math.random().toString(16).slice(2, 8).toUpperCase()

// 进度环（HUD 机甲风的「装填」弧线）
const PROG_R = 72
const PROG_C = 2 * Math.PI * PROG_R
const progStyle = computed(() => ({
  strokeDasharray: PROG_C,
  strokeDashoffset: PROG_C * (1 - progress.value / 100)
}))

// 从核心上升的能量火花，位置/大小/节奏各异
function sparkStyle(n) {
  const seed = (n * 9301 + 49297) % 233280
  const r = seed / 233280
  const size = 2 + Math.round(r * 3)
  return {
    left: 8 + ((n * 13) % 84) + '%',
    top: 30 + ((n * 23) % 50) + '%',
    width: size + 'px',
    height: size + 6 + 'px',
    animationDuration: 1.6 + (n % 4) * 0.5 + 's',
    animationDelay: -(n * 0.5) + 's'
  }
}

onMounted(() => {
  // 脚本化的进度，手感比真实加载更顺滑
  const steps = [18, 37, 52, 68, 81, 93, 100]
  let i = 0
  const advance = () => {
    progress.value = steps[i]
    i += 1
    if (i < steps.length) {
      timer = setTimeout(advance, 100)
    } else {
      // 充能到 100% —— 点火！闪一下再交棒给自检画面
      ignited.value = true
      timer = setTimeout(() => emit('done'), 240)
    }
  }
  timer = setTimeout(advance, 100)
})
onUnmounted(() => clearTimeout(timer))
</script>

<template>
  <div class="loader" :class="{ 'is-ignited': ignited }">
    <div class="loader__grid" aria-hidden="true" />
    <div class="loader__glow" aria-hidden="true" />
    <div class="loader__sparks" aria-hidden="true">
      <span v-for="n in 12" :key="n" :style="sparkStyle(n)" />
    </div>

    <!-- 点火瞬间：闪光 + 冲击波 -->
    <div class="loader__flash" aria-hidden="true" />
    <div class="loader__shock" aria-hidden="true" />

    <!-- 座舱框角标 -->
    <span class="loader__fb loader__fb--tl" />
    <span class="loader__fb loader__fb--tr" />
    <span class="loader__fb loader__fb--bl" />
    <span class="loader__fb loader__fb--br" />

    <!-- 顶部 HUD 行 -->
    <div class="loader__top">
      <span class="loader__tag"><i />SYSTEM BOOT</span>
      <span class="loader__node">CORE // IGNITION · 0x{{ sid }}</span>
    </div>

    <div class="loader__inner">
      <svg class="mark" viewBox="0 0 200 200" width="158" height="158">
        <defs>
          <linearGradient id="lg" x1="0" y1="0" x2="1" y2="1">
            <stop offset="0" stop-color="var(--accent-a)" />
            <stop offset="0.5" stop-color="var(--accent-b)" />
            <stop offset="1" stop-color="var(--accent-c)" />
          </linearGradient>
        </defs>

        <circle cx="100" cy="100" r="94" fill="none" stroke="rgba(255,255,255,.08)" stroke-width="1.5" />
        <g class="ring ring--cw">
          <circle cx="100" cy="100" r="94" fill="none" stroke="url(#lg)" stroke-width="2.5" stroke-linecap="round" stroke-dasharray="70 150 26 344" />
        </g>
        <g class="ring ring--ccw">
          <circle cx="100" cy="100" r="82" fill="none" stroke="rgba(255,255,255,.2)" stroke-width="7" stroke-dasharray="2 13" />
        </g>
        <circle cx="100" cy="100" r="72" fill="none" stroke="rgba(255,255,255,.08)" stroke-width="4" />
        <circle class="prog" cx="100" cy="100" r="72" fill="none" stroke="url(#lg)" stroke-width="4" stroke-linecap="round" transform="rotate(-90 100 100)" :style="progStyle" />
        <g class="ring ring--slow" stroke="url(#lg)" stroke-width="2.5" stroke-linecap="round">
          <line x1="100" y1="42" x2="100" y2="54" />
          <line x1="158" y1="100" x2="146" y2="100" />
          <line x1="100" y1="158" x2="100" y2="146" />
          <line x1="42" y1="100" x2="54" y2="100" />
        </g>
        <g transform="translate(68 68)">
          <g transform="rotate(-28 32 32)">
            <path id="orbit" class="mark__orbit" d="M10,32 a22,9 0 1,0 44,0 a22,9 0 1,0 -44,0" fill="none" stroke="url(#lg)" stroke-width="2" />
            <circle class="mark__node" cx="0" cy="0" r="3" fill="url(#lg)">
              <animateMotion dur="2.8s" repeatCount="indefinite" rotate="auto">
                <mpath href="#orbit" />
              </animateMotion>
            </circle>
          </g>
          <circle class="mark__core" cx="32" cy="32" r="9" fill="none" stroke="url(#lg)" stroke-width="2.5" />
        </g>
      </svg>

      <div class="loader__title gradient-text">
        {{ site.name }}<span class="loader__suffix">{{ site.suffix }}</span>
      </div>
      <div class="loader__sub"><i class="loader__sub-dot" />{{ site.loadingText || '加载中' }}</div>

      <div class="loader__bar">
        <span class="loader__fill" :style="{ width: progress + '%' }" />
      </div>
      <div class="loader__readout">
        <span class="loader__pct">{{ progress }}%</span>
        <span class="loader__sep">//</span>
        <span>{{ ignited ? 'IGNITION SEQUENCE' : 'REACTOR WARM-UP' }}</span>
        <span class="loader__sep">//</span>
        <span class="loader__ok">{{ ignited ? 'FIRING' : 'NOMINAL' }}</span>
      </div>
    </div>

    <div class="loader__scan" aria-hidden="true" />
  </div>
</template>

<style scoped>
.loader {
  position: fixed;
  inset: 0;
  z-index: 990;
  display: grid;
  place-items: center;
  overflow: hidden;
  color: var(--text);
  background: radial-gradient(130% 120% at 50% 40%, #0b1326 0%, #06091380 55%, #04060e 100%),
    #04060e;
  font-family: var(--font-sans);
}

/* 科技网格 */
.loader__grid {
  position: absolute;
  inset: 0;
  background-image: linear-gradient(rgba(255, 255, 255, 0.04) 1px, transparent 1px),
    linear-gradient(90deg, rgba(255, 255, 255, 0.04) 1px, transparent 1px);
  background-size: 42px 42px;
  -webkit-mask: radial-gradient(120% 100% at 50% 45%, #000 28%, transparent 82%);
  mask: radial-gradient(120% 100% at 50% 45%, #000 28%, transparent 82%);
}

/* 核心能量辉光 */
.loader__glow {
  position: absolute;
  left: 50%;
  top: 42%;
  width: 380px;
  height: 380px;
  transform: translate(-50%, -50%);
  border-radius: 50%;
  background: radial-gradient(circle, color-mix(in srgb, var(--accent-a) 32%, transparent), transparent 62%);
  filter: blur(10px);
  animation: glowPulse 3.4s ease-in-out infinite;
}
@keyframes glowPulse {
  50% {
    transform: translate(-50%, -50%) scale(1.12);
    opacity: 0.75;
  }
}

/* 上升的能量火花 */
.loader__sparks {
  position: absolute;
  inset: 0;
}
.loader__sparks span {
  position: absolute;
  border-radius: 2px;
  background: linear-gradient(var(--accent-a), transparent);
  box-shadow: 0 0 8px var(--accent-a);
  animation-name: sparkUp;
  animation-timing-function: ease-out;
  animation-iteration-count: infinite;
  opacity: 0.7;
}
@keyframes sparkUp {
  0% {
    transform: translateY(14px) scaleY(0.6);
    opacity: 0;
  }
  20% {
    opacity: 0.9;
  }
  100% {
    transform: translateY(-46px) scaleY(1.2);
    opacity: 0;
  }
}

/* 座舱框角标 */
.loader__fb {
  position: absolute;
  width: 26px;
  height: 26px;
  border: 0 solid var(--accent-a);
  filter: drop-shadow(0 0 5px color-mix(in srgb, var(--accent-a) 55%, transparent));
}
.loader__fb--tl { top: 16px; left: 16px; border-top-width: 2px; border-left-width: 2px; }
.loader__fb--tr { top: 16px; right: 16px; border-top-width: 2px; border-right-width: 2px; }
.loader__fb--bl { bottom: 16px; left: 16px; border-bottom-width: 2px; border-left-width: 2px; }
.loader__fb--br { bottom: 16px; right: 16px; border-bottom-width: 2px; border-right-width: 2px; }

/* 顶部 HUD 行 */
.loader__top {
  position: absolute;
  top: 22px;
  left: 30px;
  right: 30px;
  display: flex;
  justify-content: space-between;
  font-family: var(--font-mono);
  font-size: 0.62rem;
  letter-spacing: 1.6px;
  text-transform: uppercase;
  color: var(--text-dim);
}
.loader__tag {
  display: inline-flex;
  align-items: center;
  gap: 7px;
  color: var(--accent-a);
}
.loader__tag i {
  width: 6px;
  height: 6px;
  background: var(--accent-a);
  box-shadow: 0 0 7px var(--accent-a);
  transform: rotate(45deg);
  animation: subBlink 1.4s ease-in-out infinite;
}

.loader__inner {
  position: relative;
  z-index: 2;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 12px;
}

.mark {
  overflow: visible;
  filter: drop-shadow(0 0 12px color-mix(in srgb, var(--accent-a) 35%, transparent));
}
.mark__orbit,
.mark__core {
  stroke-linecap: round;
}
.ring {
  transform-box: fill-box;
  transform-origin: center;
}
.ring--cw { animation: hudSpin 9s linear infinite; }
.ring--ccw { animation: hudSpin 16s linear infinite reverse; }
.ring--slow { animation: hudSpin 26s linear infinite; }
@keyframes hudSpin {
  to {
    transform: rotate(360deg);
  }
}
.prog {
  transition: stroke-dashoffset 0.45s var(--ease-out);
  filter: drop-shadow(0 0 6px color-mix(in srgb, var(--accent-a) 70%, transparent));
}

.loader__title {
  margin-top: 10px;
  font-family: var(--font-brand);
  font-size: 2rem;
  font-weight: 400;
  letter-spacing: 0.3px;
  text-shadow: 0 0 22px color-mix(in srgb, var(--accent-b) 45%, transparent);
}
.loader__suffix {
  font-family: var(--font-sans);
  font-size: 0.9rem;
  font-weight: 600;
  -webkit-text-fill-color: var(--text-dim);
  color: var(--text-dim);
}
.loader__sub {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  font-family: var(--font-mono);
  font-size: 0.78rem;
  color: var(--text-soft);
  letter-spacing: 1.5px;
}
.loader__sub-dot {
  width: 6px;
  height: 6px;
  border-radius: 50%;
  background: var(--accent-a);
  box-shadow: 0 0 8px var(--accent-a);
  animation: subBlink 1.2s ease-in-out infinite;
}
@keyframes subBlink {
  50% {
    opacity: 0.25;
  }
}

.loader__bar {
  margin-top: 8px;
  width: 230px;
  height: 4px;
  border-radius: 99px;
  background: rgba(255, 255, 255, 0.12);
  overflow: hidden;
  -webkit-mask: repeating-linear-gradient(90deg, #000 0 8px, transparent 8px 10px);
  mask: repeating-linear-gradient(90deg, #000 0 8px, transparent 8px 10px);
}
.loader__fill {
  display: block;
  height: 100%;
  background: linear-gradient(90deg, var(--accent-a), var(--accent-b), var(--accent-c));
  box-shadow: 0 0 12px color-mix(in srgb, var(--accent-a) 70%, transparent);
  transition: width 0.4s var(--ease-out);
}
.loader__readout {
  display: flex;
  align-items: center;
  gap: 7px;
  font-family: var(--font-mono);
  font-size: 0.64rem;
  letter-spacing: 1px;
  color: var(--text-dim);
}
.loader__pct {
  color: var(--accent-a);
}
.loader__sep {
  opacity: 0.4;
}
.loader__ok {
  color: var(--accent-a);
}

/* 扫描线 */
.loader__scan {
  position: absolute;
  inset: 0;
  pointer-events: none;
  opacity: 0.5;
  background: repeating-linear-gradient(0deg, rgba(255, 255, 255, 0.022) 0 1px, transparent 1px 3px);
}

/* ---------- 点火瞬间 ---------- */
.loader__flash {
  position: absolute;
  inset: 0;
  z-index: 6;
  pointer-events: none;
  opacity: 0;
  background: radial-gradient(
    circle at 50% 42%,
    rgba(255, 255, 255, 0.95),
    color-mix(in srgb, var(--accent-a) 70%, transparent) 22%,
    color-mix(in srgb, var(--accent-c) 28%, transparent) 40%,
    transparent 60%
  );
}
.loader__shock {
  position: absolute;
  left: 50%;
  top: 42%;
  width: 150px;
  height: 150px;
  margin: -75px 0 0 -75px;
  z-index: 5;
  border-radius: 50%;
  border: 2px solid var(--accent-a);
  box-shadow: 0 0 20px color-mix(in srgb, var(--accent-a) 70%, transparent);
  opacity: 0;
  pointer-events: none;
}
.loader__shock::after {
  content: '';
  position: absolute;
  inset: -5px;
  border-radius: 50%;
  border: 1px solid color-mix(in srgb, var(--accent-c) 80%, transparent);
}

.is-ignited .loader__flash {
  animation: igniteFlash 0.62s ease-out forwards;
}
.is-ignited .loader__shock {
  animation: igniteShock 0.66s cubic-bezier(0.2, 0.7, 0.3, 1) forwards;
}
.is-ignited .mark {
  animation: igniteFlare 0.62s ease-out;
}
.is-ignited .loader__glow {
  animation: igniteGlow 0.62s ease-out forwards;
}
.is-ignited .loader__fill {
  animation: igniteFill 0.62s ease-out;
}
.is-ignited .loader__pct,
.is-ignited .loader__ok {
  color: #fff;
  text-shadow: 0 0 10px var(--accent-a);
}

@keyframes igniteFlash {
  0% { opacity: 0; }
  14% { opacity: 0.95; }
  100% { opacity: 0; }
}
@keyframes igniteShock {
  0% { transform: scale(0.35); opacity: 0; }
  16% { opacity: 0.9; }
  100% { transform: scale(2.7); opacity: 0; }
}
@keyframes igniteFlare {
  0% { transform: scale(1); }
  18% {
    transform: scale(1.13);
    filter: drop-shadow(0 0 30px color-mix(in srgb, var(--accent-a) 90%, transparent)) brightness(1.7);
  }
  100% { transform: scale(1); }
}
@keyframes igniteGlow {
  0% { transform: translate(-50%, -50%) scale(1); opacity: 0.6; }
  20% { transform: translate(-50%, -50%) scale(1.7); opacity: 1; }
  100% { transform: translate(-50%, -50%) scale(1.25); opacity: 0; }
}
@keyframes igniteFill {
  0%, 100% { filter: brightness(1); }
  25% {
    filter: brightness(2.3);
    box-shadow: 0 0 26px var(--accent-a);
  }
}

@media (prefers-reduced-motion: reduce) {
  .loader__glow,
  .loader__sparks span,
  .ring,
  .loader__sub-dot,
  .loader__tag i {
    animation: none;
  }
}
</style>
