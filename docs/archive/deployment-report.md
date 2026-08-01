# GlowFit — Deployment System Analysis
Generated: 2026-07-26 · Read-only audit, nothing changed

## Scope

This report covers everything discovered in the repo related to deployment: `api/deploy.sh`, `api/ecosystem.config.cjs` (PM2), `server/nginx/glowfit30-subdomains.conf`, `server/scripts/setup-subdomains.sh`, `server/SERVER_SETUP_SUMMARY.md`, `server/STATUS.txt`, and a repo-wide search for systemd units and webhook handlers.

**VPS facts** (from `server/SERVER_SETUP_SUMMARY.md`): Ubuntu 22.04.5 LTS, public IP `139.84.149.147`, hostname `api-glowfit`, sits behind Cloudflare for `glowfit30.com` subdomains.

---

## Component-by-Component Findings

### `deploy.sh`

Location: `api/deploy.sh` — covers **only the Express API**, nothing for the Next.js admin app.

```
git fetch/checkout/pull --ff-only
  → npm ci --omit=dev
  → npx prisma migrate deploy
  → npx prisma generate
  → pm2 start ecosystem.config.cjs --only glowfit-api || true
  → pm2 restart glowfit-api
  → pm2 save
```

- Reasonably well-written: `set -Eeuo pipefail`, pre-flight checks that `git/npm/npx/pm2` exist, fails loudly with clear messages, uses `--ff-only` (won't silently create a merge commit or diverge).
- **It is never invoked by anything** — no cron, no webhook, no CI step, no systemd timer. It is a manual runbook: someone must SSH in and run `bash deploy.sh` by hand.
- No equivalent script exists for the admin (`backend/`) app — that app is deployed via a **manual tar-and-SSH process** (per `SERVER_SETUP_SUMMARY.md`: package locally → upload → extract → `npm ci` → `prisma generate` → `npm run build` → `pm2 start`), not scripted at all.
- No rollback step, no health-check-after-restart step, no lockfile-based mutex against two people/processes running it concurrently.

### Webhook

**Does not exist.** A repo-wide, case-insensitive search for "webhook" (filenames + code + docs) returns **zero matches**. There is no Express route, no standalone receiver, no GitHub App configuration, no signature-verification code anywhere. Nothing listens for GitHub push events, so nothing can trigger `deploy.sh` automatically.

### systemd

**No custom systemd unit files exist in the repo** (`find -iname "*.service"` and any path containing "systemd" both return nothing). The only systemd involvement is indirect: PM2's own startup integration was configured on the VPS during setup, which generates a systemd service named `pm2-sprsadmin` (confirmed running/enabled per `SERVER_SETUP_SUMMARY.md` §4 and "Current Service State"). This service's job is solely to relaunch PM2 itself (and whatever process list `pm2 save` persisted) on server reboot — it is not a per-app systemd unit and isn't checked into the repo, so it's **not reproducible from source** if the VPS were rebuilt.

### PM2

`api/ecosystem.config.cjs`:
```js
{
  name: 'glowfit-api',
  cwd: __dirname,
  script: 'src/index.js',
  instances: 1,
  exec_mode: 'fork',
  autorestart: true,
  watch: false,
  max_memory_restart: '400M',
  env_production: { NODE_ENV: 'production' },
}
```
- Single fork-mode instance, autorestart on, 400MB memory cap, no file-watching (correct for production).
- **No `out_file`/`error_file`** → falls back to PM2's default log paths (`~/.pm2/logs/glowfit-api-{out,error}.log`) — not centralized, not rotated (no `pm2-logrotate` module mentioned anywhere), and not part of the repo's log/monitoring story.
- **No `env_production` values beyond `NODE_ENV`** — `PORT`, `DATABASE_URL`, `JWT_SECRET`, etc. all come from `api/.env` on the server (fine, but means the ecosystem file alone can't reproduce a working deployment; `.env` is a manually-created, unversioned artifact per `SERVER_SETUP_SUMMARY.md` §11).
- **The admin app (`glowfit-backend`) has no ecosystem file at all.** Per `SERVER_SETUP_SUMMARY.md`, it was started with an ad hoc `pm2 start ... --name glowfit-backend` command directly on the server — this process definition lives only in `pm2 save`'s dump file on the VPS, not in git. If that dump is ever lost (disk issue, `pm2 kill`, server rebuild), the admin app's PM2 config has to be reconstructed from memory/docs, not `git pull` + one command.
- Both apps run as a **single fork instance** — fine at current scale, but the API's Redis-backed... actually the API's rate-limiting and stats-cache are in-memory (not Redis-backed for rate limiting), so this single-instance setup is a hidden assumption: scaling to cluster mode later would silently break per-IP rate limits and stale the `admin:stats` cache logic unless revisited.

### NGINX

`server/nginx/glowfit30-subdomains.conf`, installed via `server/scripts/setup-subdomains.sh`:

- Two `server {}` blocks, **subdomain-based routing** (not path-based):
  - `admin.glowfit30.com` → `proxy_pass http://127.0.0.1:3000` (includes `Upgrade`/`Connection: upgrade` headers for websockets/HMR)
  - `api.glowfit30.com` → `proxy_pass http://127.0.0.1:4000`
- Cloudflare-aware: large `set_real_ip_from` allowlist of Cloudflare edge ranges + `real_ip_header CF-Connecting-IP`, so `X-Real-IP`/rate-limiting/logging see the real client IP instead of Cloudflare's.
- **Both blocks are `listen 80` / `listen [::]:80` only** — as committed, this config has **no HTTPS/443 server blocks whatsoever**. TLS is meant to be bolted on afterward by running `certbot --nginx`, which auto-edits the live `/etc/nginx/sites-available/...` file on the server — meaning **the certbot-modified, HTTPS-capable version of this config is not reflected back into the repo**. If the server were rebuilt from this repo alone, it would come up HTTP-only again.
- No `client_max_body_size` directive — nginx's default is 1MB, but the API allows video uploads up to 100MB (`api/src/modules/uploads`). Unless Cloudflare or a since-added nginx override handles this, **uploads over 1MB would be rejected by nginx with a 413** before ever reaching Express. Nothing in the repo confirms this was fixed.
- No `gzip` directives — not a functional bug, just a missed easy win for response size/latency.
- The setup script (`setup-subdomains.sh`) installs the conf, disables the default site, opens 80/443 in `ufw` if active, runs `nginx -t`, and reloads — but is a manual, one-time script (`bash server/scripts/setup-subdomains.sh` run by hand over SSH), not idempotent-by-design tooling that's re-run on every deploy.

### SSL

- **No certificate material, certbot config, or renewal hook is in the repo** (expected — certs shouldn't be committed — but there's also no `certbot renew` cron/systemd-timer verification anywhere in the docs, and the committed nginx conf has zero 443 blocks to renew in the first place).
- The last recorded live status (`server/STATUS.txt`, dated 2026-04-09 — same day as `SERVER_SETUP_SUMMARY.md`) shows:
  ```
  https://api.glowfit30.com     → Cloudflare 521 (origin not OK for CF → origin handshake)
  https://admin.glowfit30.com   → Cloudflare 521 (same)
  http://139.84.149.147/        → HTTP 307 (origin reachable on port 80)
  ```
  i.e., at that point in time, HTTPS was **not working** on either subdomain — the origin had nothing listening on 443, consistent with the nginx conf having no HTTPS blocks yet and certbot not yet run.
- **There is no later status file or record in the repo confirming certbot was ever successfully run and HTTPS fixed.** Given the deployment flow depends entirely on manual SSH steps that leave no trace in git, the current live TLS state is **unverifiable from the repository alone** — it may be fixed now, or may still be broken; nothing here proves either way.
- Cloudflare SSL/TLS mode needs to be "Full (strict)" only *after* a valid origin cert exists — `STATUS.txt` explicitly warns that mismatched Cloudflare SSL mode + missing origin cert is what produces the 521.

### GitHub Webhook

Same finding as "Webhook" above, reiterated because it was asked separately: **there is no GitHub webhook configured or coded anywhere.** No `.github/workflows/` directory exists either (confirmed — `.github` isn't present at all), so there's no GitHub Actions-based deploy trigger as an alternative. A `git push` to `origin/main` today has **zero automated effect** on either server process.

---

## What Works

- `api/deploy.sh` is a solid, safe, well-guarded script *when run manually* — fail-fast checks, `--ff-only` pull, correct ordering (migrate before generate before restart), `pm2 save` for reboot persistence.
- PM2 process management for the API: single fork instance, autorestart, memory cap, and boot-time relaunch via the `pm2-sprsadmin` systemd integration.
- NGINX reverse proxy correctly routes both subdomains to the right local ports and correctly restores real client IPs behind Cloudflare.
- Firewall (`ufw`) + `fail2ban` are enabled on the VPS with sane inbound rules (22/80/443 only) and an active SSH jail.
- PostgreSQL and Redis are both bound to localhost only — not exposed to the public internet, which is good baseline hardening.
- Prisma migrations are applied via `prisma migrate deploy` (the correct production command, not `db push`) inside `deploy.sh`.
- Setup automation exists for the one-time nginx install (`setup-subdomains.sh`) — idempotent enough to re-run safely (`ln -sf`, `|| true` guards, `ufw allow` is a no-op if already allowed).

## What Doesn't Work

- **No auto-deploy pipeline exists at all** — no webhook, no GitHub Actions, no cron/systemd timer calling `deploy.sh`. Every deploy is 100% manual SSH.
- **The admin app (`backend/`) has no deploy script and no ecosystem file** — its entire deployment is an undocumented-in-git, manual tar/upload/build/PM2-start sequence.
- **HTTPS was confirmed broken** as of the last recorded status check (`STATUS.txt`, 2026-04-09), with no later evidence it was fixed — both public subdomains returned Cloudflare 521.
- **The committed nginx config has no 443/SSL blocks** — even if certbot was run on the live server since, that fix isn't reflected back into version control, so redeploying nginx from this repo today would regress HTTPS again.
- **No `client_max_body_size` override** — likely blocks the API's own 100MB video-upload feature at the nginx layer with a 413, unless a fix exists only on the live server and not in the repo.
- **PM2 process definitions for the admin app live only in the server's local `pm2 save` dump**, not in git — not reproducible from source control.

## Potential Failures

1. **Silent HTTPS regression**: if anyone reprovisions the VPS or re-runs `setup-subdomains.sh` from this repo, they get HTTP-only nginx again, since the certbot-added 443 blocks (if they exist live) aren't in the committed file.
2. **413 Payload Too Large on uploads**: nginx's default 1MB body cap vs. the API's advertised 100MB video-upload limit — a likely mismatch that would only surface when someone actually uploads a large video in production.
3. **Deploy script drift/human error**: because `deploy.sh` is only ever run by hand, there's no guarantee it's actually run consistently (or at all) after every push — code sitting on `origin/main` can silently diverge from what's actually live for arbitrary lengths of time, with nothing in the repo to detect that drift.
4. **No deploy mutex**: if `deploy.sh` (or the manual admin-app process) is triggered twice concurrently (e.g., two people SSH in at once), there's no lock file or check preventing overlapping `git pull` / `prisma migrate deploy` / `pm2 restart` runs, which could corrupt the working tree or race a migration.
5. **PM2 process list loss**: `pm2 save` persists the process list to a local dump file on the VPS (not backed up per the repo's notes) — if that file is lost (disk failure, accidental `pm2 kill`, VPS rebuild) the admin app's entire PM2 definition (name, port, cwd, env) must be manually reconstructed from `SERVER_SETUP_SUMMARY.md`, since it's not in git.
6. **No rollback path**: `deploy.sh` has no "previous release" concept (no releases directory, no tagged rollback) — a bad `git pull` + broken migration has no automated undo; recovery is entirely manual.
7. **`prisma migrate deploy` failure mid-deploy**: if a migration fails, `set -e` will abort the script *after* `npm ci` already updated `node_modules` but *before* `pm2 restart` — leaving the old process running against new (partially applied or unapplied) schema/dependencies until someone notices and intervenes.
8. **Root SSH + password auth still enabled** (`SERVER_SETUP_SUMMARY.md` explicitly flags this as pending hardening) — increases the blast radius if the VPS is ever compromised, which would also compromise the entire manual deploy trust chain (anyone with root can edit `deploy.sh`, nginx config, or PM2 processes directly).
9. **Health-check gap**: nothing in `deploy.sh` verifies the app actually came back up healthy after `pm2 restart` (e.g., curling `GET /` and checking for `200`) — a broken deploy would show as "deployment completed successfully" in the log even if the app immediately crash-loops.

## Security Improvements

1. **Rotate the `sprsadmin` Linux password and the PostgreSQL `glowfit_user` password immediately** — both are recorded in plaintext in `server/SERVER_SETUP_SUMMARY.md`, which is a git-tracked file in this repository (already flagged in the earlier technical/security audit as pushed to a public-ish GitHub remote). Anyone with read access to the repo has current, working server credentials.
2. **Disable root SSH login and password authentication** — explicitly called out as "still pending" in the setup doc; switch to key-only auth and a non-root sudo user exclusively.
3. **Finish and verify TLS**: run/confirm `certbot --nginx -d admin.glowfit30.com -d api.glowfit30.com`, add the resulting 443 blocks *back into the committed nginx config* (or template them) so the repo is the actual source of truth, then set Cloudflare to "Full (strict)".
4. **Add a certbot auto-renewal check** (systemd timer `certbot.timer` is installed by the certbot package by default, but there's no confirmation of this in the repo/docs) — verify `sudo certbot renew --dry-run` succeeds and is scheduled.
5. **Add `client_max_body_size 100m;`** (or match whatever the real upload ceiling is) to the API server block so large video uploads aren't silently rejected at the proxy layer.
6. **Introduce a real deploy trigger** — either a GitHub Actions workflow that SSHes in and runs `deploy.sh` on push to `main`, or a signed/secret-verified webhook endpoint that does the same. Either removes the "someone has to remember to SSH in" failure mode and creates an audit trail (CI logs) of every deploy.
7. **Add deploy locking** (e.g., `flock` around `deploy.sh`'s body) to prevent concurrent runs.
8. **Add a post-restart health check** to `deploy.sh` (curl the health endpoint, exit non-zero and alert if it doesn't return 200 within N seconds) so bad deploys are caught immediately instead of discovered by users.
9. **Version the admin app's PM2 definition**: add an `ecosystem.config.cjs` for `backend/` (mirroring the API's) so its process definition is reproducible from git instead of living only in a server-side `pm2 save` dump.
10. **Centralize and rotate PM2 logs**: configure `out_file`/`error_file` paths (or install `pm2-logrotate`) instead of relying on unmanaged default log growth.
11. **Set up backups** for PostgreSQL (and ideally the Redis cache is fine to skip, it's ephemeral) — explicitly listed as "not yet completed" in the setup doc; a VPS-level failure currently has no recovery path for data.
12. **Purge/rotate the credentials in `server/SERVER_SETUP_SUMMARY.md`** from git history (not just the working tree) if this repository is or could become public, since git history retains old blob content even after a file is edited or deleted.

## Deployment Flow

### As documented/intended (`docs/ARCHITECTURE.md`, per the earlier codebase audit)
```
git push → server pulls latest → rebuild → PM2 restart
```

### As actually implemented today (reconstructed from the files that exist)

**API (`api/`) — semi-scripted, fully manual trigger:**
```
Developer pushes to origin/main
        │
        ▼  (no automatic trigger — human must SSH in)
Operator SSHes into VPS (139.84.149.147)
        │
        ▼
bash api/deploy.sh
        │
        ├─ git fetch/checkout/pull --ff-only origin main
        ├─ npm ci --omit=dev
        ├─ npx prisma migrate deploy
        ├─ npx prisma generate
        ├─ pm2 start ecosystem.config.cjs --only glowfit-api  (if not running)
        ├─ pm2 restart glowfit-api
        └─ pm2 save
        │
        ▼
nginx (already running, unchanged) proxies api.glowfit30.com → 127.0.0.1:4000
        │
        ▼
Cloudflare (already configured, unchanged) fronts api.glowfit30.com
```

**Admin (`backend/`) — fully manual, not scripted at all:**
```
Developer pushes to origin/main
        │
        ▼  (no trigger of any kind)
Developer builds a tarball locally, excluding .git/node_modules/.next/.env
        │
        ▼
Uploads tarball to VPS over SSH/SCP
        │
        ▼
Operator manually: extract → create .env → npm ci → npx prisma generate → npm run build → pm2 start (ad hoc name/port) → pm2 save
        │
        ▼
nginx proxies admin.glowfit30.com → 127.0.0.1:3000
```

**Common infra, set up once and not touched by any deploy step:**
```
Cloudflare (DNS + proxy, CF IP allowlist baked into nginx)
   │
   ▼
NGINX (server/nginx/glowfit30-subdomains.conf, installed once via setup-subdomains.sh)
   │  HTTP only as committed; HTTPS depends on an unverified/undocumented certbot run
   ▼
PM2 (glowfit-api on :4000, glowfit-backend on :3000)
   │  fail2ban + ufw guard SSH/80/443; pm2-sprsadmin systemd unit relaunches PM2 on reboot
   ▼
PostgreSQL (localhost:5432) + Redis (localhost:6379), both private
```

**Bottom line:** there is a working, reasonably competent *manual* deployment process for the API, and an even more manual, unscripted one for the admin panel — but no automated pipeline connects a `git push` to either server. The system should be described as "deploy-by-SSH-runbook," not "CI/CD" or "auto-deploy," until a webhook or CI trigger is added.
