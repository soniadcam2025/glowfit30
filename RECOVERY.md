# GlowFit 30 — Disaster Recovery

How to bring GlowFit 30 back on a **new Ubuntu VPS** (or set up a fresh development machine) from GitHub plus a small set of separately-held secrets. Database specifics are in [`BACKUP_RESTORE.md`](BACKUP_RESTORE.md); day-to-day deploys are in [`DEPLOYMENT.md`](DEPLOYMENT.md).

Last reviewed: 2026-10-14, against production at commit `ab3f681` (Ubuntu 22.04.5, Node 24.14.1, PM2 6.0.14, PostgreSQL 14.24, Redis 6.0.16, nginx 1.18.0).

## 1. What comes from GitHub vs. what you must supply

| Comes from GitHub (`soniadcam2025/glowfit30`, **public**) | Must be supplied separately |
|---|---|
| API source (`api/`), Prisma schema + all migrations | **Database backup** — private repo `soniadcam2025/glowfit30-backups` (release assets, encrypted) |
| Admin panel source (`backend/`) | **Backup private key** — owner's custody (see BACKUP_RESTORE.md). Without it the backups are unreadable |
| Flutter app (`flutter_app/`), incl. `google-services.json` / `firebase_options.dart` (client config, not secret) | **`api/.env` values**: DB password, `JWT_SECRET`, Firebase service-account JSON, Vultr S3 keys + bucket names |
| nginx configs as running in production (`server/nginx/live/`) | **`backend/.env`**: `NEXT_PUBLIC_API_URL` (not secret, but not committed) |
| PM2 ecosystem files, deploy scripts, CI workflow (`.github/workflows/deploy.yml`) | **GitHub Actions secrets** `VPS_HOST`, `VPS_USER`, `VPS_SSH_KEY` (re-point at the new server) |
| Cloudflare media Worker (`infra/cloudflare/`) | **Cloudflare account** (DNS for `glowfit30.com`, Worker route for `media.`) |
| Backup/restore/setup scripts (`server/scripts/`), backup **public** key | **Vultr account** (Object Storage buckets holding every image and video) |
| Webhook deploy (legacy) script + unit (`server/webhook/`) | Webhook HMAC secret (only if you keep the legacy webhook) |
| | Landing page source — separate repo `mayax2O/glowfit-homepage` |
| | Android signing — none exists yet (APKs are debug-signed) |

Media files are **not** on the VPS — they live in Vultr Object Storage — so a lost VPS does not lose media. A lost Vultr account would.

## 2. Recover production on a new VPS

Commands are run on the new server as root unless noted. Ubuntu 22.04 matches production; 24.04 should work but is untested.

### 2.1 Get the code

```bash
apt-get update && apt-get install -y git
git clone https://github.com/soniadcam2025/glowfit30.git /var/www/glowfit
```

### 2.2 Base setup (first pass)

```bash
bash /var/www/glowfit/server/scripts/setup-vps.sh
```

It installs nginx, PostgreSQL, Redis, certbot, Node 24 and PM2, creates the `sprsadmin` app user, checks PostgreSQL is listening on localhost only — and then **stops** at the first thing it cannot do for you. Each stop prints the exact command; fix it and re-run. It is idempotent.

### 2.3 Database role + restore

```bash
sudo -u postgres createuser --pwprompt glowfit_user        # NEW strong password → goes in api/.env
```

Fetch the latest backup — from your own machine, `gh` logged in as the owner:

```bash
gh release list --repo soniadcam2025/glowfit30-backups --limit 5
gh release download <tag> --repo soniadcam2025/glowfit30-backups
scp glowfit_db-*.dump.gpg glowfit_db-*.dump.gpg.sha256 glowfit-backup-PRIVATE-key.asc root@<new-ip>:/root/
```

Then on the server:

```bash
chmod 600 /root/glowfit-backup-PRIVATE-key.asc
PRIVATE_KEY=/root/glowfit-backup-PRIVATE-key.asc \
  bash /var/www/glowfit/server/scripts/restore-db.sh /root/glowfit_db-<UTC>.dump.gpg glowfit_db glowfit_user
shred -u /root/glowfit-backup-PRIVATE-key.asc /root/glowfit_db-*.dump.gpg
```

The restore refuses to touch an existing database, verifies the checksum, restores in one transaction and prints row counts — check they look right (19 tables; users, workouts, media_assets non-zero).

### 2.4 Secrets → `.env` files

```bash
cd /var/www/glowfit
cp api/.env.example api/.env          # fill in every value from your secret store
cp backend/.env.example backend/.env  # NEXT_PUBLIC_API_URL=https://api.glowfit30.com
chmod 600 api/.env backend/.env
```

Production values that are not secret: `NODE_ENV=production`, `PORT=3000`, `DATABASE_URL=postgresql://glowfit_user:<password>@127.0.0.1:5432/glowfit_db`, `REDIS_URL=redis://127.0.0.1:6379`, `CORS_ORIGINS=https://admin.glowfit30.com`, `MEDIA_CDN_BASE=https://media.glowfit30.com`.

### 2.5 Finish setup (second pass)

```bash
bash /var/www/glowfit/server/scripts/setup-vps.sh
```

This time it installs dependencies, runs `prisma migrate deploy` (a no-op on a restored DB), builds the admin, starts `glowfit-api` (port 3000) and `glowfit-admin` (port 3001) under PM2 as `sprsadmin`, enables PM2 on boot, writes HTTP nginx vhosts for `api.` and `admin.`, and health-checks both locally. Add `ENABLE_UFW=1` to restrict inbound traffic to 22/80/443.

### 2.6 DNS + TLS

1. In Cloudflare, point `api`, `admin`, `@` and `www` A records at the new IP. Keep `media` as it is (it is a Worker route, not the VPS).
2. Issue certificates. If Cloudflare's "Always Use HTTPS" is on, the HTTP challenge can fail before the server has a cert — set the records to **DNS only** (grey cloud) for the issuance, then back to proxied:
   ```bash
   certbot --nginx -d api.glowfit30.com -d admin.glowfit30.com
   ```
   certbot rewrites the vhosts into the same shape as `server/nginx/live/api.conf` / `admin.conf`, and installs its renewal timer.
3. Cloudflare SSL/TLS mode should be **Full (strict)** once the origin has its certificates.

### 2.7 Landing page (`glowfit30.com`)

Not in this repo. Build `mayax2O/glowfit-homepage` (`pnpm install && pnpm build`), copy `dist/` to `/var/www/glowfit/web/releases/<timestamp>/`, `ln -sfn` it to `/var/www/glowfit/web/current`, install `server/nginx/live/glowfit-web.conf` minus its certbot lines, then `certbot --nginx -d glowfit30.com -d www.glowfit30.com`.

### 2.8 Re-attach automatic deploys

Deploys run from **GitHub Actions** (`.github/workflows/deploy.yml`): on every push to `main` it builds, SSHes in as `VPS_USER`, runs `api/deploy.sh` and `backend/deploy.sh`, then `server/scripts/verify-deployment.sh <sha>`.

1. Generate a dedicated deploy keypair; put the public half in `/home/sprsadmin/.ssh/authorized_keys`.
2. In GitHub → `glowfit30` → Settings → Secrets → Actions, update `VPS_HOST` (new IP), `VPS_USER` (`sprsadmin`), `VPS_SSH_KEY` (private half).
3. Run the workflow manually (Actions → Deploy to Production → Run workflow) and confirm all three jobs are green.

The older **webhook** path (`server/webhook/`, `webhook.service` on port 9000, running `/var/www/glowfit/deploy.sh`) still runs on the current VPS but has not deployed since 2026-07-26. Do not recreate it on a new server unless you deliberately want it: two deploy mechanisms firing on the same push race each other.

### 2.9 Backups on the new server

Install the nightly job from BACKUP_RESTORE.md → "Nightly backups" and take one manual backup immediately.

### 2.10 Verify

```bash
curl -s https://api.glowfit30.com/            # {"success":true,"data":{"status":"ok",...}}
curl -sI https://admin.glowfit30.com/login    # 200
curl -s -o /dev/null -w '%{http_code}\n' https://api.glowfit30.com/api/workouts   # 401 (auth working)
bash /var/www/glowfit/server/scripts/verify-deployment.sh "$(git -C /var/www/glowfit rev-parse HEAD)"
```

Then log into the admin panel with a real admin account and check the dashboard shows data, and open the Android app against production.

## 3. Development machine (VS Code / Cursor / Claude Code)

```bash
git clone https://github.com/soniadcam2025/glowfit30.git && cd glowfit30
# API (Node 24)
cd api && npm ci && cp .env.example .env    # PORT=4000 locally; see below for DATABASE_URL
npx prisma generate && npm run dev
# Admin (Next.js) — separate terminal
cd backend && npm ci && echo "NEXT_PUBLIC_API_URL=http://localhost:4000" > .env && npm run dev   # :3000
# Flutter (stable channel; debug builds call http://10.0.2.2:4000/api from the Android emulator)
cd flutter_app && flutter pub get && flutter run
```

**Database for development — read this.** Historically local development connected to the **production** database through an SSH tunnel (`api/start-db-tunnel.bat`, local port 5433). Anything written that way is live data. Prefer a local PostgreSQL 14+ restored from a backup instead:

```bash
sudo -u postgres createuser --pwprompt glowfit_user
PRIVATE_KEY=~/glowfit-backup-PRIVATE-key.asc sudo -E bash server/scripts/restore-db.sh <backup>.dump.gpg glowfit_dev glowfit_user
# DATABASE_URL=postgresql://glowfit_user:<pw>@127.0.0.1:5432/glowfit_dev
```

Never run `prisma migrate dev` against production — hand-write migrations (see `TODO.md`, schema drift).

## 4. Known gaps that affect recovery

- **Nightly off-server backups are not installed yet** — only the 2026-10-14 snapshot exists. Until they are, any data written after that date is unrecoverable if the VPS is lost.
- **Credentials in public git history.** `server/SERVER_SETUP_SUMMARY.md`, `VPS` and `help` held passwords before they were redacted/untracked on 2026-10-14; the old values remain in history. Treat them as compromised and rotate.
- `setup-vps.sh` has been syntax-checked but **not yet run end-to-end on a fresh VPS**. Do a rehearsal on a throwaway instance before you need it for real.
- No Android release keystore exists; when one is created, it must be stored like the backup private key.
- Media in Vultr Object Storage has no second copy (BACKUP_RESTORE.md → "Media").
