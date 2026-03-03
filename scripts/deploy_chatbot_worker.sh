#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
WORKER_DIR="$ROOT_DIR/backend/cloudflare-worker"
HUGO_CONFIG="$ROOT_DIR/hugo.toml"

WRANGLER_CMD=""
if command -v wrangler >/dev/null 2>&1; then
  WRANGLER_CMD="wrangler"
elif [ -x "/opt/homebrew/lib/node_modules/wrangler/bin/wrangler.js" ]; then
  WRANGLER_CMD="node /opt/homebrew/lib/node_modules/wrangler/bin/wrangler.js"
else
  echo "[error] 未找到 wrangler。请先安装：npm i -g wrangler"
  exit 1
fi

echo "[step] 准备 wrangler 配置"
cd "$WORKER_DIR"
if [ ! -f "wrangler.toml" ]; then
  cp wrangler.toml.example wrangler.toml
  echo "[ok] 已创建 backend/cloudflare-worker/wrangler.toml"
fi

echo "[step] 检查 Cloudflare 登录状态"
if ! $WRANGLER_CMD whoami >/dev/null 2>&1; then
  echo "[info] 当前未登录，开始登录..."
  $WRANGLER_CMD login --browser false || true
  echo
  echo "[todo] 请在你的终端执行并完成授权："
  echo "  $WRANGLER_CMD login"
  echo "[todo] 完成后重新运行本脚本。"
  exit 2
fi

echo "[step] 检查 OPENAI_API_KEY secret（可选）"
if ! $WRANGLER_CMD secret list 2>/dev/null | rg -q "OPENAI_API_KEY"; then
  echo "[warn] 未检测到 OPENAI_API_KEY，将按 wrangler.toml 的无密钥端点部署。"
  echo "[info] 若你后续切换到需要密钥的模型端点，再执行："
  echo "  cd $WORKER_DIR"
  echo "  $WRANGLER_CMD secret put OPENAI_API_KEY"
fi

echo "[step] 部署 Worker"
DEPLOY_OUTPUT="$($WRANGLER_CMD deploy 2>&1 | tee /dev/stderr)"
WORKER_URL="$(printf "%s" "$DEPLOY_OUTPUT" | rg -o 'https://[a-zA-Z0-9._-]+\.workers\.dev' | head -n1 || true)"

if [ -z "$WORKER_URL" ]; then
  echo "[error] 未从 deploy 输出中解析到 workers.dev URL。请手动查看输出并配置 hugo.toml"
  exit 4
fi

echo "[ok] Worker URL: $WORKER_URL"
echo "[step] 回填 hugo.toml 的 params.chatbot.apiProxy"

# 如果已有 apiProxy 行，直接替换；否则插入 params.chatbot 下
if rg -n '^\s*apiProxy\s*=' "$HUGO_CONFIG" >/dev/null 2>&1; then
  sed -i '' -E "s#^\s*apiProxy\s*=.*#    apiProxy = \"$WORKER_URL\"#g" "$HUGO_CONFIG"
else
  awk -v url="$WORKER_URL" '
    BEGIN { inserted = 0 }
    /^\[params\.chatbot\]/ {
      print $0
      print "    apiProxy = \"" url "\""
      inserted = 1
      next
    }
    { print $0 }
    END {
      if (!inserted) {
        print ""
        print "[params.chatbot]"
        print "    apiProxy = \"" url "\""
        print "    requestTimeoutSec = 12"
      }
    }
  ' "$HUGO_CONFIG" > "$HUGO_CONFIG.tmp" && mv "$HUGO_CONFIG.tmp" "$HUGO_CONFIG"
fi

echo "[ok] 已更新 $HUGO_CONFIG"
echo "[next] 运行："
echo "  cd $ROOT_DIR"
echo "  HUGO_CACHEDIR=\"\$PWD/.hugo_cache\" hugo --minify --gc"
echo "  git add -A && git commit -m \"chore(chatbot): configure worker api proxy\" && git push origin main"
