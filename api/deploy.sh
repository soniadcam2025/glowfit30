#!/usr/bin/env bash
set -Eeuo pipefail

APP_DIR="${APP_DIR:-/var/www/glowfit/api}"
BRANCH="${BRANCH:-main}"
PM2_APP_NAME="${PM2_APP_NAME:-glowfit-api}"
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
npm ci --omit=dev

log "running prisma migrations"
npx prisma migrate deploy

log "regenerating prisma client"
npx prisma generate

log "restarting pm2 process"
pm2 start ecosystem.config.cjs --env production --only "$PM2_APP_NAME" || true
pm2 restart "$PM2_APP_NAME"
pm2 save

log "deployment completed successfully"
