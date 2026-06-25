#!/bin/bash

# 默认参数
PORT=80
PASSWORD="cc"
TARGET_DIR="$(pwd)"

# 解析输入参数 (例如 --port 8080 --password my_pwd --dir /path)
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
      echo "未知参数: $1"
      echo "用法: curl -sSL ... | bash -s -- [--port 端口] [--password 密码] [--dir 目录路径]"
      exit 1
      ;;
  esac
done

# 获取当前用户的 UID 和 GID，防止 Docker 产生 root 读写权限问题
USER_UID=$(id -u)
USER_GID=$(id -g)

# 清理同名的旧容器（如果存在）
if [ "$(docker ps -aq -f name=web-ide)" ]; then
    echo "⚠️ 检测到同名容器正在运行，正在清理..."
    docker rm -f web-ide > /dev/null
fi

echo "🚀 正在启动 code-server..."
echo "📂 挂载目录: $TARGET_DIR"
echo "🌐 访问端口: $PORT"
echo "🔑 登录密码: $PASSWORD"

# 一条命令直接拉取并运行 Docker 镜像
docker run -d \
  --name web-ide \
  -p "${PORT}:8080" \
  -v "${TARGET_DIR}":/home/coder/project \
  -e PASSWORD="${PASSWORD}" \
  --user "${USER_UID}:${USER_GID}" \
  --restart unless-stopped \
  codercom/code-server:latest

echo "✅ 启动成功！请在浏览器访问 http://localhost:${PORT}"
