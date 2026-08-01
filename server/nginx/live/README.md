# Live nginx configs (mirrored from production)

These four files are **verbatim copies of what is actually running** on the VPS
(`139.84.149.147`), pulled 2026-08-01 from `/etc/nginx/sites-enabled/`.

| File | server_name | Backend |
|---|---|---|
| `api.conf` | `api.glowfit30.com` | proxy → `127.0.0.1:3000` (Express API) |
| `admin.conf` | `admin.glowfit30.com` | proxy → `127.0.0.1:3001` (Next.js admin) |
| `glowfit-web.conf` | `glowfit30.com`, `www.glowfit30.com` | static files from `/var/www/glowfit/web/current` |
| `glowfit.conf` | `_` (default_server) | proxy → `127.0.0.1:3000` — legacy catch-all |

All three named vhosts terminate TLS via certbot and 301 HTTP→HTTPS.

## ⚠️ Ports differ from the old combined config

`../glowfit30-subdomains.conf` claims **api→4000, admin→3000**. That is **wrong**.
Production runs **api→3000, admin→3001**. Applying the old file (e.g. via
`server/scripts/setup-subdomains.sh`) would point `api.glowfit30.com` at the admin
panel and break `admin.glowfit30.com` entirely, as well as strip all TLS blocks.
Treat that script as unsafe until it is rewritten to deploy these files instead.

## Landing page deploys

`glowfit-web.conf` serves whatever `/var/www/glowfit/web/current` points at.
Deploys extract a build into `/var/www/glowfit/web/releases/<timestamp>/` and flip
the `current` symlink atomically, keeping the last 5 releases. Source repo:
<https://github.com/mayax2O/glowfit-homepage> (Vite + React, pnpm, builds to `dist/`).

To roll back: `ln -sfn /var/www/glowfit/web/releases/<older> /var/www/glowfit/web/current`
(no nginx reload needed).

A backup of the pre-landing-page config set is at `/root/nginx-backup-20260801/` on the VPS.
