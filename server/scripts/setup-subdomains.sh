#!/usr/bin/env bash
# Run ON the Ubuntu VPS (SSH as sudo-capable user). Cannot be run from Windows/Cursor.
# Fixes typical Cloudflare 521: nginx not serving 80/443, firewall, or apps not listening.

set -euo pipefail

CONF_NAME="glowfit30-subdomains"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# If you upload only this script, set REPO_ROOT to where glowfit30-subdomains.conf lives:
REPO_ROOT="${REPO_ROOT:-$(cd "$SCRIPT_DIR/.." && pwd)}"
SRC_CONF="$REPO_ROOT/nginx/${CONF_NAME}.conf"
DEST="/etc/nginx/sites-available/${CONF_NAME}.conf"

if [[ ! -f "$SRC_CONF" ]]; then
  echo "Missing: $SRC_CONF — copy repo server/nginx/ onto the server or set REPO_ROOT."
  exit 1
fi

echo "==> Installing NGINX site from $SRC_CONF"
sudo cp "$SRC_CONF" "$DEST"
sudo ln -sf "$DEST" "/etc/nginx/sites-enabled/${CONF_NAME}.conf"

echo "==> Disabling default site if present (optional)"
if [[ -L /etc/nginx/sites-enabled/default ]]; then
  sudo rm -f /etc/nginx/sites-enabled/default
fi

echo "==> UFW: allow HTTP/HTTPS (if ufw is active)"
if sudo ufw status 2>/dev/null | grep -q "Status: active"; then
  sudo ufw allow 80/tcp comment 'HTTP' || true
  sudo ufw allow 443/tcp comment 'HTTPS' || true
  sudo ufw status
fi

echo "==> nginx -t"
sudo nginx -t

echo "==> Reload nginx"
sudo systemctl reload nginx

echo "==> Check listeners (should show :80 and maybe :443 after certbot)"
sudo ss -tlnp | grep -E ':80|:443' || true

echo ""
echo "Next on this server:"
echo "  1) PM2: Next on 127.0.0.1:3000, API on 127.0.0.1:4000"
echo "  2) TLS (fixes Cloudflare 521 when SSL mode is Full):"
echo "       sudo apt install -y certbot python3-certbot-nginx"
echo "       sudo certbot --nginx -d admin.glowfit30.com -d api.glowfit30.com"
echo "  3) Cloudflare SSL/TLS: Full (strict) after certbot succeeds"
echo "  4) If 521 persists: ufw/host firewall must allow 80+443; apps must listen on 3000/4000"
