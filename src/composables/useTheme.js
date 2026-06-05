import { ref } from 'vue'
import config from '../config.js'

const t = config.theme || {}

// 三套 HUD 配色（青 / 红 / 绿）。a/b/c 会写入 CSS 变量，全站联动。
// 默认「青」取自 config.js 的 theme，可在那里自定义。
export const PALETTES = {
  cyan: {
    label: 'CYAN',
    a: t.accentA || '#67e8f9',
    b: t.accentB || '#a78bfa',
    c: t.accentC || '#f472b6'
  },
  red: { label: 'RED', a: '#ff5d6c', b: '#ff8e53', c: '#ffd166' },
  green: { label: 'GREEN', a: '#34d399', b: '#a3e635', c: '#22d3ee' }
}

const KEY = 'hud-theme'
const active = ref('cyan')

function apply(name) {
  const p = PALETTES[name] || PALETTES.cyan
  const s = document.documentElement.style
  s.setProperty('--accent-a', p.a)
  s.setProperty('--accent-b', p.b)
  s.setProperty('--accent-c', p.c)
  active.value = name
  try {
    localStorage.setItem(KEY, name)
  } catch (e) {
    /* ignore */
  }
}

export function useTheme() {
  const init = () => {
    let saved = null
    try {
      saved = localStorage.getItem(KEY)
    } catch (e) {
      /* ignore */
    }
    apply(saved && PALETTES[saved] ? saved : 'cyan')
  }
  return { active, palettes: PALETTES, setTheme: apply, initTheme: init }
}
