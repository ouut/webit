#!/bin/bash

# Default parameters
PORT=8080
PASSWORD="cc"
TARGET_DIR="$(pwd)"

# Parse input arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --port)
      PORT="$2"
      shift 2
      ;;
    --password)
      PASSWORD="$2"
      shift 2
      ;;
    --dir)
      TARGET_DIR="$2"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1"
      echo "Usage: curl -sSL ... | bash -s -- [--port PORT] [--password PASSWORD] [--dir DIR_PATH]"
      exit 1
      ;;
  esac
done

# Auto-detect Docker mode and set the right user mapping
#   rootless Docker: container root(0) → host user  → use --user 0:0
#   root    Docker: container root(0) → host root   → use --user $(id -u):$(id -g)
if docker info 2>/dev/null | grep -q 'rootless'; then
    DOCKER_USER="0:0"
    echo "🐳 Docker mode: rootless (auto-detected)"
else
    DOCKER_USER="$(id -u):$(id -g)"
    echo "🐳 Docker mode: root (auto-detected)"
fi

# Clean up any previous container with this name
docker rm -f web-ide 2>/dev/null || true

echo "🚀 Starting lightweight Cloud IDE (code-server)..."
echo "📂 Shared Directory: $TARGET_DIR"
echo "🌐 Access Port:     $PORT"
echo "🔑 Access Password: $PASSWORD"
echo "💾 Persist Mode:     Container survives stop (use 'docker start web-ide' to resume)"

docker run -d \
  --name web-ide \
  --user "${DOCKER_USER}" \
  -p "${PORT}:8080" \
  -v "${TARGET_DIR}":/home/coder/project \
  -e "PASSWORD=${PASSWORD}" \
  codercom/code-server:latest

echo "------------------------------------------------"
echo "✅ Started successfully! Access via: http://localhost:${PORT}"
echo "🛑 To stop:  docker stop web-ide   |   ▶️  To resume: docker start web-ide"
echo "------------------------------------------------"