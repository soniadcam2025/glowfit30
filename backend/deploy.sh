#!/usr/bin/env bash
set -Eeuo pipefail

APP_DIR="${APP_DIR:-/var/www/glowfit/backend}"
BRANCH="${BRANCH:-main}"
PM2_APP_NAME="${PM2_APP_NAME:-glowfit-backend}"
LOG_PREFIX="[deploy:${PM2_APP_NAME}]"

log() {
  echo "${LOG_PREFIX} $1"
}

fail() {
  echo "${LOG_PREFIX} ERROR: $1" >&2
  exit 1
}

log "starting deployment"
cd "$APP_DIR" || fail "cannot cd to $APP_DIR"

if ! command -v git >/dev/null 2>&1; then fail "git not found"; fi
if ! command -v npm >/dev/null 2>&1; then fail "npm not found"; fi
if ! command -v npx >/dev/null 2>&1; then fail "npx not found"; fi
if ! command -v pm2 >/dev/null 2>&1; then fail "pm2 not found"; fi

log "fetching latest code (${BRANCH})"
git fetch --all --prune
git checkout "$BRANCH"
git pull --ff-only origin "$BRANCH"

log "installing dependencies"
npm ci

# NOTE: no `prisma generate` here. The admin panel never touches the database —
# it talks to the API over NEXT_PUBLIC_API_URL, and nothing under src/ imports
# @prisma/client. The prisma.config.ts / prisma/schema.prisma files are leftover
# scaffolding. Running generate here only broke the deploy (it demands a
# DATABASE_URL this app has no reason to hold).

log "building production bundle"
npm run build

log "restarting pm2 process"
pm2 start ecosystem.config.cjs --env production --only "$PM2_APP_NAME" || true
pm2 restart "$PM2_APP_NAME"
pm2 save

log "deployment completed successfully"
