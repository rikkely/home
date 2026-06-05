import { ref, onMounted, onUnmounted } from 'vue'

function clampPct(v) {
  return Math.min(100, Math.max(0, v))
}

/**
 * 「时光胶囊」—— 今天 / 本周 / 本月 / 今年 已流逝的百分比与文案。
 */
export function useTimeCapsule() {
  const items = ref([])
  let timer = null

  const compute = () => {
    const now = new Date()

    // 今天
    const startDay = new Date(now.getFullYear(), now.getMonth(), now.getDate())
    const dayPct = ((now - startDay) / 86400000) * 100

    // 本周（周一为起点）
    const day = (now.getDay() + 6) % 7 // 0 = Mon
    const startWeek = new Date(startDay)
    startWeek.setDate(startDay.getDate() - day)
    const weekPct = ((now - startWeek) / (7 * 86400000)) * 100

    // 本月
    const startMonth = new Date(now.getFullYear(), now.getMonth(), 1)
    const startNextMonth = new Date(now.getFullYear(), now.getMonth() + 1, 1)
    const monthPct = ((now - startMonth) / (startNextMonth - startMonth)) * 100

    // 今年
    const startYear = new Date(now.getFullYear(), 0, 1)
    const startNextYear = new Date(now.getFullYear() + 1, 0, 1)
    const yearPct = ((now - startYear) / (startNextYear - startYear)) * 100

    items.value = [
      { label: `今天已经度过了 ${now.getHours()} 小时`, pct: clampPct(dayPct) },
      { label: `本周已经度过了 ${day} 天`, pct: clampPct(weekPct) },
      { label: `本月已经度过了 ${now.getDate() - 1} 天`, pct: clampPct(monthPct) },
      { label: `今年已经度过了 ${now.getMonth()} 个月`, pct: clampPct(yearPct) }
    ]
  }

  onMounted(() => {
    compute()
    timer = setInterval(compute, 60000)
  })
  onUnmounted(() => clearInterval(timer))

  return { items }
}
