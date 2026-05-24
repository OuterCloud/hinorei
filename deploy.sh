#!/usr/bin/env bash
# =============================================================================
# deploy.sh — Hinorei 服务部署脚本
# 用法:
#   ./deploy.sh start   [PORT] [--host HOST] [--backend-port PORT] [--frontend-port PORT] [--workers N] [-B]
#   ./deploy.sh stop
#   ./deploy.sh restart [PORT] [--host HOST] [--backend-port PORT] [--frontend-port PORT] [--workers N] [-B]
#   ./deploy.sh status
#   ./deploy.sh build           # 仅编译前端，不启动服务
#   ./deploy.sh debug  [PORT]   # 调试模式：后端热重载 + 前端 HMR，Ctrl+C 退出
#   ./deploy.sh logs [-f]       # 查看日志（-f 实时追踪）
# =============================================================================

set -euo pipefail

# --------------------------------------------------------------------------- #
# 路径常量
# --------------------------------------------------------------------------- #
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PID_FILE="$SCRIPT_DIR/.hinorei.pid"
LOG_DIR="$SCRIPT_DIR/logs"
LOG_FILE="$LOG_DIR/hinorei.log"
FRONTEND_DIR="$SCRIPT_DIR/frontend"
VENV_DIR="$SCRIPT_DIR/venv"
DIST_DIR="$FRONTEND_DIR/dist"

# --------------------------------------------------------------------------- #
# 默认配置（可被命令行参数覆盖）
# --------------------------------------------------------------------------- #
HOST="${HINOREI_HOST:-0.0.0.0}"
BACKEND_PORT="${HINOREI_BACKEND_PORT:-${HINOREI_PORT:-8000}}"
FRONTEND_PORT="${HINOREI_FRONTEND_PORT:-5173}"
WORKERS="${HINOREI_WORKERS:-1}"
FORCE_BUILD=false

# --------------------------------------------------------------------------- #
# 颜色输出
# --------------------------------------------------------------------------- #
if [[ -t 1 ]]; then
  RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
  BLUE='\033[0;34m'; BOLD='\033[1m'; RESET='\033[0m'
else
  RED=''; GREEN=''; YELLOW=''; BLUE=''; BOLD=''; RESET=''
fi

info()    { echo -e "${BLUE}[INFO]${RESET}  $*"; }
success() { echo -e "${GREEN}[OK]${RESET}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${RESET}  $*"; }
error()   { echo -e "${RED}[ERROR]${RESET} $*" >&2; }
die()     { error "$*"; exit 1; }

# --------------------------------------------------------------------------- #
# 帮助信息
# --------------------------------------------------------------------------- #
usage() {
  cat <<EOF
${BOLD}用法:${RESET}
  $(basename "$0") <命令> [选项]

${BOLD}命令:${RESET}
  start     编译前端并启动后端服务（后台运行）
  stop      停止后端服务
  restart   停止后重新编译并启动
  status    显示服务运行状态
  build     仅编译前端静态文件
  debug     调试模式：后端热重载 + 前端 HMR，Ctrl+C 退出
  logs      查看服务日志

${BOLD}选项:${RESET}
  --host HOST       监听地址（默认: 0.0.0.0，可用 HINOREI_HOST 环境变量设置）
  --backend-port PORT, -p PORT
                    后端监听端口（默认: 8000，可用 HINOREI_BACKEND_PORT 环境变量设置）
  --frontend-port PORT
                    前端开发服务器端口（默认: 5173，可用 HINOREI_FRONTEND_PORT 环境变量设置）
  PORT              直接写端口号作为第一个位置参数（同 --backend-port）
  --workers N       工作进程数（默认: 1，可用 HINOREI_WORKERS 环境变量设置）
  -B, --force-build 强制重新编译前端（默认：源码无变化时跳过）
  -f                配合 logs 命令实时追踪日志

${BOLD}示例:${RESET}
  ./deploy.sh start              # 源码未变化则跳过编译
  ./deploy.sh start 9000
  ./deploy.sh start -B           # 强制重编
  ./deploy.sh start --backend-port 9000 --workers 2
  ./deploy.sh debug              # 本地调试，改代码自动生效
  ./deploy.sh debug --backend-port 9000 --frontend-port 3000
  ./deploy.sh logs -f
EOF
}

# --------------------------------------------------------------------------- #
# 参数解析
# --------------------------------------------------------------------------- #
parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --host)            HOST="$2"; shift 2 ;;
      --backend-port|-p) BACKEND_PORT="$2"; shift 2 ;;
      --frontend-port)   FRONTEND_PORT="$2"; shift 2 ;;
      --workers)         WORKERS="$2"; shift 2 ;;
      -B|--force-build)  FORCE_BUILD=true; shift ;;
      -h|--help)         usage; exit 0 ;;
      [0-9]*)            BACKEND_PORT="$1"; shift ;;  # 位置参数：直接写后端端口号
      *)                 shift ;;  # 忽略未知参数
    esac
  done
}

# --------------------------------------------------------------------------- #
# 工具函数
# --------------------------------------------------------------------------- #
get_pid() {
  [[ -f "$PID_FILE" ]] && cat "$PID_FILE" || echo ""
}

is_running() {
  local pid
  pid="$(get_pid)"
  [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null
}

require_venv() {
  if [[ ! -x "$VENV_DIR/bin/python" ]]; then
    die "未找到虚拟环境 ${VENV_DIR}。请先运行: python -m venv venv && venv/bin/pip install -r requirements.txt"
  fi
}

# 检查前端源码是否比 dist/ 更新，是则需要重编
needs_build() {
  local marker="$DIST_DIR/index.html"
  [[ ! -f "$marker" ]] && return 0  # dist 不存在，必须编译
  # 检查 src/、public/、配置文件中是否有比 dist 更新的文件
  local changed
  changed=$(find "$FRONTEND_DIR/src" "$FRONTEND_DIR/public" \
    "$FRONTEND_DIR/index.html" \
    "$FRONTEND_DIR/package.json" \
    "$FRONTEND_DIR/vite.config."* \
    -newer "$marker" 2>/dev/null | head -1)
  [[ -n "$changed" ]]
}

require_node() {
  if ! command -v node &>/dev/null; then
    die "未找到 node。请先安装 Node.js >= 18"
  fi
  if ! command -v pnpm &>/dev/null; then
    die "未找到 pnpm。请先安装：npm install -g pnpm"
  fi
}

# 释放端口：终止占用指定端口的进程
kill_port() {
  local port="$1"
  local pids
  pids=$(lsof -ti :"$port" 2>/dev/null || true)
  if [[ -n "$pids" ]]; then
    warn "端口 ${port} 被占用（PID: ${pids}），正在终止..."
    echo "$pids" | xargs kill -TERM 2>/dev/null || true
    sleep 0.8
    # 若仍存活则强制 KILL
    local remaining
    remaining=$(lsof -ti :"$port" 2>/dev/null || true)
    if [[ -n "$remaining" ]]; then
      echo "$remaining" | xargs kill -KILL 2>/dev/null || true
    fi
    success "端口 ${port} 已释放"
  fi
}

# --------------------------------------------------------------------------- #
# 子命令：build
# --------------------------------------------------------------------------- #
cmd_build() {
  require_node
  info "检查前端依赖..."
  if [[ ! -d "$FRONTEND_DIR/node_modules" ]]; then
    info "安装前端依赖（pnpm install）..."
    (cd "$FRONTEND_DIR" && pnpm install) \
      || die "前端依赖安装失败"
  fi
  info "编译前端（pnpm build）..."
  (cd "$FRONTEND_DIR" && pnpm build) \
    || die "前端编译失败"
  success "前端编译完成 → $DIST_DIR"
}

# --------------------------------------------------------------------------- #
# 子命令：start
# --------------------------------------------------------------------------- #
cmd_start() {
  if is_running; then
    local pid; pid="$(get_pid)"
    warn "服务已在运行中（PID ${pid}）。如需重启请使用: ./deploy.sh restart"
    exit 0
  fi

  require_venv

  # 前端编译
  if [[ "$FORCE_BUILD" == true ]]; then
    cmd_build
  elif needs_build; then
    info "检测到前端源码有变化，开始编译..."
    cmd_build
  else
    info "前端源码无变化，跳过编译（使用已有 dist/）"
  fi

  # 创建日志目录
  mkdir -p "$LOG_DIR"

  kill_port "$BACKEND_PORT"

  info "启动后端服务..."
  info "  地址:    http://${HOST}:${BACKEND_PORT}"
  info "  Workers: ${WORKERS}"
  info "  日志:    $LOG_FILE"

  # 用 nohup 后台启动，工作目录设为项目根
  nohup "$VENV_DIR/bin/uvicorn" app.main:app \
    --host "$HOST" \
    --port "$BACKEND_PORT" \
    --workers "$WORKERS" \
    >> "$LOG_FILE" 2>&1 &

  local pid=$!
  echo "$pid" > "$PID_FILE"

  # 等待最多 5 秒确认进程存活
  local attempts=0
  while (( attempts < 10 )); do
    sleep 0.5
    if kill -0 "$pid" 2>/dev/null; then
      success "服务已启动（PID ${pid}）→ http://${HOST}:${BACKEND_PORT}"
      return 0
    fi
    (( attempts++ ))
  done

  rm -f "$PID_FILE"
  die "服务启动失败，请查看日志：$LOG_FILE"
}

# --------------------------------------------------------------------------- #
# 子命令：stop
# --------------------------------------------------------------------------- #
cmd_stop() {
  if ! is_running; then
    warn "服务未运行"
    rm -f "$PID_FILE"
    return 0
  fi

  local pid; pid="$(get_pid)"
  info "停止服务（PID ${pid}）..."
  kill -TERM "$pid" 2>/dev/null || true

  # 等待进程退出，超时后强制 KILL
  local attempts=0
  while (( attempts < 20 )); do
    sleep 0.5
    if ! kill -0 "$pid" 2>/dev/null; then
      rm -f "$PID_FILE"
      success "服务已停止"
      return 0
    fi
    (( attempts++ ))
  done

  warn "进程未响应 SIGTERM，发送 SIGKILL..."
  kill -KILL "$pid" 2>/dev/null || true
  rm -f "$PID_FILE"
  success "服务已强制终止"
}

# --------------------------------------------------------------------------- #
# 子命令：restart
# --------------------------------------------------------------------------- #
cmd_restart() {
  cmd_stop
  sleep 1
  cmd_start
}

# --------------------------------------------------------------------------- #
# 子命令：debug
# --------------------------------------------------------------------------- #
cmd_debug() {
  require_venv
  require_node

  if [[ ! -d "$FRONTEND_DIR/node_modules" ]]; then
    info "安装前端依赖（pnpm install）..."
    (cd "$FRONTEND_DIR" && pnpm install) || die "前端依赖安装失败"
  fi

  info "启动调试模式"
  info "  后端: http://${HOST}:${BACKEND_PORT}  （Python 改动自动重载）"
  info "  前端: http://localhost:${FRONTEND_PORT}   （Vite HMR 热更新）"
  info "  按 Ctrl+C 退出所有进程"
  echo ""

  kill_port "$BACKEND_PORT"
  kill_port "$FRONTEND_PORT"

  # 后台启动后端（--reload 监听 Python 文件变动）
  "$VENV_DIR/bin/uvicorn" app.main:app \
    --reload \
    --host "$HOST" \
    --port "$BACKEND_PORT" &
  local backend_pid=$!

  # Ctrl+C 或脚本退出时一并终止后端
  trap "echo ''; info '正在退出...'; kill $backend_pid 2>/dev/null; wait $backend_pid 2>/dev/null; exit 0" INT TERM

  # 前台启动前端，传入端口和代理目标
  (cd "$FRONTEND_DIR" && VITE_PORT="$FRONTEND_PORT" VITE_PROXY_TARGET="http://${HOST}:${BACKEND_PORT}" pnpm dev --host "$HOST" --port "$FRONTEND_PORT") || true

  # 前端退出后也清理后端
  kill $backend_pid 2>/dev/null
  wait $backend_pid 2>/dev/null
}

# --------------------------------------------------------------------------- #
# 子命令：status
# --------------------------------------------------------------------------- #
cmd_status() {
  echo ""
  echo -e "${BOLD}Hinorei 服务状态${RESET}"
  echo "─────────────────────────────────"

  if is_running; then
    local pid; pid="$(get_pid)"
    local uptime_info=""
    if command -v ps &>/dev/null; then
      uptime_info=$(ps -o etime= -p "$pid" 2>/dev/null | tr -d ' ' || echo "未知")
    fi
    echo -e "  状态:    ${GREEN}● 运行中${RESET}"
    echo    "  PID:     $pid"
    [[ -n "$uptime_info" ]] && echo "  运行时长: $uptime_info"
    echo    "  地址:    http://${HOST}:${BACKEND_PORT}"
  else
    echo -e "  状态:    ${RED}● 未运行${RESET}"
    rm -f "$PID_FILE"
  fi

  # 前端构建状态
  if [[ -d "$DIST_DIR" ]]; then
    local build_time
    build_time=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$DIST_DIR/index.html" 2>/dev/null \
      || stat -c "%y" "$DIST_DIR/index.html" 2>/dev/null | cut -d'.' -f1 \
      || echo "未知")
    echo -e "  前端:    ${GREEN}已编译${RESET}（${build_time}）"
  else
    echo -e "  前端:    ${YELLOW}未编译${RESET}"
  fi

  # 日志文件
  if [[ -f "$LOG_FILE" ]]; then
    local log_size
    log_size=$(du -sh "$LOG_FILE" 2>/dev/null | cut -f1 || echo "?")
    echo    "  日志:    ${LOG_FILE}（${log_size}）"
  fi

  echo ""
}

# --------------------------------------------------------------------------- #
# 子命令：logs
# --------------------------------------------------------------------------- #
cmd_logs() {
  mkdir -p "$LOG_DIR"
  if [[ ! -f "$LOG_FILE" ]]; then
    warn "日志文件不存在：$LOG_FILE"
    return 0
  fi
  if [[ "${FOLLOW:-false}" == true ]]; then
    exec tail -f "$LOG_FILE"
  else
    tail -100 "$LOG_FILE"
  fi
}

# --------------------------------------------------------------------------- #
# 入口
# --------------------------------------------------------------------------- #
COMMAND="${1:-help}"
shift || true

# 提前扫描 -f 标志（供 logs 用）
for arg in "$@"; do
  [[ "$arg" == "-f" ]] && FOLLOW=true
done

parse_args "$@"

case "$COMMAND" in
  start)   cmd_start   ;;
  stop)    cmd_stop    ;;
  restart) cmd_restart ;;
  debug)   cmd_debug   ;;
  status)  cmd_status  ;;
  build)   cmd_build   ;;
  logs)    cmd_logs    ;;
  help|-h|--help) usage ;;
  *) error "未知命令: $COMMAND"; echo ""; usage; exit 1 ;;
esac
