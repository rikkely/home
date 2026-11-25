import { ref, onMounted, onUnmounted } from 'vue'

const WEEK = ['日', '一', '二', '三', '四', '五', '六']

function pad(n) {
  return n < 10 ? '0' + n : '' + n
}

function formatUtcOffset(d) {
  const offsetMin = -d.getTimezoneOffset()
  const sign = offsetMin >= 0 ? '+' : '-'
  const abs = Math.abs(offsetMin)
  const hrs = Math.floor(abs / 60)
  const mins = abs % 60
  return mins ? `UTC${sign}${hrs}:${pad(mins)}` : `UTC${sign}${hrs}`
}

/** 实时时钟，返回拆分好的时分秒、日期、星期、秒进度与时区。 */
export function useClock() {
  const hh = ref('00')
  const mm = ref('00')
  const ss = ref('00')
  const secPct = ref(0)
  const tz = ref('UTC+8')
  const date = ref('')
  const week = ref('')
  const colon = ref(true)

  let timer = null

  const tick = () => {
    const d = new Date()
    const s = d.getSeconds()
    hh.value = pad(d.getHours())
    mm.value = pad(d.getMinutes())
    ss.value = pad(s)
    secPct.value = (s / 59) * 100
    tz.value = formatUtcOffset(d)
    colon.value = s % 2 === 0
    date.value = `${d.getFullYear()} 年 ${pad(d.getMonth() + 1)} 月 ${pad(
      d.getDate()
    )} 日`
    week.value = '星期' + WEEK[d.getDay()]
  }

  onMounted(() => {
    tick()
    timer = setInterval(tick, 1000)
  })
  onUnmounted(() => clearInterval(timer))

  return { hh, mm, ss, secPct, tz, date, week, colon }
}
