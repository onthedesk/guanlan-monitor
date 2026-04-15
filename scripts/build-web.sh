#!/usr/bin/env bash
# Production web build: blog (Astro) + TypeScript check + Vite bundle → dist/
#
# Usage:
#   bash scripts/build-web.sh              # full build (same as npm run build)
#   bash scripts/build-web.sh --skip-blog # tsc + vite only (no blog-site)
#   SKIP_BLOG=1 bash scripts/build-web.sh
#
# Requires: Node/npm at repo root; for full build, blog-site deps must be installable
# (if blog-site/node_modules is root-owned: sudo chown -R "$(whoami)" blog-site/node_modules)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${ROOT_DIR}"

SKIP_BLOG="${SKIP_BLOG:-0}"

usage() {
  cat <<'EOF'
Usage: bash scripts/build-web.sh [--skip-blog]

  --skip-blog   Skip Astro blog build; runs `npm exec tsc --noEmit` then `vite build`
                (matches CI-style check + SPA output only.)

Environment:
  SKIP_BLOG=1   Same as --skip-blog
EOF
}

for arg in "$@"; do
  case "${arg}" in
    -h|--help)
      usage
      exit 0
      ;;
    --skip-blog)
      SKIP_BLOG=1
      ;;
    *)
      echo "Unknown option: ${arg}" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ ! -f package.json ]]; then
  echo "package.json not found (wrong cwd?)" >&2
  exit 1
fi

ensure_root_deps() {
  if [[ -e node_modules ]] && [[ ! -w node_modules ]]; then
    echo "[build-web] ERROR: node_modules/ is not writable (often root-owned)." >&2
    echo "Fix: sudo chown -R \"$(whoami)\" \"${ROOT_DIR}/node_modules\"" >&2
    exit 1
  fi
  if [[ ! -x node_modules/.bin/tsc ]] || [[ ! -x node_modules/.bin/vite ]]; then
    echo "[build-web] Installing root npm dependencies…"
    npm install
  fi
}

ensure_blog_deps() {
  if [[ ! -d blog-site/node_modules ]] || [[ ! -x blog-site/node_modules/.bin/astro ]]; then
    echo "[build-web] Installing blog-site npm dependencies…"
    (cd blog-site && npm ci)
  fi
  if [[ -d blog-site/node_modules ]] && [[ ! -w blog-site/node_modules ]]; then
    echo "[build-web] ERROR: blog-site/node_modules is not writable (often root-owned)." >&2
    echo "Fix: sudo chown -R \"$(whoami)\" \"${ROOT_DIR}/blog-site/node_modules\"" >&2
    exit 1
  fi
}

ensure_root_deps

if [[ "${SKIP_BLOG}" == "1" ]]; then
  echo "[build-web] SKIP_BLOG=1 — running tsc --noEmit && vite build"
  npm exec -- tsc --noEmit
  npm exec -- vite build
else
  ensure_blog_deps
  echo "[build-web] Full production build (blog + tsc + vite)…"
  npm run build
fi

echo "[build-web] Done. Output: dist/"
