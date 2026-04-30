#!/usr/bin/env bash
# =============================================================================
# deploy.sh — Hinorei 服务部署脚本
# 用法:
#   ./deploy.sh start   [PORT] [--host HOST] [--port PORT] [-p PORT] [--workers N] [--no-build]
#   ./deploy.sh stop
#   ./deploy.sh restart [PORT] [--host HOST] [--port PORT] [-p PORT] [--workers N] [--no-build]
#   ./deploy.sh status
#   ./deploy.sh build           # 仅编译前端，不启动服务
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
PORT="${HINOREI_PORT:-8000}"
WORKERS="${HINOREI_WORKERS:-1}"
SKIP_BUILD=false

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
  logs      查看服务日志

${BOLD}选项:${RESET}
  --host HOST       监听地址（默认: 0.0.0.0，可用 HINOREI_HOST 环境变量设置）
  --port PORT, -p PORT
                    监听端口（默认: 8000，可用 HINOREI_PORT 环境变量设置）
  PORT              直接写端口号作为第一个位置参数（同 --port）
  --workers N       工作进程数（默认: 1，可用 HINOREI_WORKERS 环境变量设置）
  --no-build        跳过前端编译，直接使用已有的 dist/
  -f                配合 logs 命令实时追踪日志

${BOLD}示例:${RESET}
  ./deploy.sh start
  ./deploy.sh start 9000
  ./deploy.sh start -p 9000 --workers 2
  ./deploy.sh start --port 9000 --workers 2
  ./deploy.sh restart --no-build
  ./deploy.sh logs -f
EOF
}

# --------------------------------------------------------------------------- #
# 参数解析
# --------------------------------------------------------------------------- #
parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --host)          HOST="$2"; shift 2 ;;
      --port|-p)       PORT="$2"; shift 2 ;;
      --workers)       WORKERS="$2"; shift 2 ;;
      --no-build)      SKIP_BUILD=true; shift ;;
      -h|--help)       usage; exit 0 ;;
      [0-9]*)          PORT="$1"; shift ;;  # 位置参数：直接写端口号
      *)               shift ;;  # 忽略未知参数
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

require_node() {
  if ! command -v node &>/dev/null; then
    die "未找到 node。请先安装 Node.js >= 18"
  fi
  if ! command -v npm &>/dev/null; then
    die "未找到 npm。请先安装 npm"
  fi
}

# --------------------------------------------------------------------------- #
# 子命令：build
# --------------------------------------------------------------------------- #
cmd_build() {
  require_node
  info "检查前端依赖..."
  if [[ ! -d "$FRONTEND_DIR/node_modules" ]]; then
    info "安装前端依赖（npm install）..."
    (cd "$FRONTEND_DIR" && npm install) \
      || die "前端依赖安装失败"
  fi
  info "编译前端（npm run build）..."
  (cd "$FRONTEND_DIR" && npm run build) \
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
  if [[ "$SKIP_BUILD" == true ]]; then
    if [[ ! -d "$DIST_DIR" ]]; then
      die "--no-build 指定跳过编译，但 $DIST_DIR 不存在。请先运行: ./deploy.sh build"
    fi
    info "跳过前端编译（--no-build）"
  else
    cmd_build
  fi

  # 创建日志目录
  mkdir -p "$LOG_DIR"

  info "启动后端服务..."
  info "  地址:    http://${HOST}:${PORT}"
  info "  Workers: ${WORKERS}"
  info "  日志:    $LOG_FILE"

  # 用 nohup 后台启动，工作目录设为项目根
  nohup "$VENV_DIR/bin/uvicorn" app.main:app \
    --host "$HOST" \
    --port "$PORT" \
    --workers "$WORKERS" \
    >> "$LOG_FILE" 2>&1 &

  local pid=$!
  echo "$pid" > "$PID_FILE"

  # 等待最多 5 秒确认进程存活
  local attempts=0
  while (( attempts < 10 )); do
    sleep 0.5
    if kill -0 "$pid" 2>/dev/null; then
      success "服务已启动（PID ${pid}）→ http://${HOST}:${PORT}"
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
    echo    "  地址:    http://${HOST}:${PORT}"
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
  status)  cmd_status  ;;
  build)   cmd_build   ;;
  logs)    cmd_logs    ;;
  help|-h|--help) usage ;;
  *) error "未知命令: $COMMAND"; echo ""; usage; exit 1 ;;
esac
