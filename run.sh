#!/bin/bash
set -euo pipefail

CONTAINER_NAME="web-ide"
IMAGE="codercom/code-server:latest"

# ── Defaults (used by start/restart) ──────────────────────────
PORT=8080
PASSWORD="cc"
TARGET_DIR="$(pwd)"

# ── Helpers ───────────────────────────────────────────────────

usage() {
    echo "Usage:"
    echo "  ./run.sh start    [--port PORT] [--password PASSWORD] [--dir DIR_PATH]"
    echo "  ./run.sh stop"
    echo "  ./run.sh restart  [--port PORT] [--password PASSWORD] [--dir DIR_PATH]"
    echo "  ./run.sh remove"
    echo "  ./run.sh status"
    echo "  ./run.sh logs"
    echo ""
    echo "  # Pipe / curl mode:"
    echo "  curl -sSL ... | bash"
    echo "  curl -sSL ... | bash -s -- [--port PORT] [--password PASSWORD] [--dir DIR_PATH]"
    exit 1
}

detect_docker_user() {
    if docker info 2>/dev/null | grep -q 'rootless'; then
        DOCKER_USER="0:0"
        echo "🐳 Docker mode: rootless (auto-detected)"
    else
        DOCKER_USER="$(id -u):$(id -g)"
        echo "🐳 Docker mode: root (auto-detected)"
    fi
}

container_exists() {
    docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"
}

container_running() {
    docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"
}

# ── Commands ──────────────────────────────────────────────────

cmd_start() {
    # Parse options
    while [[ $# -gt 0 ]]; do
        case $1 in
            --port)     PORT="$2"; shift 2 ;;
            --password) PASSWORD="$2"; shift 2 ;;
            --dir)      TARGET_DIR="$2"; shift 2 ;;
            *) echo "Unknown option: $1"; usage ;;
        esac
    done

    # If already running, just report
    if container_running; then
        local HOST_PORT
        HOST_PORT=$(docker port "${CONTAINER_NAME}" 8080 2>/dev/null | head -1 | sed 's/.*://')
        echo "⚠️  Container '${CONTAINER_NAME}' is already running."
        echo "   Access via: http://localhost:${HOST_PORT:-?}"
        echo "   Use './run.sh restart' to apply new config, or './run.sh stop' first."
        exit 0
    fi

    detect_docker_user

    # ── 最佳实践：在宿主机提前创建好持久化数据的子目录 ──
    # 保证整个 /home/coder（包含 Claude Code、Codex、Codewhale 的配置/登录态/历史记录）永不丢失
    local DATA_DIR="${TARGET_DIR}/.code-server-home"
    mkdir -p "${DATA_DIR}"

    # Clean up any stopped container so we can recreate with fresh config
    docker rm -f "${CONTAINER_NAME}" 2>/dev/null || true

    echo "🚀 Starting lightweight Cloud IDE (code-server)..."
    echo "📂 Workspace Root:    ${TARGET_DIR}"
    echo "💾 Full Home Data:    ${DATA_DIR} -> /home/coder"
    echo "🌐 Access Port:       ${PORT}"
    echo "🔑 Access Password:   ${PASSWORD}"

    # ── 嵌套挂载最佳实践 ──
    # CODE_SERVER_RECONNECTION_GRACE_TIME=2592000 让会话保持 30 天永不断线保护
    docker run -d \
        --name "${CONTAINER_NAME}" \
        --user "${DOCKER_USER}" \
        -p "${PORT}:8080" \
        -v "${DATA_DIR}":/home/coder \
        -v "${TARGET_DIR}":/home/coder/project \
        -e "PASSWORD=${PASSWORD}" \
        -e "CODE_SERVER_RECONNECTION_GRACE_TIME=2592000" \
        "${IMAGE}" \
        --bind-addr 0.0.0.0:8080 /home/coder/project

    echo "------------------------------------------------"
    echo "✅ Started successfully! Access via: http://localhost:${PORT}"
    echo "🛑 To stop:  ./run.sh stop   |   ▶️  To resume: ./run.sh start"
    echo "------------------------------------------------"
}

cmd_stop() {
    if container_running; then
        echo "🛑 Stopping container '${CONTAINER_NAME}'..."
        docker stop "${CONTAINER_NAME}"
        echo "✅ Container stopped. Use './run.sh start' to resume."
    else
        echo "⚠️  Container '${CONTAINER_NAME}' is not running."
    fi
}

cmd_restart() {
    # Stop if running, then start with any new options
    if container_running; then
        echo "🛑 Stopping container..."
        docker stop "${CONTAINER_NAME}"
    fi
    cmd_start "$@"
}

cmd_remove() {
    if container_exists; then
        echo "🗑️  Removing container '${CONTAINER_NAME}'..."
        docker rm -f "${CONTAINER_NAME}" 2>/dev/null || true
        echo "✅ Container removed."
    else
        echo "⚠️  Container '${CONTAINER_NAME}' does not exist."
    fi
}

cmd_status() {
    if container_running; then
        echo "📊 Container '${CONTAINER_NAME}' status:"
        docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' | head -1
        docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' | grep "^${CONTAINER_NAME}"
    elif container_exists; then
        echo "⏸️  Container '${CONTAINER_NAME}' exists but is stopped."
        echo "   Use './run.sh start' to resume, or './run.sh remove' to delete."
    else
        echo "❌ Container '${CONTAINER_NAME}' does not exist."
        echo "   Use './run.sh start' to create and launch it."
    fi
}

cmd_logs() {
    if container_exists; then
        docker logs --tail 50 -f "${CONTAINER_NAME}"
    else
        echo "❌ Container '${CONTAINER_NAME}' does not exist."
    fi
}

# ═══════════════════════════════════════════════════════════════
# Main entry point — dispatch on first argument
# ═══════════════════════════════════════════════════════════════
COMMAND="${1:-}"

case "${COMMAND}" in
    start)   shift; cmd_start "$@" ;;
    stop)    cmd_stop ;;
    restart) shift; cmd_restart "$@" ;;
    remove)  cmd_remove ;;
    status)  cmd_status ;;
    logs)    cmd_logs ;;
    -h|--help|help) usage ;;
    "")
        cmd_start
        ;;
    --*)
        cmd_start "$@"
        ;;
    *)
        echo "Unknown command: ${COMMAND}"
        usage
        ;;
esac
