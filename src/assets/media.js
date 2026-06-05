/**
 * 自动收集打包资源：
 *  - 背景图：把 src/assets/images/bg/ 下的图片作为默认轮播背景
 *  - 社交图标：src/assets/images/icon/ 下的 png/svg，按文件名索引
 *
 * 想加背景图 / 图标，直接往对应目录丢文件即可，无需改代码。
 */

const bgGlob = import.meta.glob('./images/bg/*.{webp,avif,jpg,jpeg,png}', {
  eager: true,
  query: '?url',
  import: 'default'
})

const iconGlob = import.meta.glob('./images/icon/*.{png,svg}', {
  eager: true,
  query: '?url',
  import: 'default'
})

// 让 background2 排在 background10 之前
function naturalSort(a, b) {
  return a.localeCompare(b, undefined, { numeric: true, sensitivity: 'base' })
}

export const bundledBackgrounds = Object.keys(bgGlob)
  .sort(naturalSort)
  .map((k) => bgGlob[k])

export const socialIcons = Object.fromEntries(
  Object.entries(iconGlob).map(([path, url]) => [
    path.split('/').pop().replace(/\.\w+$/, ''),
    url
  ])
)
