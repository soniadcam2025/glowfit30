# GlowFit — Current Sprint

*Updated automatically after every completed feature per `PROJECT_RULES.md`. Last Updated: 2026-07-26*

## Current Sprint

**Sprint: v1.0 Hardening & Task 28 Completion**

## Sprint Goal

Close out the last item of the original integration plan (Task 28 — profile settings sub-screens) and clear the Critical/Security punch list blocking a confident `v1.0.0` tag, without introducing new feature scope.

## Completed

- [x] **App Settings module** (2026-07-26): Language/Appearance synced via `/profile`; Privacy Policy & Terms backed by new `legal` API module + Admin editor + Flutter screen. Ad hoc feature request, not originally part of this sprint's scope, but completed end-to-end (DB migration, API, Admin, Flutter, verified).
- [x] **Premium/paywall screen** (2026-07-26): built from a supplied Figma design, wired from Glow's "Upgrade Now" banner. Also ad hoc, UI/navigation only.
- [x] **Glow category linking + category detail screen** (2026-07-26): real FK from posts/shorts to categories, new detail screen, new endpoint, `?categoryId=` filters.
- [x] **Unified Glow content detail screen** (2026-07-26): one screen for Reads+Shorts, optional tabbed accordion content, premium gating stub, admin forms + list badges extended.
- [x] **HTTPS confirmed live** (2026-07-26) — was listed as Blocked below; resolved by checking the actual endpoints directly instead of waiting on SSH access. Remaining follow-up (pulling the live nginx config into the repo) demoted to a normal Pending item, not blocking.
- [x] **Prisma migration drift resolved** (2026-07-26) — confirmed the 3 flagged columns already exist live; downgraded from Critical, and a proper migration was generated for the new App Settings columns going forward, keeping migration history honest.
- [x] `.gitignore` cleanup (Repository Maintenance Mode) — `client-builds/`, `VPS`, `help`, and generic binary/secret patterns added.
- [x] **Task 28 — Profile settings sub-screens** (Workout/Diet/Notification/App Settings) + `user_preferences` API/DB support — committed and pushed in `52e4983` (2026-07-26). **Original 28-task integration plan is now 28/28 complete.**
- [x] Task 27 — Glow screen (Explore by Goals, Glow Reads, Shorts & Quick Tips), full CRUD rebuilt from a non-functional stub.
- [x] Task 26 — Workout Library category cards made fully admin-managed.
- [x] Fixed `HomeController` GetX `permanent` bug (found during Task 27 work).
- [x] Bottom-nav highlight bug fix.
- [x] Full project documentation baseline created: `docs/archive/PROJECT_STATUS.md`, `PROJECT_MEMORY.md`, `ROADMAP.md`, `docs/archive/deployment-report.md`, `CHANGELOG.md`, `TODO.md`, `API_REFERENCE.md`, `DATABASE_SCHEMA.md`, `SECURITY.md`, `RELEASE_NOTES.md`, `PROJECT_MASTER.md`, `PROJECT_RULES.md`, `SPRINT.md`, `RELEASE_PROCESS.md`, `DEPLOYMENT.md`.

- [x] **GitHub secret setup for auto-deploy** (2026-07-26) — `VPS_HOST`/`VPS_USER`/`VPS_SSH_KEY` added by the user; dedicated deploy keypair generated, authorized on the VPS, local key files deleted after confirmation.
- [x] **CI build-check lint errors fixed** (2026-07-26, `c993b3f`) — the pipeline's first real run caught the 3 pre-existing ESLint errors (see `TODO.md`); fixed and confirmed `npm run lint` exits 0.
- [x] **Client APK build** (2026-07-26) — `flutter build apk --release`, packaged as `client-builds/GlowFit30-2026-07-26.zip` (debug-signed, no release keystore exists yet — fine for client testing). Now a standing request for future client-test builds.

- [x] **Landing page live on `glowfit30.com`** (2026-08-01): built from the separate `glowfit-homepage` repo (Vite + React 19 + pnpm), deployed as a static release dir with atomic symlink swap, new `glowfit-web` nginx vhost, certbot cert for apex + `www`. Ad hoc request; api/admin left untouched and verified healthy throughout.
- [x] **Live nginx config reconciled into the repo** (2026-08-01): `server/nginx/live/*.conf` now mirrors production verbatim. Uncovered a latent production-breaking bug — the committed config had api→4000/admin→3000 when production is **api→3000/admin→3001**; a fresh deploy from the repo would have swapped the API and admin panel. Old config deprecated, `setup-subdomains.sh` guarded.

## In Progress

- [ ] Confirm the first fully-green Actions run (build-check → deploy → verify) after the lint-fix push; confirm the assumed VPS layout (`/var/www/glowfit/backend`, PM2 process `glowfit-backend`) matches reality.

## ⚠️ Flagged this cycle

- Commit `52e4983` used a non-Conventional-Commit message (`"26072026"`) and bundled unrelated build artifacts (`client-builds/*.zip`, stray `VPS` file) — already pushed, not rewritten. `.gitignore` fix applied; the files remain in git history.

## Pending

- [ ] Rotate exposed VPS/DB credentials.
- [ ] Fix hardcoded password-reset flow.
- [ ] Fix `GET /admin/chart-data` table-casing bug.
- [ ] Install the auto-deploy workflow in the `glowfit-homepage` repo (drafted; landing deploys are manual until then).
- [ ] Wire up the Admin Settings "General" fields, or remove them (separate from the now-fixed Legal Content section).
- [ ] Add smoke tests for auth/profile/progress.

*(Full backlog with priority tags lives in `TODO.md`.)*

## Estimated Completion

| Scope | % |
|---|---|
| This sprint (Critical/Security punch list, Task 28 now done) | **~10%** — Task 28 complete; security/HTTPS/bug fixes not yet started |
| Overall project (weighted, all versions) | **~78%** — Task 28 completion + doc suite bumps this slightly from the ~75% baseline in `docs/archive/PROJECT_STATUS.md`; production-readiness dimension is still the drag |

## Priority Matrix

| | Low Effort | High Effort |
|---|---|---|
| **High Impact** | Fix `/admin/chart-data` casing bug · Rotate credentials · Add `client_max_body_size` | Fix password-reset flow · Confirm/complete HTTPS · Generate missing migration |
| **Low Impact** | Complete `.env.example` | Admin Settings page functionality · Real Category↔Item FK |

Work top row first (High Impact); within that row, do Low Effort items immediately and schedule High Effort items explicitly rather than letting them slip.

## Today's Tasks

1. Add `VPS_HOST`/`VPS_USER`/`VPS_SSH_KEY` GitHub secrets so the new auto-deploy pipeline can actually run.
2. Confirm the first automated deploy succeeds (check the Actions tab + the health-check job).
3. Fix `GET /admin/chart-data` table-name casing.
4. Rotate `sprsadmin` and `glowfit_user` passwords; remove plaintext copies from tracked files.

## Next Tasks

1. Replace hardcoded password-reset default with a token/OTP flow.
2. Pull the live, certbot-modified nginx config into the repo.
3. Add `client_max_body_size` to nginx.
4. Wire up or remove the Admin Settings "General" fields.
5. Flutter release build/distribution for the Premium screen — scope to be defined by the user next.

## Future Tasks

- v1.1: Redis-backed rate limiting/cache, consistent RBAC, real test suite, structured logging, shared admin CRUD components.
- v2.0: subscriptions/monetization, gamification, iOS release, AI recommendations, OTP login.
- v3.0: multi-region infra, managed DB, compliance/audit tooling (see `ROADMAP.md`).

---
*This file is rewritten in place each sprint update — unlike `PROJECT_MEMORY.md`'s Update Log, it is not append-only; it reflects the current sprint state only. Historical sprints are preserved via `CHANGELOG.md` entries and `PROJECT_MEMORY.md`.*
