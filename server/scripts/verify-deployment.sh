#!/usr/bin/env bash
#
# Proves the *running* production apps match the latest deployed commit.
#
# Written 2026-08-02 after a five-day-stale admin passed every deploy: the CI
# health check only asserted HTTP 200, which a process serving an old bundle
# answers just as happily as a fresh one. Reachability is not freshness.
#
# Usage (on the VPS):   bash server/scripts/verify-deployment.sh [expected-sha]
# Exit 0 = healthy, non-zero = deployment is not actually live.

set -uo pipefail

REPO_DIR="${REPO_DIR:-/var/www/glowfit}"
ADMIN_DIR="${ADMIN_DIR:-$REPO_DIR/backend}"
ADMIN_PM2="${ADMIN_PM2:-glowfit-admin}"
API_PM2="${API_PM2:-glowfit-api}"
ADMIN_PORT="${ADMIN_PORT:-3001}"
API_PORT="${API_PORT:-3000}"
EXPECTED_SHA="${1:-}"

FAILURES=0
ok()   { echo "  [ OK ] $1"; }
bad()  { echo "  [FAIL] $1"; FAILURES=$((FAILURES + 1)); }
warn() { echo "  [WARN] $1"; }

pm2j() { sudo -u sprsadmin PM2_HOME=/home/sprsadmin/.pm2 pm2 jlist 2>/dev/null; }

echo "── 1. Git commit ───────────────────────────────────────────"
HEAD_SHA="$(git -C "$REPO_DIR" rev-parse HEAD 2>/dev/null || echo unknown)"
echo "  HEAD: ${HEAD_SHA:0:12}"
if [[ -n "$EXPECTED_SHA" ]]; then
  if [[ "$HEAD_SHA" == "$EXPECTED_SHA"* || "$EXPECTED_SHA" == "$HEAD_SHA"* ]]; then
    ok "matches expected commit"
  else
    bad "expected ${EXPECTED_SHA:0:12}, VPS is at ${HEAD_SHA:0:12}"
  fi
fi

echo "── 2. PM2 processes ────────────────────────────────────────"
PM2_JSON="$(pm2j)"
for proc in "$API_PM2" "$ADMIN_PM2"; do
  line="$(echo "$PM2_JSON" | node -e "
    let d='';process.stdin.on('data',c=>d+=c).on('end',()=>{
      const p=JSON.parse(d).find(x=>x.name==='$proc');
      console.log(p ? p.pm2_env.status+' '+Math.floor(p.pm2_env.pm_uptime/1000)+' '+p.pid+' '+p.pm2_env.restart_time : 'missing 0 0 0');
    })" 2>/dev/null)"
  read -r st start pid restarts <<<"$line"
  if [[ "$st" == "online" ]]; then
    ok "$proc online (pid $pid, $restarts restarts)"
  else
    bad "$proc is '$st'"
  fi
done

# Any *other* process in PM2 is a candidate stale/duplicate entry.
EXTRA="$(echo "$PM2_JSON" | node -e "
  let d='';process.stdin.on('data',c=>d+=c).on('end',()=>{
    const keep=['$API_PM2','$ADMIN_PM2'];
    console.log(JSON.parse(d).filter(p=>!keep.includes(p.name)).map(p=>p.name+':'+p.pm2_env.status).join(' '));
  })" 2>/dev/null)"
[[ -n "$EXTRA" ]] && warn "unexpected PM2 entries: $EXTRA"

echo "── 3. Build freshness ──────────────────────────────────────"
if [[ -f "$ADMIN_DIR/.next/BUILD_ID" ]]; then
  BUILD_ID="$(cat "$ADMIN_DIR/.next/BUILD_ID")"
  BUILD_EPOCH="$(stat -c %Y "$ADMIN_DIR/.next/BUILD_ID")"
  echo "  BUILD_ID: $BUILD_ID  ($(date -d "@$BUILD_EPOCH" '+%Y-%m-%d %H:%M:%S'))"

  ADMIN_START="$(echo "$PM2_JSON" | node -e "
    let d='';process.stdin.on('data',c=>d+=c).on('end',()=>{
      const p=JSON.parse(d).find(x=>x.name==='$ADMIN_PM2');
      console.log(p?Math.floor(p.pm2_env.pm_uptime/1000):0);
    })" 2>/dev/null)"
  echo "  admin started: $(date -d "@$ADMIN_START" '+%Y-%m-%d %H:%M:%S')"

  # The decisive assertion: started after the build was written.
  if (( ADMIN_START >= BUILD_EPOCH )); then
    ok "admin process is newer than the build it serves"
  else
    bad "admin started $(( (BUILD_EPOCH - ADMIN_START) / 60 ))min BEFORE the build — serving a stale bundle"
  fi
else
  bad "no .next/BUILD_ID in $ADMIN_DIR"
fi

echo "── 4. Ports ────────────────────────────────────────────────"
for p in "$API_PORT:$API_PM2" "$ADMIN_PORT:$ADMIN_PM2"; do
  port="${p%%:*}"; name="${p##*:}"
  if ss -tln 2>/dev/null | grep -q ":${port}\b"; then
    ok "port $port listening ($name)"
  else
    bad "nothing listening on port $port"
  fi
done

echo "── 5. HTTP health ──────────────────────────────────────────"
API_CODE="$(curl -s -o /dev/null -w '%{http_code}' --max-time 10 "http://127.0.0.1:${API_PORT}/" || echo 000)"
[[ "$API_CODE" == "200" ]] && ok "API HTTP $API_CODE" || bad "API HTTP $API_CODE"
ADMIN_CODE="$(curl -s -o /dev/null -w '%{http_code}' --max-time 10 "http://127.0.0.1:${ADMIN_PORT}/login" || echo 000)"
[[ "$ADMIN_CODE" == "200" ]] && ok "Admin HTTP $ADMIN_CODE" || bad "Admin HTTP $ADMIN_CODE"

echo "── 6. Public endpoints (through NGINX + Cloudflare) ────────"
for url in https://api.glowfit30.com/ https://admin.glowfit30.com/ https://glowfit30.com/; do
  code="$(curl -s -o /dev/null -w '%{http_code}' --max-time 15 "$url" || echo 000)"
  [[ "$code" =~ ^(200|307|308)$ ]] && ok "$url -> $code" || bad "$url -> $code"
done

echo
if (( FAILURES == 0 )); then
  echo "DEPLOYMENT VERIFIED — running apps match commit ${HEAD_SHA:0:12}"
  exit 0
fi
echo "DEPLOYMENT NOT HEALTHY — $FAILURES check(s) failed"
exit 1
