/**
 * ============================================================
 *  站点配置 —— 你需要修改的几乎都在这个文件里
 * ============================================================
 *  改完后 `npm run build`，把 dist/ 丢到任意静态服务器即可。
 */

// 头像：放在 src/assets/images/avatar.png，换图直接替换该文件；
// 也可改成网络地址字符串，如 avatar: 'https://...'
import avatar from './assets/images/avatar.png'

export default {
  /* ---------------- 基本信息 ---------------- */
  site: {
    name: 'rikkely',          // 站点 / 昵称
    suffix: '.top',           // 名字后缀（小字），不需要可留空 ''
    avatar,                   // 见文件顶部 import
    hello: 'Hello, World !',  // 介绍卡标题
    description: '一个建立于 21 世纪的小站，存活于互联网的边缘。',
    // 顶部加载动画里显示的副标题
    loadingText: '正在唤醒核心…'
  },

  /* ---------------- 页脚 ---------------- */
  footer: {
    startYear: 2023,          // 建站年份
    author: 'rikkely',        // 署名
    icp: '',                  // 备案号，例如 '沪ICP备2023022234号-1'，没有可留空
    icpLink: 'https://beian.miit.gov.cn/'
  },

  /* ---------------- 社交图标（介绍卡下方） ---------------- */
  // icon 用 src/assets/images/icon/ 里的文件名（白色 PNG）：
  //   github / bilibili / email / gitee / qq / telegram / twitter / music
  // 也可用内置矢量图标名（rss / link 等），找不到 PNG 时会自动回退到矢量图标
  socials: [
    { icon: 'github', name: 'GitHub', url: 'https://github.com/rikkely' },
    { icon: 'bilibili', name: '哔哩哔哩', url: 'https://space.bilibili.com/98544142' },
    { icon: 'email', name: '邮箱', url: 'mailto:hi@example.com' },
    { icon: 'qq', name: 'QQ', url: 'https://res.abeim.cn/api/qq/?qq=1979107840' }
  ],

  /* ---------------- 导航 / 网站列表 ---------------- */
  // icon 可选: rss / cloud / music / compass / bookmark / flask / grid / link
  links: [
    { icon: 'rss', name: '博客', desc: '记录与分享', url: '/blog/' },
    { icon: 'cloud', name: '网盘', desc: '文件与资源', url: '/pan/' },
    { icon: 'music', name: '音乐', desc: '听过的歌', url: '/music/' },
    { icon: 'compass', name: '起始页', desc: '我的导航', url: '/start/' },
    { icon: 'bookmark', name: '网址集', desc: '收藏夹', url: '/nav/' },
    { icon: 'flask', name: '实验室', desc: '一些尝试', url: '/lab/' }
  ],

  /* ---------------- 背景 ---------------- */
  background: {
    // 切换间隔（毫秒）
    interval: 11000,
    // 默认使用 src/assets/images/bg/ 下打包的图片（往里丢图即可增减）。
    // 若在这里填网络图片地址，则优先使用这里的列表；
    // 两者都为空时回退到内置极光渐变场景。
    images: [
      // 'https://your-cdn.com/bg1.jpg',
    ]
  },

  /* ---------------- 天气 ---------------- */
  // provider 可选:
  //   'wttr'       —— 免费、无需 key，开箱即用（默认）
  //   'openweather'—— 需要 apiKey，国际通用
  //   'qweather'   —— 和风天气，需要 apiKey + location(经度,纬度 或 LocationID)
  //   'amap'       —— 高德，需要 apiKey(Web服务) + cityCode(adcode)
  //   'none'       —— 关闭，显示占位文案
  weather: {
    provider: 'wttr',
    apiKey: '',
    city: 'Shanghai',         // wttr / openweather 用城市名
    cityName: '上海市',        // 界面上显示的中文地名
    location: '121.47,31.23', // qweather 用 "经度,纬度" 或 LocationID
    cityCode: '310000'        // amap 用 adcode
  },

  /* ---------------- 一言 ---------------- */
  hitokoto: {
    enabled: true,
    // 留空使用官方随机分类；详见 https://developer.hitokoto.cn/sentence/
    api: 'https://v1.hitokoto.cn/'
  },

  /* ---------------- 主题色（极光渐变） ---------------- */
  theme: {
    accentA: '#67e8f9', // 青
    accentB: '#a78bfa', // 紫
    accentC: '#f472b6'  // 粉
  }
}
