<script setup>
import { ref, computed, watch, nextTick, onMounted, onUnmounted } from 'vue'
import config from '../config.js'
import IconBase from './IconBase.vue'
import { useTheme } from '../composables/useTheme.js'
import { launchLink, isInternalUrl } from '../composables/useLink.js'
import { triggerNextBackground } from './BackgroundScene.vue'

const props = defineProps({
  open: { type: Boolean, default: false }
})
const emit = defineEmits(['close'])

const { active: activeTheme, palettes, setTheme } = useTheme()
const query = ref('')
const activeIdx = ref(0)
const inputRef = ref(null)
const copiedSite = ref(false)

const allItems = computed(() => {
  const list = []

  for (const [i, l] of (config.links || []).entries()) {
    list.push({
      id: `link-${l.url}`,
      group: '导航舱室',
      icon: l.icon || 'compass',
      title: l.name,
      sub: l.desc,
      hint: `${i + 1}`,
      keywords: `${l.name} ${l.desc} ${l.url}`,
      run: (e) => {
        emit('close')
        if (isInternalUrl(l.url)) {
          launchLink(l.url, l.name, e || { defaultPrevented: false, button: 0, preventDefault() {} })
        } else {
          window.open(l.url, '_blank', 'noopener')
        }
      }
    })
  }

  list.push({
    id: 'act-bg',
    group: '控制台指令',
    icon: 'image',
    title: '切换背景壁纸',
    sub: '切换到下一张背景场景',
    hint: 'BG',
    keywords: 'wallpaper background 背景 壁纸 切换',
    run: () => {
      triggerNextBackground()
      emit('close')
    }
  })

  for (const [key, p] of Object.entries(palettes)) {
    list.push({
      id: `theme-${key}`,
      group: '控制台指令',
      icon: 'sliders',
      title: `切换主题 · ${p.label}`,
      sub: activeTheme.value === key ? '当前已激活' : `应用 ${p.code} 色板`,
      hint: activeTheme.value === key ? 'ON' : '',
      keywords: `theme color 主题 配色 ${p.label} ${p.code} ${key}`,
      run: () => {
        setTheme(key)
        emit('close')
      }
    })
  }

  list.push({
    id: 'act-copy-url',
    group: '控制台指令',
    icon: copiedSite.value ? 'check' : 'copy',
    title: copiedSite.value ? '已复制站点地址' : '复制当前站点地址',
    sub: location.origin,
    hint: 'COPY',
    keywords: 'copy url link 复制 地址 分享',
    run: async () => {
      try {
        await navigator.clipboard?.writeText(location.href)
        copiedSite.value = true
        setTimeout(() => {
          copiedSite.value = false
        }, 1400)
      } catch {
        /* ignore */
      }
      emit('close')
    }
  })

  for (const s of config.socials || []) {
    list.push({
      id: `social-${s.name}`,
      group: '外部联络',
      icon: s.icon || 'link',
      title: s.name,
      sub: s.url,
      hint: '↗',
      keywords: `social 社交 ${s.name} ${s.url}`,
      run: () => {
        window.open(s.url, '_blank', 'noopener')
        emit('close')
      }
    })
  }

  return list
})

const filtered = computed(() => {
  const q = query.value.trim().toLowerCase()
  if (!q) return allItems.value
  return allItems.value.filter((item) => item.keywords.toLowerCase().includes(q))
})

const grouped = computed(() => {
  const groups = []
  const map = new Map()
  filtered.value.forEach((item, flatIdx) => {
    if (!map.has(item.group)) {
      const g = { name: item.group, items: [] }
      map.set(item.group, g)
      groups.push(g)
    }
    map.get(item.group).items.push({ ...item, flatIdx })
  })
  return groups
})

watch(
  () => props.open,
  async (val) => {
    if (val) {
      query.value = ''
      activeIdx.value = 0
      await nextTick()
      inputRef.value?.focus()
    }
  }
)

watch(filtered, (list) => {
  if (activeIdx.value >= list.length) activeIdx.value = 0
})

function onKeydown(e) {
  if (!props.open) return
  if (e.key === 'Escape') {
    e.preventDefault()
    emit('close')
    return
  }
  if (!filtered.value.length) return
  if (e.key === 'ArrowDown') {
    e.preventDefault()
    activeIdx.value = (activeIdx.value + 1) % filtered.value.length
  } else if (e.key === 'ArrowUp') {
    e.preventDefault()
    activeIdx.value = (activeIdx.value - 1 + filtered.value.length) % filtered.value.length
  } else if (e.key === 'Enter') {
    e.preventDefault()
    filtered.value[activeIdx.value]?.run()
  }
}

onMounted(() => window.addEventListener('keydown', onKeydown))
onUnmounted(() => window.removeEventListener('keydown', onKeydown))
</script>

<template>
  <Teleport to="body">
    <Transition name="cmd">
      <div v-if="open" class="cmd" role="dialog" aria-modal="true" aria-label="快捷命令面板" @click.self="emit('close')">
        <div class="cmd__box">
          <div class="cmd__top">
            <IconBase name="search" :size="16" />
            <input
              ref="inputRef"
              v-model="query"
              type="text"
              placeholder="输入舱室名称、主题或指令…"
              spellcheck="false"
            />
            <button class="cmd__esc" @click="emit('close')">ESC</button>
          </div>

          <div class="cmd__list">
            <p v-if="!filtered.length" class="cmd__empty">没有找到匹配的指令或舱室</p>
            <div v-for="g in grouped" :key="g.name" class="cmd__group">
              <div class="cmd__gname">{{ g.name }}</div>
              <button
                v-for="item in g.items"
                :key="item.id"
                class="cmd__item"
                :class="{ 'is-on': item.flatIdx === activeIdx }"
                @mouseenter="activeIdx = item.flatIdx"
                @click="item.run($event)"
              >
                <span class="cmd__ico"><IconBase :name="item.icon" :size="15" /></span>
                <span class="cmd__main">
                  <span class="cmd__title">{{ item.title }}</span>
                  <span class="cmd__sub">{{ item.sub }}</span>
                </span>
                <span v-if="item.hint" class="cmd__hint">{{ item.hint }}</span>
              </button>
            </div>
          </div>

          <div class="cmd__foot">
            <span>↑↓ 选择</span>
            <span>↵ 执行</span>
            <span>ESC 关闭</span>
          </div>
        </div>
      </div>
    </Transition>
  </Teleport>
</template>

<style scoped>
.cmd {
  position: fixed;
  inset: 0;
  z-index: 950;
  display: grid;
  place-items: start center;
  padding-top: min(14vh, 110px);
  background: rgba(3, 6, 14, 0.72);
  -webkit-backdrop-filter: blur(8px);
  backdrop-filter: blur(8px);
}
.cmd__box {
  width: min(560px, 92vw);
  border-radius: 18px;
  background: linear-gradient(160deg, rgba(13, 19, 38, 0.92), rgba(7, 11, 22, 0.94));
  border: 1px solid color-mix(in srgb, var(--accent-a) 28%, rgba(255, 255, 255, 0.12));
  box-shadow: 0 28px 80px -16px rgba(0, 0, 0, 0.9),
    0 0 40px -14px color-mix(in srgb, var(--accent-a) 38%, transparent),
    inset 0 1px 0 rgba(255, 255, 255, 0.15);
  overflow: hidden;
}
.cmd__top {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 14px 16px;
  border-bottom: 1px solid rgba(255, 255, 255, 0.08);
  color: var(--accent-a);
}
.cmd__top input {
  flex: 1;
  min-width: 0;
  border: none;
  outline: none;
  background: none;
  color: var(--text);
  font-size: 0.95rem;
}
.cmd__top input::placeholder {
  color: var(--text-dim);
}
.cmd__esc {
  padding: 3px 7px;
  border-radius: 6px;
  font-family: var(--font-mono);
  font-size: 0.6rem;
  color: var(--text-dim);
  background: rgba(255, 255, 255, 0.06);
  border: 1px solid rgba(255, 255, 255, 0.1);
}
.cmd__list {
  max-height: min(54vh, 380px);
  overflow-y: auto;
  padding: 8px;
}
.cmd__empty {
  padding: 34px 12px;
  text-align: center;
  font-size: 0.85rem;
  color: var(--text-dim);
}
.cmd__group + .cmd__group {
  margin-top: 8px;
}
.cmd__gname {
  padding: 6px 10px 4px;
  font-family: var(--font-mono);
  font-size: 0.6rem;
  letter-spacing: 1.4px;
  color: var(--text-dim);
}
.cmd__item {
  width: 100%;
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 9px 10px;
  border-radius: 10px;
  text-align: left;
  border: 1px solid transparent;
  transition: background 0.18s, border-color 0.18s;
}
.cmd__item.is-on {
  background: color-mix(in srgb, var(--accent-a) 12%, rgba(255, 255, 255, 0.05));
  border-color: color-mix(in srgb, var(--accent-a) 32%, transparent);
}
.cmd__ico {
  display: grid;
  place-items: center;
  width: 30px;
  height: 30px;
  flex: none;
  border-radius: 8px;
  color: var(--accent-a);
  background: rgba(255, 255, 255, 0.05);
}
.cmd__main {
  flex: 1;
  min-width: 0;
  display: flex;
  flex-direction: column;
}
.cmd__title {
  font-size: 0.88rem;
  font-weight: 600;
  color: var(--text);
}
.cmd__sub {
  font-size: 0.7rem;
  color: var(--text-dim);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}
.cmd__hint {
  font-family: var(--font-mono);
  font-size: 0.6rem;
  padding: 2px 6px;
  border-radius: 5px;
  color: var(--accent-a);
  background: color-mix(in srgb, var(--accent-a) 12%, transparent);
}
.cmd__foot {
  display: flex;
  gap: 14px;
  padding: 9px 16px;
  border-top: 1px solid rgba(255, 255, 255, 0.07);
  font-family: var(--font-mono);
  font-size: 0.6rem;
  color: var(--text-dim);
}

.cmd-enter-active,
.cmd-leave-active {
  transition: opacity 0.2s var(--ease-out);
}
.cmd-enter-active .cmd__box,
.cmd-leave-active .cmd__box {
  transition: transform 0.22s var(--ease-out), opacity 0.2s var(--ease-out);
}
.cmd-enter-from,
.cmd-leave-to {
  opacity: 0;
}
.cmd-enter-from .cmd__box,
.cmd-leave-to .cmd__box {
  opacity: 0;
  transform: translateY(-10px) scale(0.97);
}
</style>
