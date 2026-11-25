<script setup>
import { ref, onUnmounted } from 'vue'
import HudModule from './HudModule.vue'
import IconBase from './IconBase.vue'
import { useHitokoto } from '../composables/useHitokoto.js'

defineProps({ delay: { type: Number, default: 0 } })
const { text, from, loading, refresh } = useHitokoto()

const copied = ref(false)
let copyTimer = null

async function copyQuote() {
  if (!text.value) return
  const payload = from.value ? `${text.value} —— ${from.value}` : text.value
  try {
    await navigator.clipboard?.writeText(payload)
    copied.value = true
    clearTimeout(copyTimer)
    copyTimer = setTimeout(() => {
      copied.value = false
    }, 1600)
  } catch {
    /* ignore clipboard failure */
  }
}

onUnmounted(() => clearTimeout(copyTimer))
</script>

<template>
  <HudModule label="TRANSMISSION" index="03" :delay="delay">
    <div class="tx">
      <p class="tx__text" :class="{ loading }">
        <span class="tx__prompt">&gt;&gt;</span>
        {{ text || 'decoding…' }}<span class="tx__cursor" />
      </p>
      <div class="tx__foot">
        <span class="tx__from" v-if="from">SRC // {{ from }}</span>
        <span v-else />
        <div class="tx__actions">
          <button
            class="tx__btn"
            :class="{ 'is-ok': copied }"
            :title="copied ? '已复制' : '复制语录'"
            :aria-label="copied ? '已复制' : '复制语录'"
            @click="copyQuote"
          >
            <IconBase :name="copied ? 'check' : 'copy'" :size="14" />
          </button>
          <button
            class="tx__btn tx__refresh"
            :class="{ spin: loading }"
            title="换一句"
            aria-label="换一句"
            @click="refresh"
          >
            <IconBase name="refresh" :size="14" />
          </button>
        </div>
      </div>
    </div>
  </HudModule>
</template>

<style scoped>
.tx {
  display: flex;
  flex-direction: column;
  gap: 12px;
}
.tx__text {
  font-size: clamp(0.95rem, 1.45vw, 1.1rem);
  line-height: 1.75;
  font-weight: 500;
  color: var(--text);
  transition: opacity 0.3s;
}
.tx__text.loading {
  opacity: 0.48;
}
.tx__prompt {
  font-family: var(--font-mono);
  color: var(--accent-a);
  margin-right: 6px;
  text-shadow: 0 0 8px color-mix(in srgb, var(--accent-a) 65%, transparent);
}
.tx__cursor {
  display: inline-block;
  width: 7px;
  height: 1.05em;
  margin-left: 5px;
  vertical-align: text-bottom;
  border-radius: 1px;
  background: var(--accent-c);
  box-shadow: 0 0 8px var(--accent-c);
  animation: caret 1.1s steps(1) infinite;
}
@keyframes caret {
  50% {
    opacity: 0;
  }
}
.tx__foot {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 8px;
  font-family: var(--font-mono);
  font-size: 0.66rem;
  letter-spacing: 1px;
  color: var(--text-dim);
}
.tx__actions {
  display: inline-flex;
  align-items: center;
  gap: 4px;
}
.tx__btn {
  display: grid;
  place-items: center;
  width: 28px;
  height: 28px;
  border-radius: 8px;
  color: var(--text-soft);
  border: 1px solid transparent;
  transition: color 0.25s, background 0.25s, border-color 0.25s, transform 0.45s var(--ease-out);
}
.tx__btn:hover {
  color: #fff;
  background: rgba(255, 255, 255, 0.08);
  border-color: rgba(255, 255, 255, 0.12);
}
.tx__btn.is-ok {
  color: var(--accent-a);
  border-color: color-mix(in srgb, var(--accent-a) 35%, transparent);
  background: color-mix(in srgb, var(--accent-a) 12%, transparent);
}
.tx__refresh:hover {
  transform: rotate(90deg);
}
.tx__refresh.spin :deep(.icon) {
  animation: spin 0.8s linear infinite;
}
@keyframes spin {
  to {
    transform: rotate(360deg);
  }
}
</style>
