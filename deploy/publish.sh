#!/usr/bin/env bash
set -Eeuo pipefail
umask 077

[[ $(id -un) == aurora-deploy ]] || { echo '请使用 aurora-deploy 账号发布。' >&2; exit 1; }
[[ $# -eq 2 && "$2" =~ ^[0-9a-f]{40}$ ]] || { echo '参数应为项目名和完整提交 SHA。' >&2; exit 1; }
project=$1
commit=$2
case "$project" in
  home) target=/data/dist; route=/ ;;
  blog|lab|music|nav|pan|start) target="/data/$project/dist"; route="/$project/" ;;
  *) echo '不支持的项目名。' >&2; exit 1 ;;
esac
[[ -d "$target" && ! -L "$target" && -f "$target/index.html" ]] || { echo '现有前端目录不完整。' >&2; exit 1; }

# 不同仓库可能同时触发工作流，服务器统一串行处理，避免争用后端或备份。
exec 9>/home/aurora-deploy/.publish.lock
flock -w 600 9 || { echo '等待其他发布超时。' >&2; exit 1; }
work=$(mktemp -d /home/aurora-deploy/incoming/release.XXXXXX)
trap 'rm -rf -- "$work"' EXIT
mkdir "$work/payload"

# 流式接收压缩包并限制体积；解压前拒绝越界路径、链接及特殊文件。
python3 -c '
import sys
total = 0
with open(sys.argv[1], "wb") as output:
    while True:
        chunk = sys.stdin.buffer.read(1024 * 1024)
        if not chunk: break
        total += len(chunk)
        if total > 200 * 1024 * 1024: raise ValueError("Archive exceeds 200 MiB")
        output.write(chunk)
' "$work/release.tar.gz"
python3 - "$work/release.tar.gz" "$work/payload" "$project" <<'PY'
import os, pathlib, sys, tarfile
archive, destination, project = sys.argv[1:]
total = 0
seen = set()
with tarfile.open(archive, 'r:gz') as package:
    for entry in package:
        item = pathlib.PurePosixPath(entry.name)
        if item.is_absolute() or '..' in item.parts or '\\' in entry.name:
            raise ValueError('Unsafe archive path')
        if not item.parts or item.parts[0] not in (['dist', 'server', 'package.json'] if project == 'lab' else ['dist']):
            raise ValueError('Unexpected archive contents')
        if not (entry.isdir() or entry.isfile()) or item in seen:
            raise ValueError('Links, special files and duplicate paths are not allowed')
        seen.add(item)
        total += entry.size
        if total > 500 * 1024 * 1024: raise ValueError('Expanded archive exceeds 500 MiB')
        output = pathlib.Path(destination).joinpath(*item.parts)
        if entry.isdir():
            output.mkdir(parents=True, exist_ok=True)
        else:
            output.parent.mkdir(parents=True, exist_ok=True)
            with package.extractfile(entry) as source, output.open('wb') as target:
                while True:
                    chunk = source.read(1024 * 1024)
                    if not chunk: break
                    target.write(chunk)
PY
payload="$work/payload"
[[ -s "$payload/dist/index.html" && -d "$payload/dist/assets" ]] || { echo '构建产物缺少入口或资源目录。' >&2; exit 1; }
python3 - "$payload/dist" <<'PY'
import pathlib, sys
from html.parser import HTMLParser
from urllib.parse import unquote, urlsplit
root = pathlib.Path(sys.argv[1]).resolve()
class Assets(HTMLParser):
    def handle_starttag(self, tag, attrs):
        values = dict(attrs)
        value = values.get('src') if tag == 'script' else values.get('href') if tag == 'link' else None
        if not value: return
        url = urlsplit(value)
        if url.scheme or url.netloc or not url.path: return
        target = (root / unquote(url.path)).resolve()
        if root not in target.parents or not target.is_file():
            raise ValueError('Missing or unsafe asset: ' + value)
Assets().feed((root / 'index.html').read_text(encoding='utf-8'))
PY

if [[ "$project" == lab ]]; then
  [[ -f "$payload/package.json" && -f "$payload/server/index.js" ]] || { echo '后端文件不完整。' >&2; exit 1; }
  node_path=/opt/aurora-node/bin/node
  [[ -x "$node_path" ]] || node_path=$(command -v node || true)
  [[ -n "$node_path" ]] || { echo '发布账号无法执行 Node。' >&2; exit 1; }
  # 用服务器现有数据验证新版数据层，验证失败时尚未改动线上文件。
  "$node_path" --input-type=module - "$payload/server" <<'JS'
import path from 'node:path'
import { pathToFileURL } from 'node:url'
const directory = process.argv[2]
const { createLabStore } = await import(pathToFileURL(path.join(directory, 'dataStore.js')))
const { createContentStore } = await import(pathToFileURL(path.join(directory, 'contentStore.js')))
await createLabStore({ dataFile: '/data/lab/server/data/experiments.json' })
await createContentStore('/data/lab/server/data')
JS
fi

backup=$(mktemp -d "/home/aurora-deploy/backups/$project.$(date +%Y%m%d-%H%M%S).XXXXXX")
mkdir "$backup/dist"
rsync -a "$target/" "$backup/dist/"
if [[ "$project" == lab ]]; then
  mkdir "$backup/server"
  rsync -a --exclude=data/ /data/lab/server/ "$backup/server/"
  cp /data/lab/package.json "$backup/package.json"
fi
printf '%s\n' "$commit" > "$backup/incoming-commit"

restart_api() { sudo -n "$(command -v systemctl)" restart aurora-api; }
rollback() {
  failure=$1
  failed_command=${2:-'流程被中断'}
  trap - ERR INT TERM HUP
  set +e
  echo "发布失败，正在恢复；备份目录：$backup" >&2
  echo "失败步骤：$failed_command" >&2
  rollback_failed=0
  rsync -a --chmod=D755,F644 "$backup/dist/" "$target/" || rollback_failed=1
  if [[ "$project" == lab ]]; then
    rsync -a --delete --exclude=data/ --chmod=D755,F644 "$backup/server/" /data/lab/server/ || rollback_failed=1
    cp "$backup/package.json" /data/lab/package.json || rollback_failed=1
    chmod 644 /data/lab/package.json
    restart_api || rollback_failed=1
  fi
  if [[ "$rollback_failed" -eq 0 ]]; then
    echo '上一版文件已恢复，请检查服务状态和发布日志。' >&2
  else
    echo '自动恢复未完全成功，请管理员使用备份检查恢复。' >&2
  fi
  exit "$failure"
}
trap 'rollback $? "$BASH_COMMAND"' ERR
trap 'rollback 130' INT
trap 'rollback 143' TERM
trap 'rollback 129' HUP

# 保留旧版哈希资源，避免仍打开旧页面的访客请求资源时遇到 404。
rsync -a --delay-updates --chmod=D755,F644 "$payload/dist/" "$target/"
if [[ "$project" == lab ]]; then
  rsync -a --exclude=data/ --chmod=D755,F644 "$payload/server/" /data/lab/server/
  rsync -a --ignore-existing --chmod=D755,F644 "$payload/server/data/" /data/lab/server/data/
  cp "$payload/package.json" /data/lab/package.json
  chmod 644 /data/lab/package.json
  restart_api
  healthy=0
  for attempt in {1..15}; do
    if curl -fsS --max-time 3 http://127.0.0.1:8787/api/health > "$work/health.json"; then
      if python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); sys.exit(0 if d.get("ok") is True and d.get("service")=="aurora-site-api" else 1)' "$work/health.json"; then
        healthy=1
        break
      fi
    fi
    sleep 1
  done
  [[ "$healthy" -eq 1 ]]
fi

# 直接经过本机 HTTPS 虚拟主机验收，保留证书验证，避免 CDN 缓存误报。
curl -fsS --connect-timeout 5 --max-time 15 --resolve rikkely.top:443:127.0.0.1 \
  "https://rikkely.top${route}?deploy=$commit" > "$work/served.html"
cmp -s "$payload/dist/index.html" "$work/served.html"
if [[ "$project" == lab ]]; then
  for endpoint in health lab/experiments nav/categories music/playlist 'pan/list?path=/'; do
    curl -fsS --max-time 10 --resolve rikkely.top:443:127.0.0.1 "https://rikkely.top/api/$endpoint" > "$work/api.json"
    python3 -c 'import json,sys; json.load(open(sys.argv[1]))' "$work/api.json"
  done
fi
trap - ERR INT TERM HUP
echo "发布成功：$project $commit；上一版备份：$backup"
