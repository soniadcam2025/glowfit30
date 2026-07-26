# GlowFit — Project Health Report
**Audit date: 2026-07-26** · Cadence: every Friday, or mandatory before any production release (never skipped). This audit was run with live checks where possible (git, Prisma schema validation, `flutter analyze`, admin ESLint, and live HTTPS health checks against `api.glowfit30.com`/`admin.glowfit30.com`) rather than repeating prior written claims — findings below reflect what was actually verified today, 2026-07-26.

---

## Health Score: **65 / 100**

| Category | Weight | Score | Notes |
|---|---|---|---|
| Git Hygiene | 10 | 7/10 | Clean, in sync with `origin/main` — but the `52e4983` non-Conventional-Commit incident is recent and real |
| Documentation Consistency | 10 | 9/10 | Full doc suite reconciled this cycle; strong cross-referencing |
| Security | 15 | 7/15 | 3 real open issues, one critical (see below) |
| Deployment | 15 | 8/15 | HTTPS confirmed live and healthy (good news) but automation/backup/config-drift gaps remain |
| Technical Debt | 10 | 5/10 | Extensively documented but sizeable backlog |
| Build Status | 15 | 10/15 | API + Flutter clean; admin panel has 3 real lint errors |
| Database Migrations | 10 | 6/10 | Schema valid, but known drift + live status unverifiable today |
| API Documentation | 8 | 7/8 | Accurate and current |
| Flutter Warnings | 7 | 6/7 | 8 issues, all warnings/info, zero errors |
| **Total** | **100** | **65** | **Functional beta, needs a hardening pass — consistent with the 6.5/10 health score in `PROJECT_STATUS.md`** |

---

## Critical Issues

*(Block a production release until fixed — carried from `SECURITY.md`, none newly discovered this cycle)*

1. **Hardcoded password-reset default.** `POST /auth/reset-password` resets any admin account to a literal `'Admin12345'` with no OTP/token verification, and the admin UI displays it in plaintext on success.
2. **Plaintext VPS/DB credentials committed to git.** `server/SERVER_SETUP_SUMMARY.md` and `help` contain real, working passwords, already pushed to the public remote.

---

## Warnings

*(Should be fixed before or shortly after the next release; none block it outright)*

1. **JWT persisted in admin-panel `localStorage`** — XSS exposure alongside the httpOnly cookie meant to prevent it.
2. **Likely-broken `GET /admin/chart-data`** — raw SQL table-name casing mismatch (`"User"`/`"Progress"` vs. actual lowercase tables). Not yet fixed as of this audit.
3. **Admin panel ESLint: 3 errors** (newly verified today, not previously tracked):
   - `backend/src/app/(admin)/workouts/page.tsx:362` — unescaped `"` characters (`react/no-unescaped-entities`), ×2.
   - `backend/src/app/login/page.tsx:124` — `setState` called synchronously inside a `useEffect` body (`react-hooks/set-state-in-effect`), risking cascading re-renders.
4. **Admin panel ESLint: 4 warnings** — two `<img>` elements that should use `next/image` (`(admin)/users/page.tsx`), one unused variable (`workoutId` in `workouts/page.tsx`), one unused type (`ChartPoint` in `chart-card.tsx`).
5. **Database migration drift** — `User.fcmToken`, `Exercise.videoUrl`, `DietPlan.imageUrl` exist in `schema.prisma` with no corresponding migration. `npx prisma migrate status` could not be verified against the live database this cycle (local SSH tunnel to `127.0.0.1:5433` was not active during the audit) — re-run once the tunnel is up.
6. **nginx config drift** — the live, HTTPS-serving nginx config on the VPS was never pulled back into `server/nginx/glowfit30-subdomains.conf`, which is still committed as HTTP-only. A fresh deploy from this repo would regress HTTPS.
7. **`52e4983` commit hygiene** — non-Conventional-Commit message, bundled unrelated build artifacts (`client-builds/*.zip`, stray `VPS` file) into a feature commit. Already pushed; not rewritten. `.gitignore` fix still pending.
8. **No CI/CD** — no automated build/lint/test gate exists, which is exactly how the 3 admin ESLint errors above shipped unnoticed.
9. **API has zero automated tests** and **no lint/devDependencies configured at all** — `npm run lint` isn't even a script in `api/package.json`, unlike `backend/`.

---

## Suggestions

*(Lower urgency, quality-of-life / maintainability)*

- Fix the two `react/no-unescaped-entities` errors and the `set-state-in-effect` warning in the admin panel — small, low-risk fixes that clear real lint errors.
- Replace the two `<img>` tags flagged in `(admin)/users/page.tsx` with `next/image`.
- Remove the unused `workoutId` variable and `ChartPoint` type.
- Add an ESLint (or at least a basic syntax/import check) script to `api/package.json` — currently the only "test" is a manual DB-connectivity script.
- Re-run `npx prisma migrate status` once VPS/DB tunnel access is available, to confirm whether the 3 drifted columns are also missing from the live database or were applied out-of-band via `db push`.
- Pull the live nginx config back into the repo next time VPS access is available (see `DEPLOYMENT.md`).

---

## Next Sprint Recommendations

In priority order, folding in this audit's new findings alongside the existing `SPRINT.md`/`TODO.md` backlog:

1. Fix the 3 admin-panel ESLint errors (quick, isolated, clears real build warnings).
2. Fix `GET /admin/chart-data` table-casing bug.
3. Rotate exposed VPS/DB credentials; scrub plaintext copies from tracked files.
4. Fix the hardcoded password-reset flow.
5. Generate the missing Prisma migration for the 3 drifted columns (re-verify against live DB once tunnel access is available).
6. Add `.gitignore` entries for `client-builds/` and `VPS` (prevents repeat of the `52e4983` incident).
7. Pull the live nginx config into the repo.
8. Stand up minimal CI (lint + build for all three apps) — this audit's admin-lint findings are exactly the class of regression CI exists to catch automatically.

---

## Audit Methodology (for repeatability)

This audit re-runs the following each time, rather than trusting prior written claims:
- `git status` / sync check against `origin/main`.
- Live HTTPS check against both public subdomains.
- `npx prisma validate` + `npx prisma migrate status` (DB tunnel required for the latter).
- `flutter analyze` in `flutter_app/`.
- `npm run lint` in `backend/`.
- Cross-check `SECURITY.md`, `TODO.md`, `PROJECT_MASTER.md` §17 for anything newly resolved or newly discovered.

---
*Next scheduled audit: next Friday, or immediately before any production release — whichever comes first. Never skip.*
