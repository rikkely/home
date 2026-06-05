import { ref, onMounted, onUnmounted } from 'vue'

const WEEK = ['日', '一', '二', '三', '四', '五', '六']

function pad(n) {
  return n < 10 ? '0' + n : '' + n
}

/** 实时时钟，返回拆分好的时分秒、日期与星期。 */
export function useClock() {
  const hh = ref('00')
  const mm = ref('00')
  const ss = ref('00')
  const date = ref('')
  const week = ref('')
  const colon = ref(true)

  let timer = null

  const tick = () => {
    const d = new Date()
    hh.value = pad(d.getHours())
    mm.value = pad(d.getMinutes())
    ss.value = pad(d.getSeconds())
    colon.value = d.getSeconds() % 2 === 0
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

  return { hh, mm, ss, date, week, colon }
}
