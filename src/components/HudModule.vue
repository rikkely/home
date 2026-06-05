<script setup>
/**
 * 「全息读数」—— 不是卡片：没有实心面板/边框，只有
 *   · 向边缘溶解的弱背衬（保证可读性，但没有硬边）
 *   · 左侧能量脊 + 顶部标题分隔线
 *   · 左上 / 右下 的开放式取景括号
 *   · 扫描线
 */
defineProps({
  label: { type: String, default: '' },
  index: { type: String, default: '' },
  delay: { type: Number, default: 0 },
  tilt: { type: Boolean, default: true }
})
</script>

<template>
  <div class="hr reveal" :style="{ '--delay': delay + 's' }">
    <div class="hr__inner" v-tilt="tilt ? { max: 3.5, scale: 1.006, glare: false } : { max: 0, glare: false }">
      <div class="hr__scrim" />
      <div class="hr__scan" />
      <span class="hr__br hr__br--tl" />
      <span class="hr__br hr__br--br" />

      <header class="hr__head">
        <span class="hr__label"><i />{{ label }}</span>
        <span class="hr__idx">{{ index }}</span>
      </header>
      <div class="hr__rule" />

      <div class="hr__body"><slot /></div>
    </div>
  </div>
</template>

<style scoped>
.hr {
  height: 100%;
  min-width: 0;
}
.hr__inner {
  position: relative;
  height: 100%;
  padding: clamp(15px, 2vw, 21px) clamp(16px, 2.1vw, 22px);
  display: flex;
  flex-direction: column;
  transition: transform 0.5s var(--ease-out);
}

/* 弱背衬：向右下方溶解，没有硬边（所以不像卡片） */
.hr__scrim {
  position: absolute;
  inset: 0;
  background: linear-gradient(155deg, rgba(7, 11, 24, 0.52), rgba(7, 11, 24, 0.14));
  -webkit-backdrop-filter: blur(7px) saturate(140%);
  backdrop-filter: blur(7px) saturate(140%);
  -webkit-mask: radial-gradient(135% 130% at 22% 16%, #000 48%, transparent 100%);
  mask: radial-gradient(135% 130% at 22% 16%, #000 48%, transparent 100%);
}
.hr__scan {
  position: absolute;
  inset: 0;
  pointer-events: none;
  opacity: 0.5;
  background: repeating-linear-gradient(0deg, rgba(255, 255, 255, 0.04) 0 1px, transparent 1px 3px);
  -webkit-mask: radial-gradient(130% 120% at 22% 16%, #000 50%, transparent 100%);
  mask: radial-gradient(130% 120% at 22% 16%, #000 50%, transparent 100%);
}

/* 左侧能量脊 */
.hr__inner::before {
  content: '';
  position: absolute;
  left: 0;
  top: 14px;
  bottom: 14px;
  width: 2px;
  background: linear-gradient(var(--accent-a), transparent 70%);
  opacity: 0.5;
  transition: opacity 0.4s, box-shadow 0.4s;
}
.hr__inner:hover::before {
  opacity: 1;
  box-shadow: 0 0 10px var(--accent-a);
}

/* 开放式取景括号 */
.hr__br {
  position: absolute;
  width: 14px;
  height: 14px;
  border: 0 solid color-mix(in srgb, var(--accent-a) 55%, transparent);
  transition: width 0.4s var(--ease-out), height 0.4s var(--ease-out), border-color 0.4s;
  z-index: 3;
}
.hr__br--tl {
  top: 0;
  left: 0;
  border-top-width: 2px;
  border-left-width: 2px;
}
.hr__br--br {
  bottom: 0;
  right: 0;
  border-bottom-width: 2px;
  border-right-width: 2px;
}
.hr__inner:hover .hr__br {
  width: 19px;
  height: 19px;
  border-color: var(--accent-a);
}

.hr__head {
  position: relative;
  z-index: 2;
  display: flex;
  align-items: center;
  justify-content: space-between;
  font-family: var(--font-mono);
  font-size: 0.62rem;
  letter-spacing: 1.6px;
  text-transform: uppercase;
  color: var(--text-dim);
}
.hr__label {
  display: inline-flex;
  align-items: center;
  gap: 7px;
  color: var(--accent-a);
}
.hr__label i {
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
.hr__rule {
  position: relative;
  z-index: 2;
  height: 1px;
  margin: 9px 0 13px;
  background: linear-gradient(90deg, color-mix(in srgb, var(--accent-a) 65%, transparent), transparent 72%);
}
.hr__body {
  position: relative;
  z-index: 2;
  flex: 1;
  min-height: 0;
  display: flex;
  flex-direction: column;
  justify-content: center;
}
</style>
