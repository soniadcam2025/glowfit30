# GlowFit — Deployment (Living Document)

Operational reference for how GlowFit is actually deployed today. This is the **living, continuously-updated** deployment doc (updated after any deployment-relevant change, per `PROJECT_RULES.md`). For the original point-in-time forensic audit this was built from, see `deployment-report.md`.

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
| Admin panel (Next.js) | PM2, started manually — **no committed ecosystem file** | 3000 | `admin.glowfit30.com` |
| PostgreSQL | native, localhost only | 5432 | — |
| Redis | native, localhost only | 6379 | — |

## Deployment Flow — Current Reality

```
Developer pushes to origin/main
        │
        ▼  ⚠️ NO WEBHOOK — nothing triggers automatically
Operator manually SSHes into the VPS
        │
        ▼
bash api/deploy.sh   (API only)
        │
        ├─ git fetch/checkout/pull --ff-only origin main
        ├─ npm ci --omit=dev
        ├─ npx prisma migrate deploy
        ├─ npx prisma generate
        ├─ pm2 restart glowfit-api
        └─ pm2 save
        │
        ▼
Admin app (backend/): fully manual — package tarball locally, upload, extract,
npm ci, npx prisma generate, npm run build, pm2 start (ad hoc, no ecosystem file)
```

**Target state** (see `RELEASE_PROCESS.md` → Auto Deployment, `TODO.md` 🟢 Infrastructure):
```
GitHub Push → Webhook/CI → deploy.sh → PM2 Reload → NGINX → API Health →
Admin Health → DB Connection → Redis Connection → SSL → Application Running
```
None of the automation links in this target chain exist yet — every step from "Webhook" onward today is either manual or unverified.

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

- No webhook / CI trigger — `deploy.sh` is never invoked automatically.
- No PM2 ecosystem file for the admin app.
- No deploy locking or post-restart health check in `deploy.sh`.
- No PostgreSQL backups configured.
- Root SSH login + password auth still enabled on the VPS.

---
*Last Updated: 2026-07-26. Supersedes the one-time snapshot in `deployment-report.md` as the canonical ongoing reference — `deployment-report.md` is kept as the original audit record and is not itself updated further.*
