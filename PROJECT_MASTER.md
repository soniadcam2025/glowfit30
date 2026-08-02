# GlowFit — Project Master
**Single source of truth for the entire GlowFit project.** Merges `docs/archive/PROJECT_STATUS.md`, `PROJECT_MEMORY.md`, `ROADMAP.md`, `CHANGELOG.md`, `docs/archive/deployment-report.md`, `API_REFERENCE.md`, `DATABASE_SCHEMA.md`, `RELEASE_NOTES.md`, `SECURITY.md`, and `TODO.md`. Those files remain the detailed/standalone versions of their domain; this document is the merged overview that should be read first.

**Last Updated: 2026-07-26** · Maintained per `PROJECT_RULES.md` — updated after every completed feature, sections revised in place, nothing deleted (see `PROJECT_MEMORY.md`'s Update Log for the full append-only history this document draws from).

---

## 1. Executive Summary

GlowFit is a three-tier fitness + beauty platform: a Flutter mobile app, an Express/Prisma API, and a Next.js admin panel, backed by PostgreSQL + Redis on a single Ubuntu VPS behind Cloudflare. The original 28-task integration plan (`docs/archive/App-Admin-Api connection Task.md`) is **28/28 complete**, plus substantial beyond-scope work (Premium/paywall screen, a real Glow category system with a detail screen, and a unified tabbed content-detail screen for Reads/Shorts). HTTPS is confirmed live and CI/CD now exists (GitHub Actions → SSH deploy → health check, pending a one-time secret setup). What remains before a confident v1.0 launch: a hardcoded password-reset vulnerability, plaintext credentials committed to git, a likely-broken analytics endpoint, and zero automated test coverage. Overall weighted completion: **~82%**.

## 2. Project Health

**Score: 7 / 10 — Feature-complete beta with a real deploy pipeline; security and test coverage are now the main gaps.**

| Dimension | Score | Notes |
|---|---|---|
| Feature completeness | 9/10 | 28/28 planned tasks done, plus Premium/Glow-category/content-detail work beyond original scope |
| Code organization | 7.5/10 | Consistent modular API pattern; admin panel has duplicated CRUD boilerplate |
| Security posture | 4/10 | Hardcoded reset password, JWT in localStorage, plaintext creds in git — unchanged, still the top risk |
| Deployment maturity | 7/10 | GitHub Actions CI/CD implemented 2026-07-26 (build-check → SSH deploy → health verify), both apps now have PM2 ecosystem files, HTTPS confirmed live. Pending: GitHub secrets setup, nginx-config drift, PostgreSQL backups, root SSH hardening |
| Test coverage | 1/10 | Zero automated tests anywhere — CI's build-check verifies the app *loads/typechecks*, not that it behaves correctly |
| Documentation accuracy | 8/10 | This doc suite has been kept rigorously current all session; `docs/ARCHITECTURE.md`/`docs/archive/documentation.md` remain stale/aspirational by design (treated as roadmap, not fact) |
| Git hygiene | 7/10 | Consistent Conventional Commits maintained since the one `52e4983` incident; no branches ever used |

**Trend: positive.** Feature velocity and deployment maturity both improved significantly this cycle; security posture and test coverage are now the clear, unchanged bottlenecks — next hardening pass should target those specifically.

## 3. Architecture

```
Flutter mobile app (flutter_app/, GetX, Dio)  ──┐
                                                  ├──HTTP/JSON──▶  Express + Prisma API (api/)  ──▶ PostgreSQL + Redis
Next.js admin panel (backend/, React Query)  ────┘                                            └──▶ Vultr S3-compatible storage
                                                                                                 └──▶ Firebase (Auth + FCM push)
```

- **`api/`** — the real backend. Node.js (ESM) + Express 4 + Prisma 6 + PostgreSQL, modular controller/service/routes/validation pattern per feature, optional Redis read-through caching, Firebase Admin for social login + push, JWT (cookie + Bearer) auth.
- **`backend/`** — **misleadingly named**; this is the admin **web frontend** (Next.js 16 App Router, React 19, TanStack React Query, Tailwind v4). No direct DB access despite leftover unused Prisma boilerplate.
- **`flutter_app/`** — Flutter mobile app, GetX state management, Firebase Auth (Google Sign-In), Dio networking.
- **`server/`** — nginx + PM2 + provisioning docs for the single VPS.
- **Documentation drift:** `docs/ARCHITECTURE.md` describes an aspirational future state (Zustand, refresh tokens, a `subscriptions` module, Cloudflare R2, a `/mobile` folder) that doesn't match reality — treat it as a roadmap/vision doc, not current fact. This master document is the accurate current-state reference.
- **Architecture change policy:** per `PROJECT_RULES.md`, no architecture change may ship without updating this section first.

## 4. Folder Structure

```
glowfit/
├── api/                  Express + Prisma backend (the real backend)
│   ├── prisma/           schema.prisma + migrations/
│   ├── scripts/          seed.mjs, seed-admin.mjs, test-db.js
│   └── src/
│       ├── config/       env.js, firebase.js, storage.js
│       ├── database/     prisma.js, redis.js
│       ├── middleware/   auth.js, errorHandler.js, validate.js
│       ├── modules/      admin, analytics(stub), auth, beauty, diet, glow,
│       │                 notifications, profile, progress, uploads, users,
│       │                 workout-library, workouts
│       ├── routes/       index.js
│       └── utils/        adminLog.js, response.js
├── backend/              Next.js admin WEB FRONTEND (name is misleading)
│   └── src/app/(admin)/  dashboard, users, workouts, workout-library, diet, beauty, analytics, notifications, settings
├── flutter_app/          Flutter mobile app (GetX, Dio)
├── server/               nginx config + VPS provisioning docs
├── client-builds/        untracked, dated APK zip exports
├── docs/                 ARCHITECTURE.md (aspirational), API_CONVENTIONS.md, BACKEND_RULES.md, FLUTTER_RULES.md, ADMIN_RULES.md
└── (root docs)           PROJECT_MASTER.md (this file), PROJECT_RULES.md, SPRINT.md, RELEASE_PROCESS.md,
                          docs/archive/PROJECT_STATUS.md, PROJECT_MEMORY.md, ROADMAP.md, CHANGELOG.md, docs/archive/deployment-report.md,
                          API_REFERENCE.md, DATABASE_SCHEMA.md, RELEASE_NOTES.md, SECURITY.md, TODO.md
```

## 5. Database

PostgreSQL via Prisma, **15 models**, all relations `onDelete: Cascade`, no many-to-many. Full detail in `DATABASE_SCHEMA.md`.

`User` (now includes `language`, `appearance`) · `Workout`→`WorkoutDay`→`Exercise` · `Progress` (User+WorkoutDay) · `DietPlan`→`DietPlanDay` · `WorkoutLibraryCategory` (soft-linked, no FK) / `WorkoutLibraryItem`→`WorkoutLibraryExercise` · `BeautyPost` · `GlowCategory` · `GlowShort` · `AdminLog` · `LegalDocument`.

**Glow content is now a real linked graph, not three siloed lists** (2026-07-26): `BeautyPost`/`GlowShort` → `categoryId` FK → `GlowCategory` (`onDelete: SetNull`, deleting a category never destroys its content). `GlowCategory` also gained `heroImageUrl`/`topics` (category detail screen); `BeautyPost`/`GlowShort` gained `resultBadge`/`chips`/`sections` (JSON, fixed Problem&Cause/Solution/Tips tabs, all optional)/`isPremium` for the new unified content detail screen.

**14 migrations**, chronological from `20250409120000_init` to `20260726170000_add_glow_content_detail_fields`.

**⚠️ Known drift:** `User.fcmToken`, `Exercise.videoUrl`, `DietPlan.imageUrl` exist in `schema.prisma` with no matching migration — must be reconciled before v1.0 (see `TODO.md` 🔴).

## 6. API Modules

13 modules, **56 route+method combinations**, each mounted at both `/api/*` and bare `/*` (unresolved double-mount, see Technical Debt). Full detail + auth requirements in `API_REFERENCE.md`. `beauty` and `glow` (shorts) list endpoints now accept a `?categoryId=` filter; `glow` gained `GET /categories/:id` returning live post/short counts for the category detail screen.

`auth · profile · progress · users · admin · workouts · workout-library · diet · beauty · glow · notifications · uploads · legal` (new — `GET/PATCH /legal`, backs the Flutter Privacy Policy & Terms screen and the Admin Settings page's Legal Content editor). `analytics` module is an empty stub — metrics live in `admin` module instead.

**⚠️ Known bug:** `GET /admin/chart-data` uses raw SQL with mismatched table-name casing — likely broken at runtime.

## 7. Admin Panel

Next.js 16 App Router, React 19, TypeScript, TanStack React Query, Axios, Tailwind v4. Pages: Dashboard, Users, Workouts, Workout Library, Diet, Beauty/Glow, Analytics, Notifications, Settings (non-functional stub), Login.

- **Auth:** BFF pattern — login proxied through a same-origin Next.js route that sets an httpOnly cookie + returns the JWT for client-side `localStorage` storage (⚠️ XSS exposure, see Security).
- **Routing:** edge middleware guards auth + role (`routeRoleMap`); a client-side `withRoleGuard` HOC additionally guards only `/settings` (inconsistent — should extend to all role-restricted routes). The mobile user-agent redirect to `/desktop-only` was **removed 2026-08-02** as part of the UI upgrade; that page is now unreachable and is slated for deletion with the responsive shell.
- **UI foundation (Phase 1, 2026-08-02):** semantic design tokens in `globals.css` (HSL, light + dark, exposed via `@theme inline`) — components style against `bg-surface`/`text-muted-foreground`, never raw palette classes. System/Light/Dark theming via `next-themes` with a topbar toggle. `next-themes` requires `@custom-variant dark` (otherwise Tailwind v4 follows `prefers-color-scheme` and the toggle does nothing) and `suppressHydrationWarning` on `<html>`. Installed but not yet used: `@tanstack/react-table`, `react-hook-form`, `zod`, Radix primitives — staged for later phases.
- **State:** React Query for server state; no global auth/UI store (re-fetches `/auth/me` as needed).
- **Known dead code:** `content.service.ts` (fake mocked methods), unused table/skeleton/filter components, empty stub routes (`(auth)/login`, `api/health/db/`).
- **Settings page (`/settings`) is now partially functional** (2026-07-26): its new "Legal Content" card is fully wired (real API-backed editor for Privacy Policy & Terms). The pre-existing "General" section (App name/Admin display name/Support email) is still a non-functional stub — unrelated, separately tracked.
- **`(admin)/beauty/page.tsx` extended (2026-07-26):** Reads/Shorts forms now have a category picker, a "Premium content" checkbox, a reusable chips editor (`TopicEditor`, shared with `GlowCategory.topics`), and a nested `SectionsEditor` for the 3-tab detail-screen content. Category form gained a hero-image upload + Popular Topics editor. List cards now show 🔒 Premium / 📑 Has Tabs badges so admins can tell at a glance without opening the edit form.

## 8. Flutter App

Dart SDK ≥3.0, GetX 4.6 (state management), Dio 5.3 (networking), get_storage + flutter_secure_storage, Firebase Auth/Core/Messaging, Google Sign-In, fl_chart, video_player. Version `1.0.0+1`. Auth flow: Google Sign-In → Firebase ID token → `POST /auth/firebase` → API JWT stored in GetStorage. All core screens (home, workouts, workout-library, diet, Glow, progress, profile) wired to live API data. Current build artifacts are **Android APKs only** (`client-builds/`) — no iOS release yet.

**New (2026-07-26):**
- Premium/paywall screen (`features/premium/premium_screen.dart`) — pricing plans, "Why Go Premium" grid, hero section; wired from the Glow screen's "Upgrade Now" banner via `Get.toNamed(Routes.premium)`. UI/navigation only — no payment/IAP backend; CTA buttons are stubs, consistent with `ROADMAP.md` v2.0 scoping real subscriptions as a future feature.
- `glow_category_detail_screen.dart` — category landing page (live Videos/Posts counts, Popular Topics, Top Videos grid, Latest Posts & Videos mixed feed), pushed from tapping a category tile on the Glow screen.
- `glow_content_detail_screen.dart` — one unified detail screen for both Glow Reads and Shorts (media header adapts per type; tabbed Problem&Cause/Solution/Tips accordion when authored, else plain content; premium lock badge + Watch Ad/Go Premium stub row). Wired from every place a Read/Short/mixed-content card appears (Glow screen rows, category detail screen grids).

## 9. Infrastructure

- Single Ubuntu 22.04 VPS (Vultr, IP `139.84.149.147`, hostname `api-glowfit`), behind Cloudflare.
- PostgreSQL (`glowfit_db`) + Redis, both bound to `127.0.0.1` only.
- `ufw` (22/80/443 only) + `fail2ban` (SSH jail) enabled.
- PM2 boot persistence via generated systemd unit `pm2-sprsadmin` (not repo-tracked).
- **No backups configured** for PostgreSQL yet.
- Root SSH login + password auth still enabled — pending hardening.

## 10. Deployment

- **API:** PM2 fork mode (`glowfit-api`), deployed via `api/deploy.sh` (git pull → npm ci → prisma migrate deploy → prisma generate → pm2 restart).
- **Admin:** PM2 fork mode (**`glowfit-admin` on :3001**), `backend/ecosystem.config.cjs` + `backend/deploy.sh`. ⚠️ **Corrected 2026-08-02:** the ecosystem file previously declared `glowfit-backend` with no PORT, so Next defaulted to :3000 (held by the API), the process crash-looped on `EADDRINUSE` and never started once, and deploys restarted it instead of the process actually serving production — leaving the live admin on a five-day-old build while every deploy reported success.
- **Deployment verification:** `server/scripts/verify-deployment.sh` (2026-08-02) proves the running apps match the deployed commit — git SHA vs `github.sha`, PM2 status, stray PM2 entries, `BUILD_ID` + build timestamp vs process start time, ports, local HTTP, and the three public endpoints. Run by the CI `verify` job and again inside `backend/deploy.sh` immediately post-restart. **A deployment counts as successful only when the running application matches the commit that triggered it** — an HTTP 200 alone is not evidence, since a stale process answers identically.
- **nginx:** subdomain routing behind Cloudflare — **`api.glowfit30.com`→:3000, `admin.glowfit30.com`→:3001, `glowfit30.com`→static** (verified live 2026-08-01; the older `4000/3000` figure in this doc was wrong). Authoritative configs are mirrored in `server/nginx/live/`.
- **HTTPS:** ✅ verified live 2026-07-26 — both subdomains reachable over HTTPS, API returns a healthy JSON payload (uptime ~12.8 days). The committed nginx config is still HTTP-only, so the live certbot config needs to be pulled back into the repo (doc-drift, not a live outage).
- **CI/CD:** ✅ implemented 2026-07-26 — `.github/workflows/deploy.yml` (GitHub Actions): push to `main` → build-check (API load check, Admin `tsc`+lint) → SSH deploy (both `deploy.sh` scripts) → health-check verification. Requires a one-time `VPS_HOST`/`VPS_USER`/`VPS_SSH_KEY` secret setup in GitHub before it actually deploys (pending as of this write-up) — see `DEPLOYMENT.md`.

## 11. Git Status

- Branch: `main` only (local + remote), no branching model ever used, no merges in 33-commit history.
- Remote: `origin` → `github.com/soniadcam2025/glowfit30.git`.
- No git tags/releases cut yet.
- Commit style: Conventional Commits, consistently followed for ~2 months — **with one 2026-07-26 exception**: commit `52e4983` used a bare, non-Conventional message (`"26072026"`) and bundled the Task 28 feature together with the entire new documentation suite, a stray `VPS` file, and two APK zips (`client-builds/*.zip`). Already pushed to `origin/main`; not rewritten (destructive). Flagged in `PROJECT_MEMORY.md`/`TODO.md` as a one-off to prevent recurring, not treated as a new pattern.
- Working tree is currently clean and in sync with `origin/main` (verified 2026-07-26).

## 12. Security

Full detail in `SECURITY.md`. Top findings, ranked:
1. **Hardcoded password-reset default** (`Admin12345`) — critical, no OTP/token verification.
2. **JWT in admin panel `localStorage`** — XSS exposure alongside the httpOnly cookie meant to prevent it.
3. **Plaintext VPS/DB credentials committed to git** (`server/SERVER_SETUP_SUMMARY.md`, `help`) — already pushed to the remote.
4. Likely-broken `/admin/chart-data` (reliability, not itself a vuln).
5. No CSRF defense beyond CORS allow-list; HTTPS status unverified; inconsistent enumeration protection between register/reset-password; no automated tests.

## 13. Current Sprint

See `SPRINT.md` for full detail. **Sprint goal:** clear the v1.0 Critical/Security punch list. Task 28 (profile settings sub-screens) is now **complete and pushed** (`52e4983`, 2026-07-26) — the original 28-task plan is 28/28. Focus shifts entirely to hardening: chart-data bug fix, credential rotation, password-reset fix, HTTPS confirmation, schema-drift migration.

## 14. Completed Features

Per `docs/archive/App-Admin-Api connection Task.md` (**28/28 — complete as of 2026-07-26**) plus later work — see `CHANGELOG.md` for the full chronological log:

- **Phase 1 — API Foundation** (8/8): profile schema, WorkoutDay/Exercise/Progress models, Firebase auth, profile CRUD, workout day/exercise endpoints, progress+streak, seed script.
- **Phase 2 — Flutter↔API Integration** (8/8): ApiService, Google Sign-In→Firebase→JWT, live data wiring across home/workout/diet screens, progress logging, 401 auto-logout.
- **Phase 3 — Admin Content Management** (5/5): workout builder, exercise manager, diet plan form, dashboard stats, user detail page.
- **Phase 4 — Polish** (4/4): push notifications, media uploads (Vultr S3), streak logic, analytics page.
- **Phase 5 — Content Completion** (3/3 ✅): Workout Library category cards, Glow screen (full CRUD from stub) — fixed a `HomeController` GetX `permanent` bug along the way. Task 28 (profile settings sub-screens: Workout/Diet/Notification/App Settings) completed and pushed 2026-07-26.
- **Beyond original scope:** standalone browsable Workout Library with category browse + difficulty filter + hero/featured separation; full project documentation suite (this file plus 13 others); App Settings module (language/appearance/legal content) completed end-to-end (2026-07-26); Premium/paywall screen built and wired from Glow (2026-07-26); Glow category linking + category detail screen (2026-07-26); unified Glow content (Reads/Shorts) detail screen with tabbed accordion content and premium gating (2026-07-26).

## 15. Pending Features

- Admin Settings "General" section (App name/Admin name/Support email) still non-functional — separate from the now-fixed Legal Content section.
- Real FK between `WorkoutLibraryCategory` and `WorkoutLibraryItem`.
- Password-reset hardening.
- v2.0 scope: subscriptions/monetization, gamification, iOS release, AI recommendations, OTP login, wearable integration (see `ROADMAP.md`).

## 16. Known Issues

- `GET /admin/chart-data` table-name casing bug (likely broken).
- Hardcoded password-reset default, displayed in plaintext in the admin UI.
- Schema/migration drift on 3 columns.
- nginx missing `client_max_body_size` — likely rejects the API's 100MB video-upload endpoint with a 413.
- Plaintext VPS/DB credentials committed to git.
- ~~`HomeController` GetX `permanent` bug~~ — **fixed** (commit `41232a0`).

## 17. Technical Debt

- No automated tests anywhere in the repo.
- No devDependencies/linter in `api/`.
- Double route mounting (`/api/*` and bare `/*`) — undocumented intent.
- In-memory rate limiting + admin-stats cache — single-instance only, won't survive PM2 cluster mode without rework.
- Dead/mock code in `backend/` (`content.service.ts`, unused components, empty stub routes).
- Free-text fields that should be enums (`DietPlan.type`, `Workout.level`, `WorkoutLibraryItem.difficulty`).
- No graceful-shutdown hook on process signal.
- CRUD boilerplate duplicated across admin content pages instead of shared components.
- Missing index on `Progress.workoutDayId`.
- No API versioning (`/v1/` prefix) and no Repository layer — target architecture per the current operating rules, not yet implemented; any move toward it must be documented (Rule 2) before/alongside the change.
- `client-builds/` and stray `VPS` file now committed to git history (via `52e4983`) — add to `.gitignore` to stop recurrence.
- **Admin panel: 3 ESLint errors + 4 warnings** discovered via live `npm run lint` run during the 2026-07-26 Project Health Audit — see `docs/archive/PROJECT_HEALTH_REPORT.md` for detail. Not previously tracked since no CI/lint gate exists yet.
- `api/` has no lint script/tooling at all (`backend/` does).

## 18. Upcoming Milestones

Per `ROADMAP.md`:
1. **v1.0 — Production Launch:** close every item in Known Issues above; nothing new, pure hardening.
2. **v1.1 — Stabilize & Scale-Ready:** Redis-backed rate limiting/cache, consistent RBAC, real test coverage, structured logging, shared admin components.
3. **v2.0 — Growth & Monetization:** subscriptions, gamification, iOS release, AI recommendations, OTP login.
4. **v3.0 — Platform Maturity & Scale:** multi-region infra, managed DB, compliance/audit tooling, marketplace/BI (intentionally speculative, to be re-scoped against real usage data).

## 19. Version History

No git tags exist yet. Per-app versions: `api` `1.0.0`, `backend` `0.1.0`, `flutter_app` `1.0.0+1` — all still scaffolding defaults. See `RELEASE_NOTES.md` for the milestone-level narrative and `RELEASE_PROCESS.md` → Version Numbering for the proposed scheme once `v1.0.0` is ready to tag.

## 20. Next Recommended Tasks

In priority order (also tracked in `TODO.md`):
1. Fix `/admin/chart-data` table-casing bug.
2. Rotate exposed VPS/DB credentials; scrub from tracked files.
3. Add `client-builds/` and `VPS` to `.gitignore`.
4. Fix the hardcoded password-reset flow.
5. Generate the missing Prisma migration for schema drift.
6. Pull the live certbot-modified nginx config back into the repo (HTTPS itself is confirmed working, just undocumented in git).
7. Add `client_max_body_size` to nginx.
8. Stand up minimal CI + a real deploy trigger for the API.

---
*This document is updated after every completed feature per `PROJECT_RULES.md`. Sections are revised in place; the append-only historical record lives in `PROJECT_MEMORY.md`'s Update Log and `CHANGELOG.md`.*
