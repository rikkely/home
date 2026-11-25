import { ref } from 'vue'
import config from '../config.js'

const t = config.theme || {}

// 四套 HUD 配色（极光青 / 星云紫 / 矩阵绿 / 日冕金）。a/b/c 会写入 CSS 变量，全站联动。
export const PALETTES = {
  cyan: {
    label: '极光青',
    code: 'AURORA',
    a: t.accentA || '#67e8f9',
    b: t.accentB || '#a78bfa',
    c: t.accentC || '#f472b6'
  },
  violet: {
    label: '星云紫',
    code: 'NEBULA',
    a: '#818cf8',
    b: '#c084fc',
    c: '#38bdf8'
  },
  emerald: {
    label: '矩阵绿',
    code: 'MATRIX',
    a: '#34d399',
    b: '#2dd4bf',
    c: '#a3e635'
  },
  amber: {
    label: '日冕金',
    code: 'SOLAR',
    a: '#fbbf24',
    b: '#fb7185',
    c: '#f97316'
  }
}

const LEGACY_MAP = {
  red: 'amber',
  green: 'emerald'
}

const KEY = 'hud-theme'
const active = ref('cyan')

function apply(name) {
  const resolved = LEGACY_MAP[name] || name
  const p = PALETTES[resolved] || PALETTES.cyan
  const finalKey = PALETTES[resolved] ? resolved : 'cyan'
  const s = document.documentElement.style
  s.setProperty('--accent-a', p.a)
  s.setProperty('--accent-b', p.b)
  s.setProperty('--accent-c', p.c)
  active.value = finalKey
  try {
    localStorage.setItem(KEY, finalKey)
  } catch {
    /* ignore */
  }
}

export function useTheme() {
  const init = () => {
    let saved = null
    try {
      saved = localStorage.getItem(KEY)
    } catch {
      /* ignore */
    }
    const mapped = saved ? (LEGACY_MAP[saved] || saved) : 'cyan'
    apply(PALETTES[mapped] ? mapped : 'cyan')
  }
  return { active, palettes: PALETTES, setTheme: apply, initTheme: init }
}
