#!/usr/bin/env bash
# 生产容器部署：在 Docker builder 阶段执行 npm run build（blog + tsc + vite），
# 与 docker/Dockerfile.fullstack 中 RUN npm run build 一致。
#
# 用法（在仓库根目录）:
#   bash scripts/docker-prod-deploy.sh build     # 只构建镜像（含镜像内 vite build）
#   bash scripts/docker-prod-deploy.sh up       # 已构建则直接 up -d
#   bash scripts/docker-prod-deploy.sh deploy   # build 再 up -d（默认）
#
# 环境变量:
#   ENV_FILE   默认 docker/.env.prod，可覆盖为绝对路径
#   NPM_CONFIG_REGISTRY  传给 compose build args（与 docker-compose 一致）

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${ROOT_DIR}"

COMPOSE_FILE="docker/docker-compose.prod.yml"
ENV_FILE="${ENV_FILE:-docker/.env.prod}"

usage() {
  cat <<'EOF'
生产 Docker 部署（1panel-network + guanlan-prod-app）

  bash scripts/docker-prod-deploy.sh build    # docker compose build（镜像内 npm run build）
  bash scripts/docker-prod-deploy.sh up       # docker compose up -d
  bash scripts/docker-prod-deploy.sh deploy    # build 后 up -d（默认）

环境变量:
  ENV_FILE=docker/.env.prod   指向 compose 的 --env-file（需含 REDIS 等）

前置: 已创建 docker/.env.prod（勿提交 git）；外部网络 1panel-network 已存在。
EOF
}

if [[ ! -f "${COMPOSE_FILE}" ]]; then
  echo "找不到 ${COMPOSE_FILE}" >&2
  exit 1
fi

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "找不到环境文件: ${ENV_FILE}" >&2
  echo "请复制: cp docker/.env.prod.example docker/.env.prod 并编辑" >&2
  exit 1
fi

CMD="${1:-deploy}"
case "${CMD}" in
  -h|--help)
    usage
    exit 0
    ;;
  build)
    docker compose -f "${COMPOSE_FILE}" --env-file "${ENV_FILE}" build
    ;;
  up)
    docker compose -f "${COMPOSE_FILE}" --env-file "${ENV_FILE}" up -d
    ;;
  deploy)
    docker compose -f "${COMPOSE_FILE}" --env-file "${ENV_FILE}" up --build -d
    ;;
  *)
    echo "未知子命令: ${CMD}" >&2
    usage
    exit 1
    ;;
esac

echo "[docker-prod-deploy] 完成: ${CMD}"
