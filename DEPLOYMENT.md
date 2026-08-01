# GlowFit — Deployment (Living Document)

Operational reference for how GlowFit is actually deployed today. This is the **living, continuously-updated** deployment doc (updated after any deployment-relevant change, per `PROJECT_RULES.md`). For the original point-in-time forensic audit this was built from, see `docs/archive/deployment-report.md`.

## Environment

| | |
|---|---|
| Provider | Vultr Cloud Compute |
| OS | Ubuntu 22.04.5 LTS |
| Hostname | `api-glowfit` |
| Public IP | `139.84.149.147` |
| CDN/Proxy | Cloudflare (in front of both public subdomains) |

## Services & Ports

| Service | Process manager | Port | Domain |
|---|---|---|---|
| `glowfit-api` (Express) | PM2 fork mode, `api/ecosystem.config.cjs` | 4000 | `api.glowfit30.com` |
| `glowfit-backend` (Next.js) | PM2 fork mode, `backend/ecosystem.config.cjs` (added 2026-07-26 — was previously ad hoc) | 3000 | `admin.glowfit30.com` |
| PostgreSQL | native, localhost only | 5432 | — |
| Redis | native, localhost only | 6379 | — |

## Deployment Flow — Current Reality (2026-07-26: now automated)

```
Developer pushes to origin/main
        │
        ▼
GitHub Actions workflow (.github/workflows/deploy.yml) triggers automatically
        │
        ├─ build-check job: npm ci + verify API loads, npm ci + tsc + lint for Admin
        │  (deploy is blocked if this fails)
        │
        ├─ deploy job: SSHes into the VPS (appleboy/ssh-action, using
        │  VPS_HOST/VPS_USER/VPS_SSH_KEY GitHub secrets) and runs:
        │    bash /var/www/glowfit/api/deploy.sh       (git pull → npm ci →
        │      prisma migrate deploy → prisma generate → pm2 restart glowfit-api)
        │    bash /var/www/glowfit/backend/deploy.sh   (git pull → npm ci →
        │      prisma generate → npm run build → pm2 restart glowfit-backend)
        │
        └─ verify job: curls both public health endpoints; fails the workflow
           run (visible in GitHub Actions) if either doesn't respond correctly
```

**One-time setup required before this actually runs** (I cannot do this — no access to your GitHub account settings): add 3 repo secrets in GitHub → Settings → Secrets and variables → Actions:
- `VPS_HOST` — `139.84.149.147`
- `VPS_USER` — `sprsadmin`
- `VPS_SSH_KEY` — a private key whose matching public key is authorized on the VPS for that user (generate a dedicated deploy keypair, don't reuse a personal one)

Until those secrets exist, every push to `main` will show a **failed** Actions run at the `deploy` step (the `build-check` job will still pass) — that's expected, not a bug, until the one-time secret setup is done.

**Assumption flagged, please confirm:** `backend/deploy.sh` assumes the admin app is checked out at `/var/www/glowfit/backend` in the same git working tree as `/var/www/glowfit/api` (i.e., one repo clone with both as subdirectories) and that its PM2 process is named `glowfit-backend`. This matches `api/deploy.sh`'s existing `APP_DIR` default and `server/SERVER_SETUP_SUMMARY.md`'s process name — but I have no live SSH access to verify it against the actual server, so if the real layout differs, the `APP_DIR`/`PM2_APP_NAME` env vars on both scripts can be overridden without editing the scripts themselves.

## NGINX

`server/nginx/glowfit30-subdomains.conf` — subdomain-based routing, Cloudflare-aware (`set_real_ip_from` allowlist). **As committed: HTTP (port 80) only, no 443/SSL blocks.** No `client_max_body_size` override (default 1MB — likely rejects the API's 100MB video-upload endpoint at the proxy layer; tracked in `TODO.md`).

## SSL / HTTPS

**Status: ✅ verified live and working (checked 2026-07-26).** `https://api.glowfit30.com/` returns a valid JSON health payload (`glowfit-api`, uptime ~1,107,517s ≈ 12.8 days) and `https://admin.glowfit30.com/` serves the Next.js admin app shell — both over HTTPS with no Cloudflare 521/522 or SSL errors. This supersedes the earlier `server/STATUS.txt` (2026-04-09) record of both subdomains failing — TLS was evidently completed sometime between then and now, just never recorded back into the repo. The committed nginx config (`server/nginx/glowfit30-subdomains.conf`) still shows HTTP-only server blocks — **the live, certbot-modified config on the VPS is still not reflected back into git**; pulling this repo's nginx config onto a fresh server would regress HTTPS. Recommend pulling the actual live config back into the repo the next time anyone has VPS access.

## Health Check Commands

```bash
curl -sI https://api.glowfit30.com/       # expect 200 + JSON health payload
curl -sI https://admin.glowfit30.com/     # expect 200/3xx from Next.js
pm2 status                                 # both glowfit-api and glowfit-backend should show "online"
```

## Known Gaps (tracked in TODO.md 🟢 Infrastructure)

- ~~No webhook / CI trigger~~ — **fixed 2026-07-26**, see GitHub Actions flow above (pending the one-time secret setup).
- ~~No PM2 ecosystem file for the admin app~~ — **fixed 2026-07-26**, `backend/ecosystem.config.cjs` added.
- No deploy locking (concurrent deploys could still race if triggered by two rapid pushes — the workflow's `concurrency` group queues GitHub Actions runs but doesn't lock the shell scripts themselves against a manual SSH run happening at the same time).
- No PostgreSQL backups configured.
- Root SSH login + password auth still enabled on the VPS.

---
*Last Updated: 2026-07-26. Supersedes the one-time snapshot in `docs/archive/deployment-report.md` as the canonical ongoing reference — `docs/archive/deployment-report.md` is kept as the original audit record and is not itself updated further.*
