#!/usr/bin/env bash
# GlowFit 30 — one-command deploy
# Usage: bash /var/www/glowfit/deploy.sh
# Or make executable once: chmod +x /var/www/glowfit/deploy.sh  →  ./deploy.sh

set -euo pipefail

# ── colours ──────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
ok()   { echo -e "${GREEN}[OK]${NC}  $*"; }
info() { echo -e "${YELLOW}[>>]${NC}  $*"; }
fail() { echo -e "${RED}[FAIL]${NC} $*"; exit 1; }

# ── config ────────────────────────────────────────────────────────────────────
ROOT_DIR="/var/www/glowfit"
API_DIR="$ROOT_DIR/api"
ADMIN_DIR="$ROOT_DIR/backend"
PM2_USER="sprsadmin"          # PM2 daemon owner on this VPS
API_PORT=3000
ADMIN_PORT=3001

pm2_cmd() { sudo -u "$PM2_USER" pm2 "$@"; }

# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  GlowFit 30 — Deploy  $(date '+%Y-%m-%d %H:%M:%S')"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ── 1. Git pull ───────────────────────────────────────────────────────────────
info "Pulling latest code from GitHub..."
cd "$ROOT_DIR"
git config --global --add safe.directory "$ROOT_DIR" 2>/dev/null || true
git stash push -m "autodeploy-$(date +%Y%m%d%H%M%S)" >/dev/null 2>&1 || true
git pull origin main || fail "git pull failed"
ok "Code up to date"

# ── 2. Backend — install deps ─────────────────────────────────────────────────
info "Installing API dependencies..."
cd "$API_DIR"
npm install --prefer-offline 2>&1 | tail -3
ok "API dependencies installed"

# ── 3. Backend — Prisma migrate ───────────────────────────────────────────────
info "Running Prisma migrations..."
npx prisma migrate deploy 2>&1 | grep -E "(migration|pending|applied|No pending|Error)" || true
ok "Prisma migrations done"

# ── 4. Backend — PM2 restart ──────────────────────────────────────────────────
info "Restarting glowfit-api..."
if pm2_cmd describe glowfit-api >/dev/null 2>&1; then
  pm2_cmd restart glowfit-api
else
  pm2_cmd start "$API_DIR/ecosystem.config.cjs" --env production
fi
sleep 2

API_STATUS=$(pm2_cmd jlist 2>/dev/null | \
  python3 -c "import sys,json; procs=json.load(sys.stdin); \
  p=[x for x in procs if x['name']=='glowfit-api']; \
  print(p[0]['pm2_env']['status'] if p else 'not_found')" 2>/dev/null || echo "unknown")

[[ "$API_STATUS" == "online" ]] || fail "glowfit-api is '$API_STATUS' after restart — check: sudo -u $PM2_USER pm2 logs glowfit-api"
ok "glowfit-api is online"

# ── 5. Backend — health check ─────────────────────────────────────────────────
info "Verifying API health..."
sleep 1
HEALTH=$(curl -s --max-time 5 "http://127.0.0.1:${API_PORT}/" || echo "")
echo "$HEALTH" | grep -q '"status":"ok"' || fail "API health check failed — response: $HEALTH"
ok "API health: $(echo "$HEALTH" | python3 -c 'import sys,json; d=json.load(sys.stdin); print(d["data"]["status"])' 2>/dev/null || echo 'ok')"

# ── 6. Admin — install deps ───────────────────────────────────────────────────
info "Installing admin panel dependencies..."
cd "$ADMIN_DIR"
npm install --prefer-offline 2>&1 | tail -3
ok "Admin dependencies installed"

# ── 7. Admin — build ─────────────────────────────────────────────────────────
info "Building Next.js admin panel (this takes ~15s)..."
rm -rf .next
npm run build 2>&1 | grep -E "(compiled|error|warn|Route|✓|✗)" || true
ok "Admin panel built"

# ── 8. Admin — PM2 restart ───────────────────────────────────────────────────
info "Restarting glowfit-admin..."
if pm2_cmd describe glowfit-admin >/dev/null 2>&1; then
  pm2_cmd restart glowfit-admin
else
  pm2_cmd start npm --name glowfit-admin -- start
fi
sleep 3

ADMIN_STATUS=$(pm2_cmd jlist 2>/dev/null | \
  python3 -c "import sys,json; procs=json.load(sys.stdin); \
  p=[x for x in procs if x['name']=='glowfit-admin']; \
  print(p[0]['pm2_env']['status'] if p else 'not_found')" 2>/dev/null || echo "unknown")

[[ "$ADMIN_STATUS" == "online" ]] || fail "glowfit-admin is '$ADMIN_STATUS' after restart — check: sudo -u $PM2_USER pm2 logs glowfit-admin"
ok "glowfit-admin is online"

# ── 9. Admin — health check ───────────────────────────────────────────────────
info "Verifying admin panel response..."
ADMIN_HTTP=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "http://127.0.0.1:${ADMIN_PORT}/")
[[ "$ADMIN_HTTP" == "200" || "$ADMIN_HTTP" == "307" || "$ADMIN_HTTP" == "308" ]] || \
  fail "Admin panel returned HTTP $ADMIN_HTTP"
ok "Admin panel responded HTTP $ADMIN_HTTP"

# ── 10. Save PM2 process list ────────────────────────────────────────────────
info "Saving PM2 process list..."
pm2_cmd save
ok "PM2 process list saved"

# ── 11. NGINX reload ─────────────────────────────────────────────────────────
info "Validating and reloading NGINX..."
sudo nginx -t 2>&1 || fail "NGINX config test failed"
sudo systemctl reload nginx || fail "NGINX reload failed"
ok "NGINX reloaded"

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "  ${GREEN}Deploy finished${NC}  $(date '+%Y-%m-%d %H:%M:%S')"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  API   →  http://127.0.0.1:${API_PORT}/"
echo "  Admin →  http://127.0.0.1:${ADMIN_PORT}/"
echo ""
echo "  Live domains (require TLS):"
echo "    https://api.glowfit30.com"
echo "    https://admin.glowfit30.com"
echo ""
pm2_cmd list
echo ""
