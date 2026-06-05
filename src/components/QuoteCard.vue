<script setup>
import HudModule from './HudModule.vue'
import IconBase from './IconBase.vue'
import { useHitokoto } from '../composables/useHitokoto.js'

defineProps({ delay: { type: Number, default: 0 } })
const { text, from, loading, refresh } = useHitokoto()
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
        <button class="tx__refresh" :class="{ spin: loading }" title="换一句" @click="refresh">
          <IconBase name="refresh" :size="15" />
        </button>
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
  font-size: clamp(0.95rem, 1.5vw, 1.12rem);
  line-height: 1.7;
  font-weight: 500;
  transition: opacity 0.3s;
}
.tx__text.loading {
  opacity: 0.5;
}
.tx__prompt {
  font-family: var(--font-mono);
  color: var(--accent-a);
  margin-right: 6px;
  text-shadow: 0 0 8px var(--accent-a);
}
.tx__cursor {
  display: inline-block;
  width: 8px;
  height: 1.05em;
  margin-left: 4px;
  vertical-align: text-bottom;
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
  font-family: var(--font-mono);
  font-size: 0.68rem;
  letter-spacing: 1px;
  color: var(--text-dim);
}
.tx__refresh {
  display: grid;
  place-items: center;
  width: 30px;
  height: 30px;
  border-radius: 8px;
  color: var(--text-soft);
  transition: color 0.3s, background 0.3s, transform 0.5s var(--ease-out);
}
.tx__refresh:hover {
  color: #fff;
  background: rgba(255, 255, 255, 0.1);
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
