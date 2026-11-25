#!/usr/bin/env bash
set -Eeuo pipefail

# ==============================================================================
# Aurora Suite · GitHub 自动拉取 / 构建 / 无缝发布脚本
# 适配 rikkely.top 的 Nginx + /data 目录结构：
#   home  -> /data/dist        (/)
#   blog  -> /data/blog/dist   (/blog/)
#   lab   -> /data/lab/dist    (/lab/ + /data/lab/server + aurora-api)
#   music -> /data/music/dist  (/music/)
#   nav   -> /data/nav/dist    (/nav/)
#   pan   -> /data/pan/dist    (/pan/)
#   start -> /data/start/dist  (/start/)
# ==============================================================================

GITHUB_OWNER="${GITHUB_OWNER:-rikkely}"
GITHUB_BRANCH="${GITHUB_BRANCH:-main}"
GITHUB_BASE_URL="${GITHUB_BASE_URL:-https://github.com}"
DATA_ROOT="${DATA_ROOT:-/data}"
WORK_ROOT="${WORK_ROOT:-${DATA_ROOT}/.aurora-sync}"
API_SERVICE="${API_SERVICE:-aurora-api}"
API_HEALTH_URL="${API_HEALTH_URL:-http://127.0.0.1:8787/api/health}"
DOMAIN="${DOMAIN:-rikkely.top}"
KEEP_BACKUPS="${KEEP_BACKUPS:-3}"

ALL_PROJECTS=(home blog lab music nav pan start)

log()  { printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*"; }
warn() { printf '[%s] [警告] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >&2; }
die()  { printf '[%s] [错误] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >&2; exit 1; }

setup_path() {
  local extra=()
  for d in /opt/aurora-node/bin /usr/local/bin; do
    [[ -d "$d" ]] && extra+=("$d")
  done
  local nvm_dir
  for nvm_base in "${HOME:-}" /root; do
    [[ -n "$nvm_base" && -d "$nvm_base/.nvm/versions/node" ]] || continue
    nvm_dir=$(ls -1d "$nvm_base/.nvm/versions/node/"*/bin 2>/dev/null | sort -V | tail -n 1 || true)
    [[ -n "$nvm_dir" && -d "$nvm_dir" ]] && extra+=("$nvm_dir")
  done
  if ((${#extra[@]})); then
    local joined
    joined=$(IFS=:; echo "${extra[*]}")
    export PATH="${joined}:$PATH"
  fi
}

usage() {
  cat <<EOF
用法: $(basename "$0") [选项] [项目名...]

支持的项目名: home blog lab music nav pan start（不传则检查全部 7 个项目）

选项:
  -f, --force               即使 GitHub 提交 SHA 未变化也强制重新打包发布
  -s, --status              查看各项目远程最新提交与本地已发布提交状态
      --rollback <项目>     将指定项目回滚到最近一次本地备份
      --install-timer [分]  安装 systemd 定时任务（默认每 5 分钟自动检查更新，需 root）
      --remove-timer        卸载 systemd 定时任务（需 root）
  -h, --help                显示本帮助信息

常用环境变量:
  GITHUB_OWNER=${GITHUB_OWNER}
  GITHUB_BRANCH=${GITHUB_BRANCH}
  GITHUB_BASE_URL=${GITHUB_BASE_URL}
  DATA_ROOT=${DATA_ROOT}
  WORK_ROOT=${WORK_ROOT}
  KEEP_BACKUPS=${KEEP_BACKUPS}
  HTTPS_PROXY / HTTP_PROXY  （国内服务器如需代理拉 GitHub 可设置）
EOF
}

is_valid_project() {
  local p="$1" item
  for item in "${ALL_PROJECTS[@]}"; do
    [[ "$p" == "$item" ]] && return 0
  done
  return 1
}

target_dir_of() {
  local p="$1"
  if [[ "$p" == "home" ]]; then
    printf '%s/dist' "$DATA_ROOT"
  else
    printf '%s/%s/dist' "$DATA_ROOT" "$p"
  fi
}

repo_url_of() {
  printf '%s/%s/%s.git' "${GITHUB_BASE_URL%/}" "$GITHUB_OWNER" "$1"
}

require_tools() {
  local t
  for t in "$@"; do
    command -v "$t" >/dev/null 2>&1 || die "缺少命令：$t，请先安装对应软件包。"
  done
}

remote_sha_of() {
  local url
  url=$(repo_url_of "$1")
  git ls-remote "$url" "refs/heads/${GITHUB_BRANCH}" 2>/dev/null | awk 'NR==1 {print $1}'
}

local_sha_of() {
  local f="${WORK_ROOT}/state/$1.sha"
  [[ -f "$f" ]] && tr -d '[:space:]' < "$f" || true
}

show_status() {
  require_tools git awk
  printf '%-8s %-12s %-12s %s\n' "PROJECT" "DEPLOYED" "REMOTE" "TARGET"
  local p local_sha remote_sha target
  for p in "${ALL_PROJECTS[@]}"; do
    local_sha=$(local_sha_of "$p")
    remote_sha=$(remote_sha_of "$p" || true)
    target=$(target_dir_of "$p")
    printf '%-8s %-12s %-12s %s\n' \
      "$p" \
      "${local_sha:0:10}" \
      "${remote_sha:0:10}" \
      "$target"
  done
}

acquire_lock() {
  mkdir -p "$WORK_ROOT"
  exec 9>"${WORK_ROOT}/sync.lock"
  flock -w 300 9 || die "等待其他同步任务超时（${WORK_ROOT}/sync.lock）。"
}

prune_backups() {
  local p="$1"
  local bdir="${WORK_ROOT}/backups/${p}"
  [[ -d "$bdir" ]] || return 0
  local count=0 d
  while IFS= read -r d; do
    [[ -n "$d" ]] || continue
    count=$((count + 1))
    if (( count > KEEP_BACKUPS )); then
      rm -rf -- "$d"
    fi
  done < <(ls -1dt "$bdir"/*/ 2>/dev/null || true)
}

backup_project() {
  local p="$1"
  local target
  target=$(target_dir_of "$p")
  local stamp bpath
  stamp=$(date '+%Y%m%d-%H%M%S')
  bpath="${WORK_ROOT}/backups/${p}/${stamp}"
  mkdir -p "$bpath/dist"
  if [[ -d "$target" ]]; then
    rsync -a "$target/" "$bpath/dist/"
  fi
  if [[ "$p" == "lab" ]]; then
    if [[ -d "${DATA_ROOT}/lab/server" ]]; then
      mkdir -p "$bpath/server"
      rsync -a --exclude='data/' "${DATA_ROOT}/lab/server/" "$bpath/server/"
    fi
    if [[ -f "${DATA_ROOT}/lab/package.json" ]]; then
      cp -f "${DATA_ROOT}/lab/package.json" "$bpath/package.json"
    fi
  fi
  local prev_sha
  prev_sha=$(local_sha_of "$p")
  printf '%s\n' "${prev_sha:-unknown}" > "$bpath/commit.sha"
  prune_backups "$p"
  printf '%s' "$bpath"
}

restart_api_if_present() {
  command -v systemctl >/dev/null 2>&1 || return 0
  if systemctl list-unit-files "${API_SERVICE}.service" --no-legend 2>/dev/null | grep -q "^${API_SERVICE}\.service"; then
    systemctl restart "$API_SERVICE"
  elif systemctl is-active --quiet "$API_SERVICE" 2>/dev/null; then
    systemctl restart "$API_SERVICE"
  else
    warn "未检测到 systemd 服务 ${API_SERVICE}，跳过重启。"
    return 0
  fi

  local attempt ok=0
  for attempt in {1..15}; do
    if command -v curl >/dev/null 2>&1 && curl -fsS --max-time 3 "$API_HEALTH_URL" >/dev/null 2>&1; then
      ok=1
      break
    fi
    sleep 1
  done
  [[ "$ok" -eq 1 ]] || return 1
  return 0
}

restore_backup_path() {
  local p="$1" bpath="$2"
  local target
  target=$(target_dir_of "$p")
  [[ -d "$bpath/dist" ]] || die "备份目录缺少 dist：$bpath"
  mkdir -p "$target"
  rsync -a --delete --chmod=D755,F644 "$bpath/dist/" "$target/"

  if [[ "$p" == "lab" ]]; then
    if [[ -d "$bpath/server" ]]; then
      mkdir -p "${DATA_ROOT}/lab/server"
      rsync -a --delete --exclude='data/' --chmod=D755,F644 "$bpath/server/" "${DATA_ROOT}/lab/server/"
    fi
    if [[ -f "$bpath/package.json" ]]; then
      cp -f "$bpath/package.json" "${DATA_ROOT}/lab/package.json"
      chmod 644 "${DATA_ROOT}/lab/package.json"
    fi
    restart_api_if_present || warn "回滚后 ${API_SERVICE} 健康检查未通过，请手动检查服务。"
  fi

  if [[ -f "$bpath/commit.sha" ]]; then
    local sha
    sha=$(tr -d '[:space:]' < "$bpath/commit.sha")
    if [[ "$sha" != "unknown" && -n "$sha" ]]; then
      mkdir -p "${WORK_ROOT}/state"
      printf '%s\n' "$sha" > "${WORK_ROOT}/state/${p}.sha"
    fi
  fi
}

rollback_latest() {
  local p="$1"
  is_valid_project "$p" || die "不支持的项目名：$p"
  require_tools rsync flock
  acquire_lock
  local latest
  latest=$(ls -1dt "${WORK_ROOT}/backups/${p}"/*/ 2>/dev/null | head -n 1 || true)
  [[ -n "$latest" ]] || die "未找到项目 ${p} 的可用备份。"
  latest="${latest%/}"
  log "正在将 ${p} 回滚至备份：$latest"
  restore_backup_path "$p" "$latest"
  log "[成功] ${p} 回滚完成。"
}

validate_lab_server() {
  local repo_dir="$1"
  [[ -f "$repo_dir/package.json" && -f "$repo_dir/server/index.js" ]] || die "lab 后端文件不完整。"
  if [[ -d "${DATA_ROOT}/lab/server/data" ]]; then
    node --input-type=module - "$repo_dir/server" "${DATA_ROOT}/lab/server/data" <<'JS'
import path from 'node:path'
import { pathToFileURL } from 'node:url'
const [serverDir, liveDataDir] = process.argv.slice(2)
const { createLabStore } = await import(pathToFileURL(path.join(serverDir, 'dataStore.js')))
const { createContentStore } = await import(pathToFileURL(path.join(serverDir, 'contentStore.js')))
await createLabStore({ dataFile: path.join(liveDataDir, 'experiments.json') })
await createContentStore(liveDataDir)
JS
  fi
}

sync_project() {
  local p="$1" force="$2"
  local url target repo_dir state_file
  url=$(repo_url_of "$p")
  target=$(target_dir_of "$p")
  repo_dir="${WORK_ROOT}/repos/${p}"
  state_file="${WORK_ROOT}/state/${p}.sha"

  local remote_sha local_sha
  remote_sha=$(remote_sha_of "$p")
  [[ -n "$remote_sha" ]] || die "无法获取远程分支 SHA：${url} (${GITHUB_BRANCH})"
  local_sha=$(local_sha_of "$p")

  if [[ "$force" != "1" && "$remote_sha" == "$local_sha" && -f "$target/index.html" ]]; then
    log "[跳过] ${p} 已是最新 (${remote_sha:0:10})"
    return 0
  fi

  log "[拉取] ${p} -> ${remote_sha:0:10}"
  mkdir -p "${WORK_ROOT}/repos" "${WORK_ROOT}/state"
  if [[ ! -d "$repo_dir/.git" ]]; then
    rm -rf -- "$repo_dir"
    git clone --depth 1 --branch "$GITHUB_BRANCH" "$url" "$repo_dir"
  else
    git -C "$repo_dir" remote set-url origin "$url"
    git -C "$repo_dir" fetch --depth 1 origin "$GITHUB_BRANCH"
    git -C "$repo_dir" checkout -f FETCH_HEAD
  fi
  git -C "$repo_dir" clean -fdx -e node_modules

  # 仅当 package-lock.json 变更或 vite 不存在时安装依赖
  local lock_hash="" prev_lock_hash="" lock_marker="${repo_dir}/node_modules/.aurora-lock.sha256"
  if [[ -f "${repo_dir}/package-lock.json" ]]; then
    lock_hash=$(sha256sum "${repo_dir}/package-lock.json" | awk '{print $1}')
  fi
  [[ -f "$lock_marker" ]] && prev_lock_hash=$(cat "$lock_marker" || true)

  if [[ ! -x "${repo_dir}/node_modules/.bin/vite" || "$lock_hash" != "$prev_lock_hash" ]]; then
    log "[依赖] ${p} 正在安装 npm 依赖…"
    if [[ -f "${repo_dir}/package-lock.json" ]]; then
      (cd "$repo_dir" && npm ci --no-audit --no-fund)
    else
      (cd "$repo_dir" && npm install --no-audit --no-fund)
    fi
    [[ -n "$lock_hash" ]] && printf '%s\n' "$lock_hash" > "$lock_marker"
  fi

  log "[构建] ${p} 正在执行 vite build…"
  rm -rf -- "${repo_dir}/dist"
  (
    cd "$repo_dir"
    VITE_API_MODE="${VITE_API_MODE:-live}" \
    VITE_API_BASE="${VITE_API_BASE:-/api}" \
    VITE_API_FALLBACK_TO_MOCK="${VITE_API_FALLBACK_TO_MOCK:-true}" \
    npm run build
  )

  [[ -s "${repo_dir}/dist/index.html" && -d "${repo_dir}/dist/assets" ]] || {
    die "${p} 构建产物不完整（缺少 dist/index.html 或 dist/assets）。"
  }

  if [[ "$p" == "lab" ]]; then
    validate_lab_server "$repo_dir"
  fi

  local bpath
  bpath=$(backup_project "$p")

  mkdir -p "$(dirname "$target")" "$target"
  chmod 755 "$(dirname "$target")" "$target"
  # 先写入新资源再清理旧文件，避免切换期间静态资源 404
  rsync -a --delete-after --chmod=D755,F644 "${repo_dir}/dist/" "${target}/"

  if [[ "$p" == "lab" ]]; then
    mkdir -p "${DATA_ROOT}/lab/server/data"
    rsync -a --exclude='data/' --chmod=D755,F644 "${repo_dir}/server/" "${DATA_ROOT}/lab/server/"
    rsync -a --ignore-existing --chmod=D755,F644 "${repo_dir}/server/data/" "${DATA_ROOT}/lab/server/data/"
    cp -f "${repo_dir}/package.json" "${DATA_ROOT}/lab/package.json"
    chmod 644 "${DATA_ROOT}/lab/package.json"

    if ! restart_api_if_present; then
      warn "lab 后端重启健康检查失败，正在自动回滚…"
      restore_backup_path "lab" "$bpath"
      die "lab 更新失败并已自动回滚至 ${bpath}。"
    fi
  fi

  printf '%s\n' "$remote_sha" > "$state_file"
  log "[完成] ${p} 已更新至 ${remote_sha:0:10} -> ${target}"
}

install_timer() {
  local minutes="${1:-5}"
  [[ ${EUID} -eq 0 ]] || die "安装 systemd 定时任务需要 root 权限。"
  [[ "$minutes" =~ ^[0-9]+$ && "$minutes" -ge 1 ]] || die "定时间隔必须是正整数分钟。"
  require_tools install systemctl

  local self
  self=$(readlink -f "${BASH_SOURCE[0]}")
  install -m 755 "$self" /usr/local/bin/aurora-sync

  cat > /etc/systemd/system/aurora-sync.service <<EOF
[Unit]
Description=Aurora Suite GitHub Auto Sync & Deploy
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
Environment="GITHUB_OWNER=${GITHUB_OWNER}"
Environment="GITHUB_BRANCH=${GITHUB_BRANCH}"
Environment="GITHUB_BASE_URL=${GITHUB_BASE_URL}"
Environment="DATA_ROOT=${DATA_ROOT}"
Environment="WORK_ROOT=${WORK_ROOT}"
Environment="API_SERVICE=${API_SERVICE}"
ExecStart=/usr/local/bin/aurora-sync
EOF

  cat > /etc/systemd/system/aurora-sync.timer <<EOF
[Unit]
Description=Run Aurora GitHub Auto Sync every ${minutes} minutes

[Timer]
OnBootSec=2min
OnUnitActiveSec=${minutes}min
Persistent=true

[Install]
WantedBy=timers.target
EOF

  systemctl daemon-reload
  systemctl enable --now aurora-sync.timer
  log "已安装并启用 aurora-sync.timer（每 ${minutes} 分钟检查一次 GitHub 更新）。"
  systemctl list-timers --no-pager aurora-sync.timer || true
}

remove_timer() {
  [[ ${EUID} -eq 0 ]] || die "卸载 systemd 定时任务需要 root 权限。"
  require_tools systemctl
  systemctl disable --now aurora-sync.timer >/dev/null 2>&1 || true
  rm -f /etc/systemd/system/aurora-sync.service /etc/systemd/system/aurora-sync.timer
  systemctl daemon-reload
  log "已移除 aurora-sync.timer。"
}

main() {
  setup_path

  local force=0 mode="sync" rollback_target="" timer_mins="5"
  local targets=()

  while (($#)); do
    case "$1" in
      -f|--force) force=1; shift ;;
      -s|--status) mode="status"; shift ;;
      --rollback)
        mode="rollback"
        shift
        [[ $# -gt 0 ]] || die "--rollback 需要指定项目名。"
        rollback_target="$1"
        shift
        ;;
      --install-timer)
        mode="install-timer"
        shift
        if [[ $# -gt 0 && "$1" =~ ^[0-9]+$ ]]; then
          timer_mins="$1"
          shift
        fi
        ;;
      --remove-timer) mode="remove-timer"; shift ;;
      -h|--help) usage; exit 0 ;;
      -*) die "未知选项：$1（可用 --help 查看用法）" ;;
      *)
        is_valid_project "$1" || die "不支持的项目名：$1"
        targets+=("$1")
        shift
        ;;
    esac
  done

  case "$mode" in
    status) show_status; exit 0 ;;
    rollback) rollback_latest "$rollback_target"; exit 0 ;;
    install-timer) install_timer "$timer_mins"; exit 0 ;;
    remove-timer) remove_timer; exit 0 ;;
  esac

  require_tools git node npm rsync flock sha256sum
  acquire_lock

  if ((${#targets[@]} == 0)); then
    targets=("${ALL_PROJECTS[@]}")
  fi

  local updated=0 p
  for p in "${targets[@]}"; do
    local before_sha after_sha
    before_sha=$(local_sha_of "$p")
    sync_project "$p" "$force"
    after_sha=$(local_sha_of "$p")
    if [[ "$before_sha" != "$after_sha" || "$force" == "1" ]]; then
      updated=$((updated + 1))
    fi
  done

  if command -v nginx >/dev/null 2>&1 && nginx -t >/dev/null 2>&1; then
    systemctl reload nginx >/dev/null 2>&1 || true
  fi

  log "全部检查完成（本次更新项目数：${updated}）。"
}

main "$@"
