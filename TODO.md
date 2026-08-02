# TODO

Live task list for GlowFit. Grouped by priority. Check items off in place; when a task is completed, mark it `[x]` and leave it in the list for one cycle (moved into `CHANGELOG.md`/`PROJECT_MEMORY.md` Update Log), don't silently delete it.

## 🔴 Critical / Security (block v1.0)

- [ ] Rotate exposed VPS (`sprsadmin`) and PostgreSQL (`glowfit_user`) passwords — currently plaintext in git-tracked `server/SERVER_SETUP_SUMMARY.md` and `help`.
- [ ] Replace hardcoded password-reset default (`Admin12345`) with a signed, time-limited, emailed reset token.
- [ ] Fix `GET /admin/chart-data` raw-SQL table-name casing bug (`"User"`/`"Progress"` vs actual `users`/`progress`).
- [x] ~~Confirm/complete HTTPS on `api.glowfit30.com` and `admin.glowfit30.com`~~ — verified live 2026-07-26, both working over HTTPS.
- [x] ~~Pull the live, certbot-modified nginx config back into the repo~~ — done 2026-08-01. Live configs mirrored verbatim into `server/nginx/live/` (api/admin/glowfit/glowfit-web). **Also uncovered that the old combined config had the wrong ports** (claimed api→4000/admin→3000; production is api→3000/admin→3001), which would have broken both services on a fresh deploy. Old file marked DEPRECATED and `setup-subdomains.sh` now refuses to run without an explicit override.
- [ ] Rewrite `server/scripts/setup-subdomains.sh` to deploy `server/nginx/live/*.conf`, then remove its safety guard.

## 🟠 In Progress

*(none — Task 28 completed and pushed 2026-07-26, see Completed note below)*

- [x] ~~Finish and commit Task 28~~ — Profile settings sub-screens (Workout/Diet/Notification/App Settings) + `user_preferences` API/DB support, committed in `52e4983` (2026-07-26). Original 28-task plan now 28/28.
- [x] ~~Add `client-builds/` and `VPS` to root `.gitignore`~~ — done during Repository Maintenance Mode setup (2026-07-26), plus generic APK/ZIP/cert/key patterns added.

## 🟡 Should Have (v1.0 / v1.1)

- [ ] Replace the app's blanket `catch (_) { return []; }` in `api_service.dart` with something that distinguishes auth/network/server failures from "no content" — a 500 on `/glow/shorts` presented as an empty list and cost a full debugging cycle on 2026-08-02.
- [ ] Make the Glow screen's hardcoded fallback tiles either tappable or visually distinct — they duplicate real seed-data titles, so a failed fetch is indistinguishable from real content.
- [ ] Consider server-side enforcement of the 30s per-tip clip limit (currently client-side only, so a crafted request could store a longer clip).
- [ ] **Schema drift: 5 tables carry a DB-side `id` default that `schema.prisma` does not declare** (`diet_plan_days`, `glow_categories`, `workout_library_categories`, `workout_library_exercises`, `workout_library_items`). Surfaced 2026-08-02 when `prisma migrate diff` bundled five unrelated `ALTER COLUMN "id" DROP DEFAULT` statements into what should have been a 3-column migration. **Any future `prisma migrate dev` will try to apply these to production** — write migrations by hand until this is reconciled deliberately.
- [ ] Add a per-tab intro line as an authorable field — the Glow detail screen's copy under each heading is currently hardcoded generic text, not per-post content.
- [ ] Remove unused `prisma` / `@prisma/client` dependencies from `backend/` — the admin never touches the database (they were the cause of the broken admin deploy on 2026-08-01).

- [ ] Generate + commit the missing Prisma migration for `User.fcmToken`, `Exercise.videoUrl`, `DietPlan.imageUrl` (**confirmed 2026-07-26: all 3 columns already exist live in the DB, added out-of-band via `db push` — this is a reproducibility/CI gap, not an active bug**; downgraded from 🔴 Critical).
- [x] ~~Fix 3 admin-panel ESLint errors~~ — done 2026-07-26 (`c993b3f`), found blocking the new CI `build-check` job on its first real run: escaped the literal quotes in `(admin)/workouts/page.tsx`, removed a dead `useEffect`/unused imports in `login/page.tsx`. `npm run lint` now exits 0.
- [ ] Clean up 4 admin-panel ESLint warnings: two `<img>` tags in `(admin)/users/page.tsx` (use `next/image`), unused `workoutId` var, unused `ChartPoint` type.
- [ ] Add a lint script to `api/package.json` (currently has none).

- [x] ~~Add `client_max_body_size` to nginx API server block~~ — **already live**, verified 2026-08-01: the production `api` vhost has `client_max_body_size 110M`. This item was stale; no change needed.
- [x] ~~Make the Admin Settings page functional~~ — partially done 2026-07-26: Legal Content section is real and API-backed. Remaining: the "General" fields (App name/Admin name/Support email) are still a non-functional stub.
- [ ] Wire up the Admin Settings "General" fields (App name/Admin display name/Support email) or remove them — separate from the Legal Content fix above.
- [ ] Real foreign key between `WorkoutLibraryCategory` and `WorkoutLibraryItem` (currently string-matched).
- [ ] Add CSRF defense-in-depth given `sameSite: 'none'` cookies in production.
- [ ] Consistent enumeration protection between `/auth/register` and `/auth/reset-password`.
- [ ] Complete `.env.example` (missing Firebase + Vultr S3 vars).
- [ ] Add smoke tests for auth/profile/progress endpoints (zero automated tests exist today).
- [ ] Clean up dead/mock code in `backend/` (`content.service.ts`, unused table/skeleton components, empty stub routes).
- [ ] Move rate limiting + admin-stats cache to Redis-backed (currently in-memory, single-instance only).
- [ ] Consistent RBAC enforcement across all admin routes (currently only `/settings` uses the client-side guard).
- [ ] Remove JWT from admin panel `localStorage`; route all calls through the existing Next.js BFF/cookie session.

## 🟢 Infrastructure / Ops

- [x] ~~Deploy the marketing landing page to `glowfit30.com`~~ — done 2026-08-01. Source repo <https://github.com/mayax2O/glowfit-homepage> (Vite + React 19, pnpm, → `dist/`). Static release-directory deploy with atomic symlink swap at `/var/www/glowfit/web/`, new `glowfit-web` nginx vhost, Let's Encrypt cert for apex + `www`. All four domains verified 200 over HTTPS.
- [ ] Add the auto-deploy workflow to the `glowfit-homepage` repo (`.github/workflows/deploy.yml` + `VPS_HOST`/`VPS_USER`/`VPS_SSH_KEY` secrets) — drafted, not yet installed; landing-page deploys are manual until then.
- [ ] Reconcile deploy-user assumptions: apps run under `sprsadmin` (PM2 home `/home/sprsadmin/.pm2`), and an undocumented `webhook.service` auto-deploy is also running alongside the new GitHub Actions pipeline — confirm which mechanism owns deploys before both fire.

- [x] ~~Stand up minimal CI (lint + build) for `api/` and `backend/`~~ — done 2026-07-26 as the `build-check` job in `.github/workflows/deploy.yml`.
- [x] ~~Add a real deploy trigger~~ — done 2026-07-26, GitHub Actions + SSH (`.github/workflows/deploy.yml`). **Needs one-time secret setup** (`VPS_HOST`/`VPS_USER`/`VPS_SSH_KEY`) before it actually deploys — see `DEPLOYMENT.md`.
- [x] ~~Add a PM2 `ecosystem.config.cjs` for the admin app~~ — done 2026-07-26, `backend/ecosystem.config.cjs` + `backend/deploy.sh` added.
- [ ] Set up PostgreSQL backups.
- [ ] Disable root SSH login / password auth on the VPS.
- [ ] Add deploy locking + a post-restart health check to `deploy.sh` (both scripts) — the new CI's health-check `verify` job covers post-deploy detection, but not a lock against overlapping manual+automated runs.
- [ ] Confirm the assumption in `backend/deploy.sh`/`DEPLOYMENT.md` that the admin app lives at `/var/www/glowfit/backend` with PM2 process name `glowfit-backend` — flagged as unverified (no live SSH access), adjust `APP_DIR`/`PM2_APP_NAME` env vars if the real VPS layout differs.
- [ ] Add uptime/alerting monitoring.

## 🔵 Technical Debt (see TECHNICAL DEBT section of PROJECT_MASTER.md for full list)

- [ ] Add linter/devDependencies to `api/`.
- [ ] Resolve double route mounting (`/api/*` and bare `/*`).
- [ ] Convert free-text "enum-like" fields to real Prisma enums (`DietPlan.type`, `Workout.level`, `WorkoutLibraryItem.difficulty`).
- [ ] Add missing index on `Progress.workoutDayId`.
- [ ] Add graceful-shutdown hook (Prisma/HTTP server on `SIGTERM`).
- [ ] Extract shared CRUD/table/filter components in the admin panel (currently duplicated per content page).
- [ ] Structured logging (replace `console.log`/`console.error`, especially `AUTH_DEBUG`-gated login logs).

## 🟣 Future (v2.0+, see ROADMAP.md)

- [ ] Subscriptions/monetization + entitlement gating.
- [ ] Gamification (badges, leaderboards).
- [ ] iOS release readiness + Apple Sign-In.
- [ ] AI-driven recommendations, OTP login, wearable integration.

---
*Last updated: 2026-07-26*
