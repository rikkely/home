# Aurora Home · 个人主页

一个原创的玻璃拟态（Glassmorphism）个人主页 / 导航页。纯前端，`npm run build` 后产出 `dist/`，丢到任意静态服务器即可运行。

特性：

- 🌀 **进场加载动画** —— 手绘式自描边 Logo + 进度条，加载完成后缩放淡出，主界面错落浮现。
- 🌌 **循环切换背景** —— 多场景交叉淡入 + 缓慢 Ken-Burns 缩放 + 鼠标视差；内置极光渐变场景，零外部图片也好看，也可换成自己的图片。
- 🧊 **毛玻璃便当卡片**（Bento Grid）—— 个人信息 / 时钟 / 天气 / 一言 / 网站导航 / 时光胶囊。
- 🪄 **3D 倾斜** —— 卡片随鼠标倾斜并带高光，自动尊重「减少动态效果」与触摸屏。
- 🌦 **天气接入 API** —— 内置 4 种数据源（wttr / OpenWeather / 和风 / 高德），均可配置 Key，默认免 Key 开箱即用。

## 开发 & 构建

```bash
npm install      # 安装依赖
npm run dev      # 本地开发（默认 http://localhost:5173）
npm run build    # 产出 dist/
npm run preview  # 本地预览构建产物
```

部署：把 `dist/` 整个目录上传到任意静态托管（Nginx / Vercel / Netlify / GitHub Pages / 对象存储 等）即可。`vite.config.js` 中 `base: './'` 使其支持任意子路径。

## 配置（你主要改这一个文件）

几乎所有个性化内容都在 [`src/config.js`](src/config.js)：

| 区块          | 作用                                                        |
| ------------- | ----------------------------------------------------------- |
| `site`        | 昵称、后缀、头像、问候语、简介、加载副标题                  |
| `footer`      | 建站年份、署名、ICP 备案号                                  |
| `socials`     | 介绍卡下方的社交图标与链接                                  |
| `links`       | 「网站列表」导航项                                          |
| `background`  | 切换间隔；`images` 填网络图片地址（留空则用打包进来的本地图片） |
| `weather`     | 天气数据源与 Key（见下）                                    |
| `hitokoto`    | 一言开关与接口                                              |
| `theme`       | 极光主题三色（青 / 紫 / 粉）                                |

### 头像

默认使用 `src/assets/images/avatar.png`，换头像直接替换这个文件即可（`config.js` 顶部已 `import`）。
也可以把 `site.avatar` 改成网络图片地址字符串。

### 背景图

背景默认自动收集 `src/assets/images/bg/` 目录下的所有图片（`*.webp/jpg/png` 等），
**往这个目录丢图 / 删图就能增减背景，无需改代码**。
如果想用网络图片，在 `config.background.images` 填地址数组即可（优先级最高）；
两者都为空时回退到内置的极光渐变场景。

### 字体

`src/assets/fonts/` 下放了两款字体并已在 `src/styles/global.css` 里 `@font-face`：

- **Pacifico** —— 站点名 / 加载页标题的手写体（CSS 变量 `--font-brand`）
- **UnidreamLED** —— 时钟的 7 段数码体（CSS 变量 `--font-led`）

换字体时替换文件并改 `global.css` 里的 `@font-face` 与变量即可。

### 天气

在 `config.weather.provider` 选择数据源：

| provider      | 是否需要 Key | 额外字段                                  |
| ------------- | ------------ | ----------------------------------------- |
| `wttr`        | 否（默认）   | `city`（英文城市名，如 `Shanghai`）       |
| `openweather` | 是 `apiKey`  | `city`                                    |
| `qweather`    | 是 `apiKey`  | `location`（`经度,纬度` 或 LocationID）   |
| `amap`        | 是 `apiKey`  | `cityCode`（adcode，如上海 `310000`）     |
| `none`        | —            | 关闭天气，显示占位                        |

`cityName` 是界面上显示的中文地名（如 `上海市`），与请求参数无关。
任何请求失败都会优雅降级为占位文案，不会白屏。

> 提示：和风天气 / 高德返回的天气状况本身就是中文；wttr.in 默认英文，已内置常见状况的中英映射。

## 图标

分两套：

- **社交图标**（介绍卡）：用 `src/assets/images/icon/` 里的白色 PNG，按文件名引用。
  现有：`github / bilibili / email / gitee / qq / telegram / twitter / music`。
  往该目录丢同名 PNG 即可新增；`socials[].icon` 找不到对应 PNG 时会自动回退到下面的矢量图标。
- **矢量图标**（导航 / 天气 / 时钟等 UI）：在 [`src/components/IconBase.vue`](src/components/IconBase.vue) 中以内联 SVG 维护。
  `links` 可用：`rss / cloud / music / compass / bookmark / flask / grid / link`。
  需要新图标时，往该文件的 `stroke`（描边）或 `fill`（填充）里加一条 path 即可。

## 技术栈

Vue 3 + Vite。无 UI 库、无运行时网络字体依赖，构建产物约 35 KB（gzip）。
