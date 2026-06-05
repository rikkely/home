import { ref, onMounted } from 'vue'
import config from '../config.js'

/** 把天气文案粗略映射到图标名（IconBase 里已有这些图标）。 */
function pickIcon(text = '') {
  const t = String(text).toLowerCase()
  if (/(雨|雷|drizzle|rain|thunder|shower)/.test(t)) return 'cloud-rain'
  if (/(雪|sleet|snow)/.test(t)) return 'cloud-rain'
  if (/(云|阴|雾|霾|cloud|overcast|fog|mist|haze)/.test(t)) return 'cloud'
  if (/(风|wind)/.test(t)) return 'wind'
  if (/(夜|晚|night|clear.*night)/.test(t)) return 'moon'
  return 'sun'
}

// wttr.in 默认返回英文天气，这里做一个常见状况的中文映射
const WTTR_ZH = {
  sunny: '晴',
  clear: '晴',
  'partly cloudy': '多云',
  cloudy: '多云',
  overcast: '阴',
  mist: '薄雾',
  fog: '雾',
  freezing: '冰冻',
  'patchy rain possible': '局部有雨',
  'patchy rain nearby': '附近有雨',
  'patchy light rain': '小雨',
  'light rain': '小雨',
  'light drizzle': '毛毛雨',
  'patchy light drizzle': '零星小雨',
  'moderate rain': '中雨',
  'heavy rain': '大雨',
  'light rain shower': '阵雨',
  'torrential rain shower': '暴雨',
  'patchy snow possible': '局部有雪',
  'light snow': '小雪',
  'moderate snow': '中雪',
  'heavy snow': '大雪',
  'thundery outbreaks possible': '可能有雷阵雨',
  'thundery outbreaks in nearby': '附近有雷阵雨'
}
function toZh(text = '') {
  return WTTR_ZH[text.trim().toLowerCase()] || text
}

const adapters = {
  /* wttr.in —— 免费无 key，含逐时温度与湿度 */
  async wttr({ city }) {
    const res = await fetch(
      `https://wttr.in/${encodeURIComponent(city)}?format=j1&lang=zh`
    )
    const data = await res.json()
    const cur = data.current_condition?.[0] || {}
    const raw = cur.lang_zh?.[0]?.value || cur.weatherDesc?.[0]?.value || ''
    const hourly = data.weather?.[0]?.hourly || []
    return {
      desc: toZh(raw) || '未知',
      temp: cur.temp_C != null ? `${cur.temp_C}℃` : '',
      tempNum: cur.temp_C != null ? Number(cur.temp_C) : null,
      wind:
        cur.winddir16Point && cur.windspeedKmph
          ? `${cur.winddir16Point} ${cur.windspeedKmph}km/h`
          : '',
      humidity: cur.humidity != null ? Number(cur.humidity) : null,
      series: hourly.map((h) => Number(h.tempC)).filter((n) => !Number.isNaN(n))
    }
  },

  async openweather({ city, apiKey }) {
    const res = await fetch(
      `https://api.openweathermap.org/data/2.5/weather?q=${encodeURIComponent(
        city
      )}&appid=${apiKey}&units=metric&lang=zh_cn`
    )
    const d = await res.json()
    return {
      desc: d.weather?.[0]?.description || '未知',
      temp: d.main?.temp != null ? `${Math.round(d.main.temp)}℃` : '',
      tempNum: d.main?.temp != null ? Math.round(d.main.temp) : null,
      wind: d.wind?.speed != null ? `风速 ${d.wind.speed}m/s` : '',
      humidity: d.main?.humidity ?? null,
      series: []
    }
  },

  async qweather({ location, apiKey }) {
    const res = await fetch(
      `https://devapi.qweather.com/v7/weather/now?location=${location}&key=${apiKey}`
    )
    const d = await res.json()
    const now = d.now || {}
    return {
      desc: now.text || '未知',
      temp: now.temp != null ? `${now.temp}℃` : '',
      tempNum: now.temp != null ? Number(now.temp) : null,
      wind: now.windDir && now.windScale ? `${now.windDir} ${now.windScale}级` : '',
      humidity: now.humidity != null ? Number(now.humidity) : null,
      series: []
    }
  },

  async amap({ cityCode, apiKey }) {
    const res = await fetch(
      `https://restapi.amap.com/v3/weather/weatherInfo?key=${apiKey}&city=${cityCode}&extensions=base`
    )
    const d = await res.json()
    const live = d.lives?.[0] || {}
    return {
      desc: live.weather || '未知',
      temp: live.temperature != null ? `${live.temperature}℃` : '',
      tempNum: live.temperature != null ? Number(live.temperature) : null,
      wind:
        live.winddirection && live.windpower
          ? `${live.winddirection}风 ${live.windpower}级`
          : '',
      humidity: live.humidity != null ? Number(live.humidity) : null,
      series: []
    }
  }
}

export function useWeather() {
  const cityName = ref(config.weather?.cityName || '')
  const desc = ref('')
  const temp = ref('')
  const tempNum = ref(null)
  const wind = ref('')
  const humidity = ref(null)
  const series = ref([])
  const icon = ref('sun')
  const ready = ref(false)
  const error = ref(false)

  const load = async () => {
    const cfg = config.weather || {}
    const adapter = adapters[cfg.provider]
    if (!adapter) {
      desc.value = '在 config.js 配置天气'
      ready.value = true
      return
    }
    try {
      const r = await adapter(cfg)
      desc.value = r.desc
      temp.value = r.temp
      tempNum.value = r.tempNum
      wind.value = r.wind
      humidity.value = r.humidity
      series.value = r.series || []
      icon.value = pickIcon(r.desc)
      ready.value = true
    } catch (e) {
      error.value = true
      desc.value = '天气暂不可用'
      ready.value = true
    }
  }

  onMounted(load)

  return { cityName, desc, temp, tempNum, wind, humidity, series, icon, ready, error, reload: load }
}
