import { ref, onMounted } from 'vue'
import config from '../config.js'

const FALLBACK = [
  { text: '我们的情人，不过是随便借个名字，用幻想吹出来的肥皂泡。', from: '大鼻子情圣' },
  { text: '心之所向，素履以往；生如逆旅，一苇以航。', from: '愿你历尽千帆' },
  { text: '比起未知的迷茫，我更害怕的是停在原地。', from: '佚名' },
  { text: '星河滚烫，你是人间理想。', from: '银河系漫游指南' }
]

/** 一言。失败时回退到内置语录，并支持点击刷新。 */
export function useHitokoto() {
  const text = ref('')
  const from = ref('')
  const loading = ref(false)

  const useFallback = () => {
    const q = FALLBACK[Math.floor(Math.random() * FALLBACK.length)]
    text.value = q.text
    from.value = q.from
  }

  const fetchQuote = async () => {
    if (!config.hitokoto?.enabled) {
      useFallback()
      return
    }
    loading.value = true
    try {
      const res = await fetch(config.hitokoto.api || 'https://v1.hitokoto.cn/')
      if (!res.ok) throw new Error('bad status')
      const data = await res.json()
      text.value = data.hitokoto || ''
      from.value = data.from || data.from_who || ''
      if (!text.value) useFallback()
    } catch (e) {
      useFallback()
    } finally {
      loading.value = false
    }
  }

  onMounted(fetchQuote)

  return { text, from, loading, refresh: fetchQuote }
}
