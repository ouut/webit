#!/bin/bash

# Default parameters (Changed default port to 8080 for Rootless Docker compatibility)
PORT=80
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

# If an older container instance exists, stop it first
if [ "$(docker ps -aq -f name=web-ide)" ]; then
    echo "⚠️ Existing instance found, stopping and cleaning up..."
    docker stop web-ide > /dev/null
fi

echo "🚀 Starting lightweight Cloud IDE (code-server)..."
echo "📂 Shared Directory: $TARGET_DIR"
echo "🌐 Access Port:     $PORT"
echo "🔑 Access Password: $PASSWORD"
echo "♻️  Exit Mode:       --rm (Container will be destroyed automatically on stop)"

# Run Docker (Optimized for Rootless and User Namespace environments)
docker run -d \
  --name web-ide \
  --rm \
  -p "${PORT}:8080" \
  -v "${TARGET_DIR}":/home/coder/project \
  -e PASSWORD="${PASSWORD}" \
  codercom/code-server:latest

echo "------------------------------------------------"
echo "✅ Started successfully! Access via: http://localhost:${PORT}"
echo "🛑 To stop and destroy the container, run: docker stop web-ide"
echo "------------------------------------------------"
