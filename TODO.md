# TODO

Live task list for GlowFit. Grouped by priority. Check items off in place; when a task is completed, mark it `[x]` and leave it in the list for one cycle (moved into `CHANGELOG.md`/`PROJECT_MEMORY.md` Update Log), don't silently delete it.

## 🔴 Critical / Security (block v1.0)

- [ ] Rotate exposed VPS (`sprsadmin`) and PostgreSQL (`glowfit_user`) passwords — currently plaintext in git-tracked `server/SERVER_SETUP_SUMMARY.md` and `help`.
- [ ] Replace hardcoded password-reset default (`Admin12345`) with a signed, time-limited, emailed reset token.
- [ ] Fix `GET /admin/chart-data` raw-SQL table-name casing bug (`"User"`/`"Progress"` vs actual `users`/`progress`).
- [ ] Confirm/complete HTTPS on `api.glowfit30.com` and `admin.glowfit30.com`; commit the certbot-generated 443 nginx blocks back into the repo.
- [ ] Generate + commit the missing Prisma migration for schema drift (`User.fcmToken`, `Exercise.videoUrl`, `DietPlan.imageUrl`).

## 🟠 In Progress

- [ ] Finish and commit Task 28 — Profile settings sub-screens (Workout/Diet/Notification/App Settings), including the `user_preferences` API/DB support already drafted.

## 🟡 Should Have (v1.0 / v1.1)

- [ ] Add `client_max_body_size` to nginx API server block (100MB, matching the video-upload limit).
- [ ] Make the Admin Settings page functional, or remove it.
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

- [ ] Stand up minimal CI (lint + build) for `api/` and `backend/`.
- [ ] Add a real deploy trigger (GitHub Actions SSH step or signed webhook) — `deploy.sh` exists but is never auto-invoked.
- [ ] Add a PM2 `ecosystem.config.cjs` for the admin app (currently started ad hoc, not reproducible from git).
- [ ] Set up PostgreSQL backups.
- [ ] Disable root SSH login / password auth on the VPS.
- [ ] Add deploy locking + a post-restart health check to `deploy.sh`.
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
