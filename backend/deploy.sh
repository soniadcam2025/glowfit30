#!/usr/bin/env bash
set -Eeuo pipefail

APP_DIR="${APP_DIR:-/var/www/glowfit/backend}"
BRANCH="${BRANCH:-main}"
# Must match the PM2 process actually serving production on :3001.
# Was `glowfit-backend` until 2026-08-02 — a process that had never started
# successfully, so every deploy restarted a corpse and left the live admin
# serving a stale build. See ecosystem.config.cjs for the full story.
PM2_APP_NAME="${PM2_APP_NAME:-glowfit-admin}"
ADMIN_PORT="${ADMIN_PORT:-3001}"
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
pm2 restart "$PM2_APP_NAME" --update-env
pm2 save

# ── Post-restart proof ────────────────────────────────────────────────────────
# A 200 response only proves *something* is listening — it was exactly that weak
# check which hid a five-day-stale admin. These assertions prove the running
# process is serving the build we just produced, from the commit we just pulled.

log "verifying deployment"

COMMIT="$(git rev-parse --short HEAD)"
BUILD_ID="$(cat "$APP_DIR/.next/BUILD_ID" 2>/dev/null || echo 'missing')"
[[ "$BUILD_ID" == "missing" ]] && fail "no .next/BUILD_ID — the build did not produce output"

# Seconds since epoch for the build output and for the process start.
BUILD_EPOCH="$(stat -c %Y "$APP_DIR/.next/BUILD_ID")"
sleep 3   # let PM2 report the new pid/uptime

PM2_STATUS="$(pm2 jlist | node -e "
let d='';process.stdin.on('data',c=>d+=c).on('end',()=>{
  const p=JSON.parse(d).find(x=>x.name==='$PM2_APP_NAME');
  if(!p){console.log('missing 0 0');process.exit(0)}
  console.log(p.pm2_env.status, Math.floor(p.pm2_env.pm_uptime/1000), p.pid);
})")"
read -r STATUS START_EPOCH APP_PID <<<"$PM2_STATUS"

[[ "$STATUS" == "online" ]] || fail "$PM2_APP_NAME is '$STATUS' after restart"

# The decisive check: the process must have started *after* the build was
# written. If it started earlier it is still serving the previous bundle.
if (( START_EPOCH < BUILD_EPOCH )); then
  fail "$PM2_APP_NAME (pid $APP_PID) started before the current build — it is serving a stale bundle"
fi

# Confirm it owns the port we expect, so a second process cannot silently win.
if ! ss -tlnp 2>/dev/null | grep -q ":${ADMIN_PORT}\b.*pid=${APP_PID}"; then
  log "WARNING: pid $APP_PID is not the listener on :${ADMIN_PORT} — check for duplicate processes"
fi

HTTP_CODE="$(curl -s -o /dev/null -w '%{http_code}' --max-time 10 "http://127.0.0.1:${ADMIN_PORT}/login" || echo 000)"
[[ "$HTTP_CODE" == "200" ]] || fail "admin returned HTTP $HTTP_CODE on :${ADMIN_PORT}"

log "verified — commit=$COMMIT build=$BUILD_ID pid=$APP_PID port=$ADMIN_PORT http=$HTTP_CODE"
log "deployment completed successfully"
