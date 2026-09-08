#!/usr/bin/env bash
set -Eeuo pipefail

[[ ${EUID} -eq 0 ]] || { echo '请使用 root 执行安装脚本。' >&2; exit 1; }
for tool in rsync curl tar python3 flock sudo visudo systemctl useradd getent install; do
  command -v "$tool" >/dev/null || { echo "缺少命令：$tool，请先安装对应系统软件包。" >&2; exit 1; }
done

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
[[ -f "$script_dir/publish.sh" ]] || { echo '请把 install.sh 和 publish.sh 放在同一目录。' >&2; exit 1; }

# 仅接管已经存在的站点目录，防止路径拼错后发布到空目录。
targets=(/data/dist /data/blog/dist /data/lab/dist /data/music/dist /data/nav/dist /data/pan/dist /data/start/dist)
for target in "${targets[@]}"; do
  [[ -d "$target" && ! -L "$target" && -f "$target/index.html" ]] || {
    echo "请确认现有前端目录：$target（本脚本不自动迁移符号链接）。" >&2
    exit 1
  }
done
[[ -f /data/lab/server/index.js && -f /data/lab/package.json && -d /data/lab/server/data ]] || {
  echo '请先在 /data/lab 部署并启动共享后端。' >&2; exit 1;
}
[[ ! -L /data/lab/server && ! -L /data/lab/package.json ]] || { echo '请先检查后端目录的符号链接。' >&2; exit 1; }

if ! id aurora-deploy >/dev/null 2>&1; then
  useradd --create-home --user-group --shell /bin/bash aurora-deploy
fi
deploy_home=$(getent passwd aurora-deploy | cut -d: -f6)
[[ "$deploy_home" == /home/aurora-deploy ]] || { echo 'aurora-deploy 的主目录应为 /home/aurora-deploy。' >&2; exit 1; }
for parent in /data /data/blog /data/lab /data/music /data/nav /data/pan /data/start; do
  sudo -u aurora-deploy test -x "$parent" || {
    echo "发布账号无法进入 $parent，请管理员检查该目录的通行权限。" >&2; exit 1;
  }
done
install -d -m 700 -o aurora-deploy -g aurora-deploy "$deploy_home/.ssh" "$deploy_home/backups" "$deploy_home/incoming"
touch "$deploy_home/.ssh/authorized_keys"
chown aurora-deploy:aurora-deploy "$deploy_home/.ssh/authorized_keys"
chmod 600 "$deploy_home/.ssh/authorized_keys"

# 后端仅从 JSON 读取内容；所有权交给发布账号后仍保留服务和 Nginx 的读取权限。
for target in "${targets[@]}" /data/lab/server; do
  chown -R aurora-deploy:aurora-deploy "$target"
  find "$target" -type d -exec chmod 755 {} +
  find "$target" -type f -exec chmod 644 {} +
done
chown aurora-deploy:aurora-deploy /data/lab/package.json
chmod 644 /data/lab/package.json

install -m 755 "$script_dir/publish.sh" /usr/local/bin/aurora-publish
systemctl_path=$(command -v systemctl)
sudoers_tmp=$(mktemp)
trap 'rm -f -- "$sudoers_tmp"' EXIT
printf 'Defaults:aurora-deploy !requiretty\naurora-deploy ALL=(root) NOPASSWD: %s restart aurora-api\n' "$systemctl_path" > "$sudoers_tmp"
visudo -cf "$sudoers_tmp"
install -m 440 "$sudoers_tmp" /etc/sudoers.d/aurora-deploy

echo '安装完成。接下来添加部署公钥，并在七个 GitHub 仓库配置 Secrets 和 DEPLOY_ENABLED。'
echo '脚本没有修改 Nginx、SSH 服务配置，也没有启动发布。'
