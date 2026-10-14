#!/usr/bin/env bash
#
# Prepare a fresh Ubuntu 22.04/24.04 VPS to run GlowFit 30 from this repository.
#
# Idempotent: every step checks before acting, so it is safe to re-run after
# fixing whatever made it stop. It never creates, drops or overwrites a
# database, never writes secrets, and never touches SSH or the firewall
# unless asked (ENABLE_UFW=1).
#
# Prerequisite (the script lives in the repo, so clone first):
#   sudo apt-get update && sudo apt-get install -y git
#   sudo git clone https://github.com/soniadcam2025/glowfit30.git /var/www/glowfit
#   sudo bash /var/www/glowfit/server/scripts/setup-vps.sh
#
# It stops, with instructions, at the two points that need things GitHub
# cannot provide: the database (restore a backup — see BACKUP_RESTORE.md) and
# the .env files (secrets). Supply those and run it again.
#
# Env overrides: REPO_DIR, APP_USER, NODE_MAJOR, DB_NAME, DB_ROLE, ENABLE_UFW

set -Eeuo pipefail

REPO_DIR="${REPO_DIR:-/var/www/glowfit}"
APP_USER="${APP_USER:-sprsadmin}"
NODE_MAJOR="${NODE_MAJOR:-24}"
DB_NAME="${DB_NAME:-glowfit_db}"
DB_ROLE="${DB_ROLE:-glowfit_user}"
ENABLE_UFW="${ENABLE_UFW:-0}"

step() { echo; echo "── $* ──────────────────────────────────────────"; }
ok()   { echo "  [ OK ] $*"; }
info() { echo "  [ .. ] $*"; }
stop() { echo; echo "  [STOP] $*" >&2; echo; exit 2; }

as_app() { sudo -u "$APP_USER" -H bash -lc "cd '$1' && ${*:2}"; }
pg()     { ( cd / && sudo -u postgres "$@" ); }

[[ $EUID -eq 0 ]] || stop "run as root: sudo bash $0"
[[ -d "$REPO_DIR/.git" ]] || stop "no git clone at $REPO_DIR — clone the repository there first (see header)"
grep -qi ubuntu /etc/os-release || stop "this script targets Ubuntu"

# ── 1. System packages ───────────────────────────────────────────────────────
step "1. System packages"
PKGS=(git curl ca-certificates gnupg nginx postgresql postgresql-contrib redis-server certbot python3-certbot-nginx ufw)
MISSING=()
for p in "${PKGS[@]}"; do dpkg -s "$p" >/dev/null 2>&1 || MISSING+=("$p"); done
if ((${#MISSING[@]})); then
  info "installing: ${MISSING[*]}"
  apt-get update -qq
  DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "${MISSING[@]}"
fi
ok "packages present"

# ── 2. Node.js + PM2 ─────────────────────────────────────────────────────────
step "2. Node.js $NODE_MAJOR + PM2"
if ! command -v node >/dev/null 2>&1 || [[ "$(node -v | sed -E 's/^v([0-9]+).*/\1/')" != "$NODE_MAJOR" ]]; then
  info "installing Node.js $NODE_MAJOR from NodeSource"
  curl -fsSL "https://deb.nodesource.com/setup_${NODE_MAJOR}.x" | bash -
  apt-get install -y -qq nodejs
fi
command -v pm2 >/dev/null 2>&1 || npm install -g pm2
ok "node $(node -v), pm2 $(pm2 -v)"

# ── 3. App user + ownership ──────────────────────────────────────────────────
step "3. App user ($APP_USER)"
if ! id "$APP_USER" >/dev/null 2>&1; then
  adduser --disabled-password --gecos "" "$APP_USER"
  info "created $APP_USER (no password; add your SSH key to ~$APP_USER/.ssh/authorized_keys)"
fi
# Deploy scripts run `sudo -u $APP_USER pm2 ...` and `sudo nginx -t`
if [[ ! -f /etc/sudoers.d/glowfit-deploy ]]; then
  echo "$APP_USER ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/glowfit-deploy
  chmod 440 /etc/sudoers.d/glowfit-deploy
  visudo -cf /etc/sudoers.d/glowfit-deploy >/dev/null
fi
chown -R "$APP_USER:$APP_USER" "$REPO_DIR"
git config --system --get-all safe.directory 2>/dev/null | grep -qx "$REPO_DIR" \
  || git config --system --add safe.directory "$REPO_DIR"
ok "$APP_USER owns $REPO_DIR"

# ── 4. PostgreSQL + Redis (localhost only) ───────────────────────────────────
step "4. PostgreSQL + Redis"
systemctl enable --now postgresql redis-server >/dev/null 2>&1
redis-cli ping | grep -q PONG && ok "redis responding"
PG_LISTEN="$(pg psql -At -c 'show listen_addresses')"
[[ "$PG_LISTEN" == "localhost" || "$PG_LISTEN" == "127.0.0.1" ]] \
  || stop "PostgreSQL listen_addresses is '$PG_LISTEN' — set it to 'localhost' (it must never be public)"
ok "postgres listening on $PG_LISTEN only"

ROLE_EXISTS="$(pg psql -At -d postgres -c "select 1 from pg_roles where rolname='$DB_ROLE'")"
if [[ -z "$ROLE_EXISTS" ]]; then
  stop "role '$DB_ROLE' does not exist. Create it with a NEW strong password (you will type it, it is not stored here):
           sudo -u postgres createuser --pwprompt $DB_ROLE
         then re-run this script."
fi
ok "role $DB_ROLE exists"

DB_EXISTS="$(pg psql -At -d postgres -c "select 1 from pg_database where datname='$DB_NAME'")"
if [[ -z "$DB_EXISTS" ]]; then
  stop "database '$DB_NAME' does not exist. Restore the latest backup into it (BACKUP_RESTORE.md):
           PRIVATE_KEY=/root/glowfit-backup-PRIVATE-key.asc \\
             bash $REPO_DIR/server/scripts/restore-db.sh /root/<backup>.dump.gpg $DB_NAME $DB_ROLE
         (Only for a deliberately EMPTY install: sudo -u postgres createdb -O $DB_ROLE $DB_NAME)
         then re-run this script."
fi
ok "database $DB_NAME exists"

# ── 5. Environment files (secrets — never in git) ───────────────────────────
step "5. Environment files"
for f in api/.env backend/.env; do
  [[ -f "$REPO_DIR/$f" ]] || stop "$REPO_DIR/$f is missing. Copy $f.example, fill in the real values from your secret store, chmod 600, chown $APP_USER, re-run."
  grep -qE 'replace_with|user:password@' "$REPO_DIR/$f" && stop "$REPO_DIR/$f still contains placeholder values from .env.example"
  chmod 600 "$REPO_DIR/$f"; chown "$APP_USER:$APP_USER" "$REPO_DIR/$f"
done
ok "api/.env and backend/.env present (contents not printed)"

# ── 6. API: deps, migrations, process ────────────────────────────────────────
step "6. API"
as_app "$REPO_DIR/api" "npm ci --omit=dev --no-audit --no-fund"
as_app "$REPO_DIR/api" "npx prisma generate >/dev/null"
# migrate deploy only applies committed, not-yet-applied migrations; on a
# freshly restored database it is a no-op. Never use `migrate dev` here.
as_app "$REPO_DIR/api" "npx prisma migrate deploy"
as_app "$REPO_DIR/api" "pm2 describe glowfit-api >/dev/null 2>&1 && pm2 restart glowfit-api || pm2 start ecosystem.config.cjs --env production"
ok "glowfit-api started"

# ── 7. Admin: deps, build, process ───────────────────────────────────────────
step "7. Admin panel"
as_app "$REPO_DIR/backend" "npm ci --no-audit --no-fund"
as_app "$REPO_DIR/backend" "npm run build"
as_app "$REPO_DIR/backend" "pm2 describe glowfit-admin >/dev/null 2>&1 && pm2 restart glowfit-admin || pm2 start ecosystem.config.cjs --env production"
as_app "$REPO_DIR" "pm2 save"
env PATH="$PATH" pm2 startup systemd -u "$APP_USER" --hp "/home/$APP_USER" >/dev/null
ok "glowfit-admin started, PM2 boot persistence configured"

# ── 8. NGINX (HTTP bootstrap; certbot adds TLS afterwards) ───────────────────
step "8. NGINX"
write_vhost() {  # name, server_names, upstream
  local f="/etc/nginx/sites-available/$1"
  if [[ -f "$f" ]]; then info "$1 exists — left untouched"; return; fi
  cat > "$f" <<EOF
server {
    listen 80;
    server_name $2;

    location / {
        client_max_body_size 110M;
        proxy_pass http://127.0.0.1:$3;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF
  ln -sfn "$f" "/etc/nginx/sites-enabled/$1"
  info "wrote $1"
}
write_vhost api   api.glowfit30.com   3000
write_vhost admin admin.glowfit30.com 3001
# Stock Ubuntu default site only — never remove a customised one
if [[ -L /etc/nginx/sites-enabled/default ]] && grep -q '^# Default server configuration' /etc/nginx/sites-available/default 2>/dev/null; then
  rm -f /etc/nginx/sites-enabled/default
fi
nginx -t && systemctl reload nginx
ok "nginx valid and reloaded (landing page vhost: see RECOVERY.md)"

# ── 9. Firewall (opt-in) ─────────────────────────────────────────────────────
step "9. Firewall"
if [[ "$ENABLE_UFW" == 1 ]]; then
  ufw allow 22/tcp >/dev/null; ufw allow 80/tcp >/dev/null; ufw allow 443/tcp >/dev/null
  ufw --force enable >/dev/null
  ok "ufw enabled: 22, 80, 443"
else
  info "skipped (ENABLE_UFW=1 to allow only 22/80/443)"
fi

# ── 10. Local health ─────────────────────────────────────────────────────────
step "10. Health"
sleep 3
curl -fsS --max-time 5 http://127.0.0.1:3000/ | grep -q '"status":"ok"' && ok "API healthy on :3000" || echo "  [FAIL] API not healthy — sudo -u $APP_USER pm2 logs glowfit-api"
code="$(curl -s -o /dev/null -w '%{http_code}' --max-time 10 http://127.0.0.1:3001/ || true)"
[[ "$code" =~ ^(200|307|308)$ ]] && ok "admin responding on :3001 ($code)" || echo "  [FAIL] admin returned $code — sudo -u $APP_USER pm2 logs glowfit-admin"

cat <<EOF

Next (manual, needs your accounts — see RECOVERY.md):
  1. Point DNS (Cloudflare) api/admin/@/www A records at this server's IP.
  2. sudo certbot --nginx -d api.glowfit30.com -d admin.glowfit30.com
  3. Update the GitHub Actions secret VPS_HOST (and VPS_SSH_KEY's public key in
     ~$APP_USER/.ssh/authorized_keys) so pushes to main deploy here.
  4. Install the nightly backup (BACKUP_RESTORE.md → "Nightly backups").
EOF
