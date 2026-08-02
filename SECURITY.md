# GlowFit Security Posture

## Resolved — Critical

### 2026-08-02 · Unauthenticated admin account takeover via `POST /auth/reset-password`

**Severity:** 🔴 Critical. **Status:** fixed in code, deployed 2026-08-02.

The endpoint was reachable **without any authentication** and reset any account with an `admin` or `super_admin` role to the constant `Admin12345` — a value hardcoded in `auth.controller.js`, committed to the repository, and echoed back in the success message. Knowing an admin's email address was sufficient to take over that account with a single request. The `authLimiter` rate limit (30 req/15min/IP) was no mitigation, since one request achieves the takeover.

Confirmed live against production during the readiness audit by probing with a non-existent address (no mutation performed).

**Fix:** the route now requires `verifyToken` + `requireRole('super_admin')`, and generates a 24-character cryptographically random password per call (`randomBytes(18).base64url`), returned once to the caller. The shared constant is deleted. The generic no-such-account response is retained so the endpoint cannot be used to enumerate admin emails.

**Known limitation:** this is a stop-gap, not a reset *flow*. A sole locked-out admin cannot self-serve, because a super_admin must perform the reset. A signed, time-limited OTP delivered by email is the intended replacement — blocked only on mail credentials (see `TODO.md`). Redis is already available to hold OTPs with a TTL.

**Exposure window:** the endpoint existed for the project's lifetime, so every admin password must be assumed compromised and rotated.

## Authentication

- **JWT** (`jsonwebtoken`), HS-family symmetric secret `JWT_SECRET` (Zod-enforced ≥16 chars, boot fails otherwise), payload `{ sub: user.id, role }`, expiry `JWT_EXPIRES_IN` (default 7d). No refresh-token rotation/blacklist — revocation only via `isBlocked` checked per-request.
- **Cookies**: httpOnly, `secure` in prod, `sameSite: 'none'` (prod) / `'lax'` (dev); also supports `Authorization: Bearer` fallback for the mobile app and admin-panel direct API calls.
- **Password hashing**: bcryptjs, 12 salt rounds.
- **Social login**: Firebase ID-token verification via `FIREBASE_SERVICE_ACCOUNT_JSON`.

## CORS

Allow-list from `CORS_ORIGINS` (default `https://admin.glowfit30.com`), `credentials: true`. Dev origins auto-added unless `NODE_ENV=production` (or via `CORS_ALLOW_LOCAL_DEV=true` override). Requests with no `Origin` header are always allowed (needed for the mobile app / server-to-server calls).

## Helmet

`helmet({ crossOriginResourcePolicy: { policy: 'cross-origin' } })`, otherwise v8 defaults. CORP relaxed intentionally for cross-origin media (Vultr storage).

## Rate Limiting

Global: 400 req/15min/IP. Auth-specific: 30 req/15min/IP on register/firebase/login/reset-password. **In-memory only** — resets on restart, not shared across instances (fine today at 1 PM2 fork instance; would silently misbehave if scaled).

---

## 🔴 Active Vulnerabilities / Findings (ranked)

1. **CRITICAL — Hardcoded password-reset default.** `POST /auth/reset-password` resets any admin/super_admin account's password to a literal `'Admin12345'` given only their email, with **no OTP/token/email-link verification**. The admin login UI even displays this password in plaintext in the success toast. Anyone who knows/guesses an admin email can take over the account.
   - **Fix:** require a signed, time-limited reset token sent to the account's email; never display the new password in a response.
2. **HIGH — JWT persisted in `localStorage`** in the admin panel (`glowfit_admin_jwt`), alongside an httpOnly cookie meant to prevent exactly this. Any injected script (XSS) can read and exfiltrate it.
   - **Fix:** drop direct-to-API Bearer calls from the browser; route everything through the existing Next.js BFF/cookie session.
3. **HIGH — Plaintext credentials committed to git.** `server/SERVER_SETUP_SUMMARY.md` and root `help` file contain real VPS (`sprsadmin`) and PostgreSQL (`glowfit_user`) passwords, already pushed to the GitHub remote.
   - **Fix:** rotate both passwords immediately; remove the files (or their secret content) from the working tree and, if the repo could ever go public, purge from git history.
4. **MEDIUM — Likely-broken `GET /admin/chart-data`.** Raw SQL references quoted `"User"`/`"Progress"` (case-sensitive) vs. actual lowercase `users`/`progress` tables. Not itself a vulnerability, but an availability/reliability issue worth fixing alongside this pass.
5. **MEDIUM — No CSRF defense beyond the CORS allow-list**, while cookies use `sameSite: 'none'` + `credentials: true` in production. Add a CSRF token as defense-in-depth.
6. **LOW (downgraded from MEDIUM) — TLS/HTTPS is live and working** (verified 2026-07-26: both subdomains return valid HTTPS responses, no 521/SSL errors). Remaining issue is documentation drift, not a live vulnerability: the committed nginx config still has no 443 blocks, meaning the live, certbot-modified config was never pulled back into git — a fresh deploy from this repo would regress HTTPS. Pull the live config into `server/nginx/` next time VPS access is available.
7. **LOW — Inconsistent enumeration protection.** `/auth/register` reveals "email already registered" (409) while `/auth/reset-password` deliberately avoids enumeration — inconsistent handling of the same information-leak class within one module.
8. **LOW — `.env.example` incomplete** (missing Firebase/Vultr vars) — onboarding risk, not a vuln itself.
9. **LOW — No automated tests** — regressions, including security regressions, won't be caught automatically.
10. **LOW — Double route mounting** (`/api/*` and bare `/*`) — confirm intentional; otherwise unnecessary surface duplication.
11. **LOW — No graceful shutdown hook** for Prisma/HTTP server on `SIGTERM`.

## Infrastructure Security (VPS)

- `ufw` enabled, inbound limited to 22/80/443; `fail2ban` active with an SSH jail.
- PostgreSQL and Redis bound to `127.0.0.1` only — not internet-exposed.
- **Root SSH login and password authentication are still enabled** — explicitly flagged as pending hardening in `server/SERVER_SETUP_SUMMARY.md`. Should move to key-only, non-root access.
- Cloudflare fronts both public subdomains; nginx allowlists Cloudflare IP ranges for real-client-IP restoration.

## Recommended Security Roadmap

See `TODO.md` 🔴 Critical/Security section and `ROADMAP.md` v1.0 for the scheduled fix order. Priority: rotate credentials → fix password reset → confirm HTTPS → add CSRF defense → remove JWT from localStorage.

---
*Consolidated from the technical, database, and deployment audits performed on this codebase. Last verified: 2026-07-26.*
