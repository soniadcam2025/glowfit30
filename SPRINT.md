# GlowFit — Current Sprint

*Updated automatically after every completed feature per `PROJECT_RULES.md`. Last Updated: 2026-07-26*

## Current Sprint

**Sprint: v1.0 Hardening & Task 28 Completion**

## Sprint Goal

Close out the last item of the original integration plan (Task 28 — profile settings sub-screens) and clear the Critical/Security punch list blocking a confident `v1.0.0` tag, without introducing new feature scope.

## Completed

- [x] **Task 28 — Profile settings sub-screens** (Workout/Diet/Notification/App Settings) + `user_preferences` API/DB support — committed and pushed in `52e4983` (2026-07-26). **Original 28-task integration plan is now 28/28 complete.**
- [x] Task 27 — Glow screen (Explore by Goals, Glow Reads, Shorts & Quick Tips), full CRUD rebuilt from a non-functional stub.
- [x] Task 26 — Workout Library category cards made fully admin-managed.
- [x] Fixed `HomeController` GetX `permanent` bug (found during Task 27 work).
- [x] Bottom-nav highlight bug fix.
- [x] Full project documentation baseline created: `PROJECT_STATUS.md`, `PROJECT_MEMORY.md`, `ROADMAP.md`, `deployment-report.md`, `CHANGELOG.md`, `TODO.md`, `API_REFERENCE.md`, `DATABASE_SCHEMA.md`, `SECURITY.md`, `RELEASE_NOTES.md`, `PROJECT_MASTER.md`, `PROJECT_RULES.md`, `SPRINT.md`, `RELEASE_PROCESS.md`, `DEPLOYMENT.md`.

## In Progress

*(nothing currently in progress — sprint focus shifts entirely to the v1.0 hardening/security punch list below)*

## ⚠️ Flagged this cycle

- Commit `52e4983` used a non-Conventional-Commit message (`"26072026"`) and bundled unrelated build artifacts (`client-builds/*.zip`, stray `VPS` file) — already pushed, not rewritten; `.gitignore` should be updated to prevent recurrence. See `PROJECT_MEMORY.md` Technical Debt.

## Blocked

- [ ] **HTTPS confirmation** — blocked on VPS SSH access to run/verify `certbot --nginx -d admin.glowfit30.com -d api.glowfit30.com` and check live status; cannot be verified from the repo alone.
- [ ] **Auto-deploy trigger** — blocked on a decision: GitHub Actions (needs VPS SSH secret) vs. a signed webhook receiver (needs a new API endpoint + secret management). Needs a choice before implementation starts.

## Pending

- [ ] Rotate exposed VPS/DB credentials.
- [ ] Fix hardcoded password-reset flow.
- [ ] Fix `GET /admin/chart-data` table-casing bug.
- [ ] Generate missing Prisma migration for schema drift (`fcmToken`, `Exercise.videoUrl`, `DietPlan.imageUrl`).
- [ ] Add `client_max_body_size` to nginx.
- [ ] Make Admin Settings functional or remove it.
- [ ] Add smoke tests for auth/profile/progress.

*(Full backlog with priority tags lives in `TODO.md`.)*

## Estimated Completion

| Scope | % |
|---|---|
| This sprint (Critical/Security punch list, Task 28 now done) | **~10%** — Task 28 complete; security/HTTPS/bug fixes not yet started |
| Overall project (weighted, all versions) | **~78%** — Task 28 completion + doc suite bumps this slightly from the ~75% baseline in `PROJECT_STATUS.md`; production-readiness dimension is still the drag |

## Priority Matrix

| | Low Effort | High Effort |
|---|---|---|
| **High Impact** | Fix `/admin/chart-data` casing bug · Rotate credentials · Add `client_max_body_size` | Fix password-reset flow · Confirm/complete HTTPS · Generate missing migration |
| **Low Impact** | Complete `.env.example` | Admin Settings page functionality · Real Category↔Item FK |

Work top row first (High Impact); within that row, do Low Effort items immediately and schedule High Effort items explicitly rather than letting them slip.

## Today's Tasks

1. Fix `GET /admin/chart-data` table-name casing.
2. Rotate `sprsadmin` and `glowfit_user` passwords; remove plaintext copies from tracked files.
3. Add `client-builds/` and `VPS` to `.gitignore` to prevent the git-hygiene issue from recurring.

## Next Tasks

1. Replace hardcoded password-reset default with a token/OTP flow.
2. Generate + commit the missing Prisma migration for schema drift.
3. Confirm/complete HTTPS on both subdomains; commit the 443 nginx config.
4. Add `client_max_body_size` to nginx.
5. Make Admin Settings functional, or remove it.

## Future Tasks

- v1.1: Redis-backed rate limiting/cache, consistent RBAC, real test suite, structured logging, shared admin CRUD components.
- v2.0: subscriptions/monetization, gamification, iOS release, AI recommendations, OTP login.
- v3.0: multi-region infra, managed DB, compliance/audit tooling (see `ROADMAP.md`).

---
*This file is rewritten in place each sprint update — unlike `PROJECT_MEMORY.md`'s Update Log, it is not append-only; it reflects the current sprint state only. Historical sprints are preserved via `CHANGELOG.md` entries and `PROJECT_MEMORY.md`.*
