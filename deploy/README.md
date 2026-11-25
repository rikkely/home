# 服务器端 GitHub 自动拉取打包更新脚本指南

[`sync-from-github.sh`](./sync-from-github.sh) 直接部署在你的 Linux 服务器上，用于自动检查 GitHub 7 个仓库的最新提交、拉取代码、按需安装依赖、`vite build` 打包，并无缝原子更新到 `/data` 目录下对应的 Nginx 站点目录。

## 对应服务器目录映射

| 项目 | GitHub 仓库 | 部署目录 | 访问路由 |
| --- | --- | --- | --- |
| `home` | `rikkely/home` | `/data/dist` | `/` |
| `blog` | `rikkely/blog` | `/data/blog/dist` | `/blog/` |
| `lab` | `rikkely/lab` | `/data/lab/dist`（并同步 `server/` 与重启 `aurora-api`） | `/lab/` & `/api/` |
| `music` | `rikkely/music` | `/data/music/dist` | `/music/` |
| `nav` | `rikkely/nav` | `/data/nav/dist` | `/nav/` |
| `pan` | `rikkely/pan` | `/data/pan/dist` | `/pan/` |
| `start` | `rikkely/start` | `/data/start/dist` | `/start/` |

## 服务器一键安装与使用

确保服务器已安装 `git`、`node`（Node 18+）、`npm`、`rsync`。在服务器上执行：

```bash
# 1. 从 GitHub 下载脚本并安装为全局命令 aurora-sync
curl -fsSL https://raw.githubusercontent.com/rikkely/home/main/deploy/sync-from-github.sh -o /tmp/aurora-sync
sudo install -m 755 /tmp/aurora-sync /usr/local/bin/aurora-sync
rm -f /tmp/aurora-sync
```

### 常用命令

```bash
# 查看 7 个项目当前的本地版本 vs GitHub 远程版本
aurora-sync --status

# 检查全部 7 个项目（仅当有新提交时才拉取、打包、部署）
sudo aurora-sync

# 仅更新指定的几个子站
sudo aurora-sync blog music

# 强制全部重新打包并部署（即使提交 SHA 未变化）
sudo aurora-sync --force

# 回滚某个项目到上一次备份
sudo aurora-sync --rollback blog
```

## 开启定时自动更新（Systemd Timer）

安装后每 5 分钟（可自定义分钟数）自动检测 GitHub 新提交并部署，无需额外配置 Webhook 或 GitHub Actions：

```bash
# 每 5 分钟自动检查并同步一次
sudo aurora-sync --install-timer 5

# 查看运行日志
journalctl -u aurora-sync -n 50 --no-pager

# 如需卸载定时任务
sudo aurora-sync --remove-timer
```

## 可选环境变量（代理 / 镜像）

如果服务器位于国内直连 GitHub 较慢，可在执行前设置代理，或写入 `/etc/systemd/system/aurora-sync.service` 的 `[Service]` 段：

```bash
HTTPS_PROXY=http://127.0.0.1:7890 sudo -E aurora-sync
```

## 附：Nginx 静态路径优化提示

当前 Nginx 中的写法：

```nginx
location /blog/ {
    root /data;
    rewrite ^/blog/(.*)$ /blog/dist/$1 break;
    try_files $uri $uri/ /blog/index.html;
}
```

如果访问子路径刷新时偶尔出现路由回退异常，也可简化为 `alias`（`try_files` 指向自身或目录即可，无二次重写风险）：

```nginx
location /blog/ {
    alias /data/blog/dist/;
    index index.html;
    try_files $uri $uri/ /blog/index.html;
}
```
