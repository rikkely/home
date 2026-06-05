<script setup>
import { useSystemStats } from '../composables/useSystemStats.js'

// 复用真实 FPS / 在线时长
const { fps, uptime } = useSystemStats()
</script>

<template>
  <aside class="sm" aria-hidden="true">
    <div class="sm__scrim" />
    <span class="sm__br sm__br--tl" />
    <span class="sm__br sm__br--br" />

    <div class="sm__head"><i />SYS.MONITOR</div>

    <!-- 雷达扫描 -->
    <div class="sm__scope">
      <span class="sm__ring sm__ring--1" />
      <span class="sm__ring sm__ring--2" />
      <span class="sm__cross" />
      <span class="sm__sweep" />
      <span class="sm__blip sm__blip--a" />
      <span class="sm__blip sm__blip--b" />
      <span class="sm__blip sm__blip--c" />
    </div>

    <!-- 负载条 -->
    <div class="sm__bars">
      <div class="sm__bar">
        <span class="sm__bk">CPU</span>
        <span class="sm__bt"><i class="sm__bf sm__bf--a" /></span>
      </div>
      <div class="sm__bar">
        <span class="sm__bk">MEM</span>
        <span class="sm__bt"><i class="sm__bf sm__bf--b" /></span>
      </div>
      <div class="sm__bar">
        <span class="sm__bk">NET</span>
        <span class="sm__bt"><i class="sm__bf sm__bf--c" /></span>
      </div>
    </div>

    <div class="sm__foot">
      <span>FPS {{ fps }}</span>
      <span>{{ uptime }}</span>
    </div>
  </aside>
</template>

<style scoped>
.sm {
  position: fixed;
  right: 18px;
  bottom: 16px;
  z-index: 45;
  width: 158px;
  padding: 11px 12px 10px;
  pointer-events: none;
  font-family: var(--font-mono);
  opacity: 0.92;
}
.sm__scrim {
  position: absolute;
  inset: 0;
  background: linear-gradient(155deg, rgba(7, 11, 24, 0.55), rgba(7, 11, 24, 0.2));
  -webkit-backdrop-filter: blur(7px);
  backdrop-filter: blur(7px);
  -webkit-mask: radial-gradient(140% 130% at 28% 18%, #000 52%, transparent 100%);
  mask: radial-gradient(140% 130% at 28% 18%, #000 52%, transparent 100%);
}
.sm__br {
  position: absolute;
  width: 12px;
  height: 12px;
  border: 0 solid color-mix(in srgb, var(--accent-a) 55%, transparent);
}
.sm__br--tl { top: 0; left: 0; border-top-width: 2px; border-left-width: 2px; }
.sm__br--br { bottom: 0; right: 0; border-bottom-width: 2px; border-right-width: 2px; }

.sm__head {
  position: relative;
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 0.56rem;
  letter-spacing: 1.5px;
  color: var(--accent-a);
  margin-bottom: 8px;
}
.sm__head i {
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

/* 雷达 */
.sm__scope {
  position: relative;
  width: 100%;
  aspect-ratio: 1;
  margin-bottom: 9px;
}
.sm__ring {
  position: absolute;
  border-radius: 50%;
  border: 1px solid color-mix(in srgb, var(--accent-a) 24%, transparent);
}
.sm__ring--1 {
  inset: 4%;
}
.sm__ring--2 {
  inset: 28%;
}
.sm__cross {
  position: absolute;
  inset: 4%;
  background: linear-gradient(transparent calc(50% - 0.5px), color-mix(in srgb, var(--accent-a) 20%, transparent) calc(50% - 0.5px) calc(50% + 0.5px), transparent calc(50% + 0.5px)),
    linear-gradient(90deg, transparent calc(50% - 0.5px), color-mix(in srgb, var(--accent-a) 20%, transparent) calc(50% - 0.5px) calc(50% + 0.5px), transparent calc(50% + 0.5px));
}
.sm__sweep {
  position: absolute;
  inset: 4%;
  border-radius: 50%;
  background: conic-gradient(from 0deg, color-mix(in srgb, var(--accent-a) 55%, transparent), transparent 65deg);
  -webkit-mask: radial-gradient(circle, #000 99%, transparent 100%);
  mask: radial-gradient(circle, #000 99%, transparent 100%);
  animation: spin 3.2s linear infinite;
}
@keyframes spin {
  to {
    transform: rotate(360deg);
  }
}
.sm__blip {
  position: absolute;
  width: 5px;
  height: 5px;
  border-radius: 50%;
  background: var(--accent-c);
  box-shadow: 0 0 7px var(--accent-c);
  opacity: 0;
}
.sm__blip--a { top: 30%; left: 62%; animation: blip 3.2s ease-in-out infinite; }
.sm__blip--b { top: 60%; left: 40%; animation: blip 3.2s ease-in-out 1.1s infinite; }
.sm__blip--c { top: 50%; left: 70%; animation: blip 3.2s ease-in-out 2.2s infinite; }
@keyframes blip {
  0%, 100% { opacity: 0; }
  8% { opacity: 1; }
  55% { opacity: 0; }
}

/* 负载条 */
.sm__bars {
  position: relative;
  display: flex;
  flex-direction: column;
  gap: 5px;
}
.sm__bar {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 0.52rem;
  letter-spacing: 0.5px;
  color: var(--text-dim);
}
.sm__bk {
  width: 22px;
  color: var(--accent-a);
}
.sm__bt {
  flex: 1;
  height: 4px;
  background: rgba(255, 255, 255, 0.1);
  -webkit-mask: repeating-linear-gradient(90deg, #000 0 5px, transparent 5px 7px);
  mask: repeating-linear-gradient(90deg, #000 0 5px, transparent 5px 7px);
}
.sm__bf {
  display: block;
  height: 100%;
  background: linear-gradient(90deg, var(--accent-a), var(--accent-b));
}
.sm__bf--a { animation: loadA 4.5s ease-in-out infinite; }
.sm__bf--b { animation: loadB 6s ease-in-out infinite; }
.sm__bf--c { animation: loadC 3.5s ease-in-out infinite; }
@keyframes loadA {
  0%, 100% { width: 38%; }
  30% { width: 72%; }
  55% { width: 50%; }
  80% { width: 88%; }
}
@keyframes loadB {
  0%, 100% { width: 55%; }
  40% { width: 30%; }
  70% { width: 66%; }
}
@keyframes loadC {
  0%, 100% { width: 60%; }
  25% { width: 95%; }
  60% { width: 42%; }
}

.sm__foot {
  position: relative;
  display: flex;
  justify-content: space-between;
  margin-top: 8px;
  font-size: 0.54rem;
  letter-spacing: 0.5px;
  color: var(--text-dim);
}

/* 仅在足够宽的屏幕显示，让它落在网格右侧留白里、不遮挡内容 */
@media (max-width: 1440px) {
  .sm {
    display: none;
  }
}
@media (prefers-reduced-motion: reduce) {
  .sm__sweep,
  .sm__blip,
  .sm__bf {
    animation: none;
  }
}
</style>
