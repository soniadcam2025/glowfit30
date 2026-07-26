# GlowFit — Project Memory

**Maintenance rules for this file (read before editing):**
- This file has two parts: a **Current State** snapshot (top) and an **Update Log** (bottom, append-only).
- The **Current State** section reflects "as of Last Updated" — it gets edited in place each time something changes, because it's a pointer to *now*, not history.
- The **Update Log** is **never edited or deleted** — every completed feature/fix appends one new dated entry at the bottom describing what changed. History is preserved permanently there even after the Current State section above it moves on.
- Last Updated: **2026-07-26**

---

## Current State

### Current Version

| App | Version |
|---|---|
| `api/` | `1.0.0` |
| `backend/` (admin panel) | `0.1.0` |
| `flutter_app/` (mobile) | `1.0.0+1` |

No git tags/formal releases cut yet (`git tag -l` empty). See `ROADMAP.md` for planned `v1.0` (production launch) scope.

### Completed Features

Per `App-Admin-Api connection Task.md` (27/28 tasks) plus later work:

- **Phase 1 — API Foundation**: profile schema fields, `WorkoutDay`/`Exercise`/`Progress` models, `POST /auth/firebase`, `GET/PATCH /profile`, workout days/exercises endpoints, progress + streak calc, seed script.
- **Phase 2 — Flutter ↔ API Integration**: `ApiService` (Dio), Google Sign-In → Firebase → JWT flow, home/workout/diet screens wired to live data, progress logging, 401 auto-logout.
- **Phase 3 — Admin Content Management**: workout day-by-day builder, exercise manager with image upload, diet plan form, dashboard stats, user detail page with progress history.
- **Phase 4 — Polish**: push notifications (FCM), image/video upload (Vultr S3), user streak logic, analytics page (Recharts).
- **Phase 5 — Content Completion (2/3)**: Workout Library category cards (admin-managed, seeded, verified), Glow screen (Explore by Goals / Glow Reads / Shorts, full CRUD rebuilt from stub) — fixed a `HomeController` GetX `permanent` bug found along the way.
- **Beyond original scope**: standalone browsable Workout Library (separate from day-plan Workouts) with category browse + difficulty filter + hero/featured workout separation.

### Pending Features

- [ ] **Task 28** — Profile settings sub-screens (Workout/Diet/Notification/App Settings) — in progress as of last check (uncommitted Flutter screens + API preference fields).
- [ ] Functional Admin Settings page (currently a non-functional stub).
- [ ] Real FK between `WorkoutLibraryCategory` and `WorkoutLibraryItem` (currently string-matched).
- [ ] Password-reset hardening (token/OTP instead of hardcoded default).
- [ ] v2.0-scope: subscriptions/monetization, gamification, iOS release, AI recommendations, OTP login (see `ROADMAP.md`).

### Folder Structure

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
├── backend/              Next.js admin WEB FRONTEND (name is misleading — not a backend)
│   └── src/app/(admin)/  dashboard, users, workouts, workout-library, diet, beauty, analytics, notifications, settings
├── flutter_app/          Flutter mobile app (GetX, Dio)
├── server/               nginx config + VPS provisioning docs
├── client-builds/        untracked, dated APK zip exports
├── docs/                 ARCHITECTURE.md (aspirational/roadmap), API_CONVENTIONS.md, BACKEND_RULES.md, FLUTTER_RULES.md, ADMIN_RULES.md
├── PROJECT_STATUS.md, ROADMAP.md, deployment-report.md, PROJECT_MEMORY.md (this file)
```

### Database Models

PostgreSQL via Prisma (`api/prisma/schema.prisma`), 14 models, all relations `onDelete: Cascade`, no many-to-many:

`User` (email/firebaseUid unique, role enum, isBlocked, profile+prefs fields) · `Workout` → `WorkoutDay` → `Exercise` · `Progress` (user+day, unique) · `DietPlan` → `DietPlanDay` · `WorkoutLibraryCategory` (soft-linked, no FK) / `WorkoutLibraryItem` → `WorkoutLibraryExercise` · `BeautyPost` · `GlowCategory` · `GlowShort` · `AdminLog`.

**Known drift:** `User.fcmToken`, `Exercise.videoUrl`, `DietPlan.imageUrl` are declared in schema with no corresponding migration yet.

### API Endpoints

12 modules, 51 route+method combinations, each mounted at both `/api/*` and bare `/*`:

- `/auth` — register, firebase, login, logout, me, reset-password
- `/profile` — get/patch, fcm-token
- `/progress` — post/get
- `/users` (admin) — list, get, progress, block
- `/admin` (admin) — stats (Redis-cached), analytics, chart-data ⚠️ (known bug, see below)
- `/workouts` — full CRUD workouts/days/exercises
- `/workout-library` — categories + items + exercises CRUD
- `/diet` — plans + today + per-day CRUD
- `/beauty` — CRUD
- `/glow` — categories + shorts CRUD
- `/notifications` (admin) — send (FCM)
- `/uploads` (admin) — image (5MB), video (100MB)

### Deployment Status

- **API**: PM2 fork mode (`glowfit-api`, `api/ecosystem.config.cjs`), deployed via `api/deploy.sh` — **manual SSH trigger only**, no webhook/CI.
- **Admin**: no ecosystem file, no deploy script — manual tar/upload/build/PM2-start process.
- **nginx**: subdomain routing (`api.glowfit30.com` → :4000, `admin.glowfit30.com` → :3000) behind Cloudflare; committed config is **HTTP-only, no 443 blocks**.
- **HTTPS**: last recorded check (2026-04-09) showed Cloudflare 521 on both subdomains — **unverified whether ever fixed**.
- **CI/CD**: none — no `.github/workflows/`, no webhook found anywhere in the repo.

### Infrastructure

- Single Ubuntu 22.04 VPS (Vultr, IP `139.84.149.147`), hostname `api-glowfit`.
- PostgreSQL (`glowfit_db`) + Redis, both bound to `127.0.0.1` only (not internet-exposed).
- `ufw` (22/80/443 only) + `fail2ban` (SSH jail) enabled.
- Cloudflare in front of both public subdomains.
- PM2 boot persistence via generated systemd unit `pm2-sprsadmin` (not a repo-tracked systemd file).
- No backups configured for PostgreSQL yet.

### Known Bugs

- `GET /admin/chart-data` — raw SQL quotes `"User"`/`"Progress"` (case-sensitive) but actual tables are lowercase `users`/`progress` — likely throws at runtime.
- Password reset resets admin accounts to a hardcoded literal (`Admin12345`), displayed in plaintext in the admin UI, with no OTP/token check.
- Schema/migration drift on 3 columns (see Database Models).
- nginx has no `client_max_body_size` override — likely rejects the API's 100MB video-upload endpoint with a 413.
- HTTPS status on both public subdomains is unverified/possibly still broken.
- ~~`HomeController` not marked `permanent` in GetX, causing crashes when a screen replaced the whole route stack~~ — **fixed** during Glow screen work (commit `41232a0`).

### Technical Debt

- No automated tests anywhere in the repo (API, admin, or Flutter).
- No devDependencies/linter in `api/`.
- Double route mounting (`/api/*` and bare `/*`) — undocumented, likely unintentional.
- In-memory rate limiting + admin-stats cache — single-instance only, won't scale to PM2 cluster mode without rework.
- Dead/mock code in `backend/`: `content.service.ts` (fake network calls), unused table/skeleton/filter components, empty stub routes (`(auth)/login`, `api/health/db/`).
- Free-text fields that should be enums (`DietPlan.type`, `Workout.level`, `WorkoutLibraryItem.difficulty`) — casing/typo risk with no DB constraint.
- `WorkoutLibraryCategory` ↔ `WorkoutLibraryItem` linked by string match, not FK.
- No graceful shutdown hook (Prisma/HTTP server) on process signal.
- Plaintext VPS/DB credentials committed to git-tracked files (`server/SERVER_SETUP_SUMMARY.md`, `help`) — needs rotation + history purge if repo could go public.
- CRUD boilerplate duplicated across admin content pages instead of shared components.

### Next Tasks

1. Finish + commit Task 28 (profile settings sub-screens).
2. Fix `/admin/chart-data` table-casing bug.
3. Rotate exposed VPS/DB credentials; scrub from tracked files.
4. Generate the missing Prisma migration for schema drift.
5. Confirm/complete HTTPS on both subdomains; commit the 443 nginx config back to the repo.
6. Harden the password-reset flow.
7. Make Admin Settings functional or remove it.
8. Stand up minimal CI + a real deploy trigger for the API.

---

## Update Log

*(Append-only. Newest entry at the bottom. Never edit or delete a prior entry — if something in it becomes outdated, note that in a new entry instead.)*

### 2026-07-26 — Initial creation
Created `PROJECT_MEMORY.md` and populated the Current State snapshot above by aggregating findings already produced this session: the full technical audit (backend/admin/database/deployment), the git repository analysis, the deployment-system analysis (`deployment-report.md`), `PROJECT_STATUS.md`, and `ROADMAP.md`. No code changed — this is a documentation-only baseline. Established the maintenance convention: this file will be updated after every completed feature or bug fix going forward, with the Current State section revised in place and a new dated entry appended here summarizing what changed.
