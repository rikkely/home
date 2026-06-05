<script setup>
import config from '../config.js'
import { socialIcons } from '../assets/media.js'
import HudModule from './HudModule.vue'
import IconBase from './IconBase.vue'

defineProps({ delay: { type: Number, default: 0 } })
const site = config.site
const socials = config.socials || []

const loc = String(config.weather?.location || '').split(',')
const coords = loc.length === 2 ? { lon: loc[0].trim(), lat: loc[1].trim() } : null
</script>

<template>
  <HudModule label="HOST.UNIT" index="00" :delay="delay">
    <div class="core">
      <!-- 反应堆核心：漂浮大头像 + 旋转准星 + 轨道能量点 + 能量辉光 -->
      <div class="core__reactor">
        <span class="core__glow" />
        <div class="id__avatar">
          <span class="id__avatar-float">
            <img :src="site.avatar" :alt="site.name" loading="eager" />
            <span class="id__ring" />
            <svg class="id__hud" viewBox="0 0 100 100" aria-hidden="true">
              <defs>
                <linearGradient id="hudg" x1="0" y1="0" x2="1" y2="1">
                  <stop offset="0" stop-color="var(--accent-a)" />
                  <stop offset="1" stop-color="var(--accent-c)" />
                </linearGradient>
              </defs>
              <circle cx="50" cy="50" r="47" fill="none" stroke="rgba(255,255,255,.28)" stroke-width="0.8" stroke-dasharray="0.5 4.5" />
              <g class="id__hud-rot">
                <circle cx="50" cy="50" r="47" fill="none" stroke="url(#hudg)" stroke-width="1.6" stroke-linecap="round" stroke-dasharray="22 80 14 178" />
                <g stroke="url(#hudg)" stroke-width="1.6" stroke-linecap="round">
                  <line x1="50" y1="1.5" x2="50" y2="8" />
                  <line x1="98.5" y1="50" x2="92" y2="50" />
                  <line x1="50" y1="98.5" x2="50" y2="92" />
                  <line x1="1.5" y1="50" x2="8" y2="50" />
                </g>
              </g>
            </svg>
            <span class="reactor__orbit"><i /><i /><i /></span>
          </span>
          <span class="id__avatar-shadow" />
        </div>
      </div>

      <!-- 身份信息 -->
      <div class="core__id">
        <div class="id__name">
          <span class="gradient-text">{{ site.name }}</span>
          <span class="id__suffix">{{ site.suffix }}</span>
        </div>

        <div class="id__readout">
          <span class="id__online"><i />ONLINE</span>
          <span v-if="coords" class="id__coords">LAT {{ coords.lat }} · LON {{ coords.lon }}</span>
        </div>

        <div class="id__socials">
          <a
            v-for="s in socials"
            :key="s.name"
            class="id__social"
            :href="s.url"
            :title="s.name"
            target="_blank"
            rel="noopener"
          >
            <img v-if="socialIcons[s.icon]" class="id__social-img" :src="socialIcons[s.icon]" :alt="s.name" />
            <IconBase v-else :name="s.icon" :size="20" />
          </a>
        </div>
      </div>
    </div>
  </HudModule>
</template>

<style scoped>
.core {
  height: 100%;
  display: flex;
  flex-direction: column;
  gap: 22px;
  justify-content: center;
  align-items: center;
}

/* ---------- reactor ---------- */
.core__reactor {
  position: relative;
  display: flex;
  justify-content: center;
  padding: 16px 0 6px;
}
.core__glow {
  position: absolute;
  top: 44%;
  left: 50%;
  width: 200px;
  height: 200px;
  transform: translate(-50%, -50%);
  border-radius: 50%;
  background: radial-gradient(circle, color-mix(in srgb, var(--accent-b) 55%, transparent), transparent 66%);
  filter: blur(16px);
  animation: corePulse 4s ease-in-out infinite;
}
@keyframes corePulse {
  50% {
    transform: translate(-50%, -50%) scale(1.14);
    opacity: 0.7;
  }
}

.id__avatar {
  position: relative;
  width: 140px;
  height: 160px;
  flex: none;
}
.id__avatar-float {
  position: absolute;
  top: 0;
  left: 0;
  width: 140px;
  height: 140px;
  animation: bob 3.8s var(--ease-in-out) infinite;
  transition: transform 0.5s var(--ease-out);
  will-change: transform;
}
.id__avatar:hover .id__avatar-float {
  animation-play-state: paused;
  transform: scale(1.05);
}
.id__avatar img {
  position: relative;
  z-index: 2;
  width: 100%;
  height: 100%;
  border-radius: 50%;
  object-fit: cover;
  background: rgba(255, 255, 255, 0.1);
  box-shadow: 0 12px 26px rgba(0, 0, 0, 0.38);
}
.id__ring {
  position: absolute;
  z-index: 3;
  inset: -5px;
  border-radius: 50%;
  background: conic-gradient(
    from 0deg,
    var(--accent-a),
    var(--accent-b),
    var(--accent-c),
    var(--accent-a)
  );
  -webkit-mask: radial-gradient(closest-side, transparent 79%, #000 81%);
  mask: radial-gradient(closest-side, transparent 79%, #000 81%);
  animation: spin 8s linear infinite;
}
.id__hud {
  position: absolute;
  z-index: 3;
  inset: -16px;
  overflow: visible;
  pointer-events: none;
  opacity: 0.55;
  transition: opacity 0.45s var(--ease-out);
}
.id__hud-rot {
  transform-box: fill-box;
  transform-origin: center;
  animation: hudSpin 38s linear infinite;
}
.id__avatar:hover .id__hud {
  opacity: 1;
}
.id__avatar:hover .id__hud-rot {
  animation-duration: 7s;
}
@keyframes hudSpin {
  to {
    transform: rotate(360deg);
  }
}

/* 轨道能量点 */
.reactor__orbit {
  position: absolute;
  z-index: 4;
  inset: -19px;
  pointer-events: none;
  animation: spin 17s linear infinite;
}
.id__avatar:hover .reactor__orbit {
  animation-duration: 6s;
}
.reactor__orbit i {
  position: absolute;
  inset: 0;
}
.reactor__orbit i:nth-child(2) {
  transform: rotate(120deg);
}
.reactor__orbit i:nth-child(3) {
  transform: rotate(240deg);
}
.reactor__orbit i::before {
  content: '';
  position: absolute;
  top: -3px;
  left: 50%;
  width: 7px;
  height: 7px;
  border-radius: 50%;
  transform: translateX(-50%);
  background: var(--accent-a);
  box-shadow: 0 0 9px var(--accent-a);
}
.reactor__orbit i:nth-child(2)::before {
  background: var(--accent-b);
  box-shadow: 0 0 9px var(--accent-b);
}
.reactor__orbit i:nth-child(3)::before {
  background: var(--accent-c);
  box-shadow: 0 0 9px var(--accent-c);
}

.id__avatar-shadow {
  position: absolute;
  left: 50%;
  bottom: 0;
  width: 86px;
  height: 14px;
  border-radius: 50%;
  background: radial-gradient(ellipse at center, rgba(0, 0, 0, 0.5), transparent 72%);
  filter: blur(3px);
  transform: translateX(-50%);
  animation: bobShadow 3.8s var(--ease-in-out) infinite;
}
@keyframes spin {
  to {
    transform: rotate(360deg);
  }
}
@keyframes bob {
  0%,
  100% {
    transform: translateY(0);
  }
  50% {
    transform: translateY(-12px);
  }
}
@keyframes bobShadow {
  0%,
  100% {
    transform: translateX(-50%) scale(1);
    opacity: 0.42;
  }
  50% {
    transform: translateX(-50%) scale(0.66);
    opacity: 0.22;
  }
}

/* ---------- identity text ---------- */
.core__id {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 14px;
  text-align: center;
}
.id__name {
  display: flex;
  align-items: baseline;
  flex-wrap: wrap;
  justify-content: center;
  gap: 0 6px;
  font-family: var(--font-brand);
  font-weight: 400;
  font-size: clamp(2.1rem, 4vw, 3rem);
  line-height: 1.1;
  padding-bottom: 0.08em;
}
.id__suffix {
  font-family: var(--font-sans);
  font-size: 1rem;
  font-weight: 600;
  color: var(--text-dim);
}

.id__readout {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  justify-content: center;
  gap: 6px 14px;
  font-family: var(--font-mono);
  font-size: 0.64rem;
  letter-spacing: 1.5px;
  text-transform: uppercase;
  color: var(--text-dim);
}
.id__online {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  color: var(--accent-a);
}
.id__online i {
  width: 6px;
  height: 6px;
  background: var(--accent-a);
  box-shadow: 0 0 8px var(--accent-a);
  animation: caretBlink 1.6s ease-in-out infinite;
}
@keyframes caretBlink {
  50% {
    opacity: 0.25;
  }
}

.id__socials {
  display: flex;
  gap: 12px;
  margin-top: 2px;
}
.id__social {
  display: grid;
  place-items: center;
  width: 44px;
  height: 44px;
  border-radius: 11px;
  color: var(--text-soft);
  background: rgba(255, 255, 255, 0.06);
  border: 1px solid rgba(255, 255, 255, 0.1);
  transition: transform 0.3s var(--ease-out), color 0.3s, background 0.3s,
    box-shadow 0.3s;
}
.id__social:hover {
  color: #fff;
  transform: translateY(-4px);
  background: rgba(255, 255, 255, 0.12);
  box-shadow: 0 0 16px -2px var(--accent-a);
}
.id__social-img {
  width: 21px;
  height: 21px;
  object-fit: contain;
  opacity: 0.82;
  transition: opacity 0.3s;
}
.id__social:hover .id__social-img {
  opacity: 1;
}
</style>
