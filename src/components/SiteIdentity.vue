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
      <!-- 反应堆核心：漂浮头像 + 精密星轨准星 -->
      <div class="core__reactor">
        <span class="core__glow" aria-hidden="true" />
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
              <circle
                cx="50"
                cy="50"
                r="47"
                fill="none"
                stroke="rgba(255,255,255,.22)"
                stroke-width="0.7"
                stroke-dasharray="0.6 4.4"
              />
              <g class="id__hud-rot">
                <circle
                  cx="50"
                  cy="50"
                  r="47"
                  fill="none"
                  stroke="url(#hudg)"
                  stroke-width="1.35"
                  stroke-linecap="round"
                  stroke-dasharray="22 80 14 178"
                />
                <g stroke="url(#hudg)" stroke-width="1.35" stroke-linecap="round">
                  <line x1="50" y1="1.5" x2="50" y2="7.5" />
                  <line x1="98.5" y1="50" x2="92.5" y2="50" />
                  <line x1="50" y1="98.5" x2="50" y2="92.5" />
                  <line x1="1.5" y1="50" x2="7.5" y2="50" />
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
        <span v-if="site.hello" class="id__hello">
          <IconBase name="sparkles" :size="12" />{{ site.hello }}
        </span>

        <div class="id__name">
          <span class="gradient-text">{{ site.name }}</span>
          <span v-if="site.suffix" class="id__suffix">{{ site.suffix }}</span>
        </div>

        <p v-if="site.description" class="id__desc">{{ site.description }}</p>

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
            :aria-label="s.name"
            target="_blank"
            rel="noopener"
          >
            <img v-if="socialIcons[s.icon]" class="id__social-img" :src="socialIcons[s.icon]" :alt="s.name" />
            <IconBase v-else :name="s.icon" :size="19" />
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
  gap: 16px;
  justify-content: center;
  align-items: center;
}

/* ---------- reactor ---------- */
.core__reactor {
  position: relative;
  display: flex;
  justify-content: center;
  padding: 12px 0 4px;
}
.core__glow {
  position: absolute;
  top: 44%;
  left: 50%;
  width: 186px;
  height: 186px;
  transform: translate(-50%, -50%);
  border-radius: 50%;
  background: radial-gradient(
    circle,
    color-mix(in srgb, var(--accent-b) 48%, transparent),
    transparent 68%
  );
  filter: blur(18px);
  animation: corePulse 4.5s ease-in-out infinite;
}
@keyframes corePulse {
  50% {
    transform: translate(-50%, -50%) scale(1.12);
    opacity: 0.65;
  }
}

.id__avatar {
  position: relative;
  width: 132px;
  height: 148px;
  flex: none;
}
.id__avatar-float {
  position: absolute;
  top: 0;
  left: 0;
  width: 132px;
  height: 132px;
  animation: bob 4s var(--ease-in-out) infinite;
  transition: transform 0.5s var(--ease-out);
  will-change: transform;
}
.id__avatar:hover .id__avatar-float {
  animation-play-state: paused;
  transform: scale(1.04);
}
.id__avatar img {
  position: relative;
  z-index: 2;
  width: 100%;
  height: 100%;
  border-radius: 50%;
  object-fit: cover;
  background: rgba(255, 255, 255, 0.08);
  box-shadow: 0 12px 28px rgba(0, 0, 0, 0.45);
}
.id__ring {
  position: absolute;
  z-index: 3;
  inset: -4px;
  border-radius: 50%;
  background: conic-gradient(
    from 0deg,
    var(--accent-a),
    var(--accent-b),
    var(--accent-c),
    var(--accent-a)
  );
  -webkit-mask: radial-gradient(closest-side, transparent 84%, #000 86%);
  mask: radial-gradient(closest-side, transparent 84%, #000 86%);
  animation: spin 9s linear infinite;
}
.id__hud {
  position: absolute;
  z-index: 3;
  inset: -15px;
  overflow: visible;
  pointer-events: none;
  opacity: 0.52;
  transition: opacity 0.45s var(--ease-out);
}
.id__hud-rot {
  transform-box: fill-box;
  transform-origin: center;
  animation: hudSpin 36s linear infinite;
}
.id__avatar:hover .id__hud {
  opacity: 0.95;
}
.id__avatar:hover .id__hud-rot {
  animation-duration: 8s;
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
  inset: -18px;
  pointer-events: none;
  animation: spin 18s linear infinite;
}
.id__avatar:hover .reactor__orbit {
  animation-duration: 7s;
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
  top: -2.5px;
  left: 50%;
  width: 6px;
  height: 6px;
  border-radius: 50%;
  transform: translateX(-50%);
  background: var(--accent-a);
  box-shadow: 0 0 8px var(--accent-a);
}
.reactor__orbit i:nth-child(2)::before {
  background: var(--accent-b);
  box-shadow: 0 0 8px var(--accent-b);
}
.reactor__orbit i:nth-child(3)::before {
  background: var(--accent-c);
  box-shadow: 0 0 8px var(--accent-c);
}

.id__avatar-shadow {
  position: absolute;
  left: 50%;
  bottom: 0;
  width: 82px;
  height: 12px;
  border-radius: 50%;
  background: radial-gradient(ellipse at center, rgba(0, 0, 0, 0.55), transparent 72%);
  filter: blur(3px);
  transform: translateX(-50%);
  animation: bobShadow 4s var(--ease-in-out) infinite;
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
    transform: translateY(-10px);
  }
}
@keyframes bobShadow {
  0%,
  100% {
    transform: translateX(-50%) scale(1);
    opacity: 0.42;
  }
  50% {
    transform: translateX(-50%) scale(0.68);
    opacity: 0.22;
  }
}

/* ---------- identity text ---------- */
.core__id {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 11px;
  text-align: center;
}
.id__hello {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 4px 12px;
  border-radius: 999px;
  font-family: var(--font-mono);
  font-size: 0.68rem;
  letter-spacing: 0.6px;
  color: var(--accent-a);
  background: color-mix(in srgb, var(--accent-a) 10%, rgba(255, 255, 255, 0.03));
  border: 1px solid color-mix(in srgb, var(--accent-a) 26%, transparent);
}
.id__name {
  display: flex;
  align-items: baseline;
  flex-wrap: wrap;
  justify-content: center;
  gap: 0 6px;
  font-family: var(--font-brand);
  font-weight: 400;
  font-size: clamp(2rem, 3.8vw, 2.8rem);
  line-height: 1.1;
  padding-bottom: 0.06em;
}
.id__suffix {
  font-family: var(--font-sans);
  font-size: 0.96rem;
  font-weight: 600;
  color: var(--text-dim);
}
.id__desc {
  max-width: 28ch;
  font-size: 0.82rem;
  line-height: 1.6;
  color: var(--text-soft);
}

.id__readout {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  justify-content: center;
  gap: 6px 12px;
  font-family: var(--font-mono);
  font-size: 0.62rem;
  letter-spacing: 1.4px;
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
  border-radius: 50%;
  background: var(--accent-a);
  box-shadow: 0 0 8px var(--accent-a);
  animation: caretBlink 1.8s ease-in-out infinite;
}
@keyframes caretBlink {
  50% {
    opacity: 0.3;
  }
}

.id__socials {
  display: flex;
  gap: 10px;
  margin-top: 4px;
}
.id__social {
  display: grid;
  place-items: center;
  width: 42px;
  height: 42px;
  border-radius: 12px;
  color: var(--text-soft);
  background: rgba(255, 255, 255, 0.045);
  border: 1px solid rgba(255, 255, 255, 0.09);
  box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.08);
  transition: transform 0.3s var(--ease-out), color 0.3s, background 0.3s,
    border-color 0.3s, box-shadow 0.3s;
}
.id__social:hover {
  color: #fff;
  transform: translateY(-3px);
  background: color-mix(in srgb, var(--accent-a) 14%, rgba(255, 255, 255, 0.08));
  border-color: color-mix(in srgb, var(--accent-a) 45%, transparent);
  box-shadow: 0 10px 22px -10px color-mix(in srgb, var(--accent-a) 65%, transparent);
}
.id__social-img {
  width: 20px;
  height: 20px;
  object-fit: contain;
  opacity: 0.84;
  transition: opacity 0.3s;
}
.id__social:hover .id__social-img {
  opacity: 1;
}
</style>
