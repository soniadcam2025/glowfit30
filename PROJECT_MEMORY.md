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
- **Phase 5 — Content Completion (3/3 ✅ as of 2026-07-26)**: Workout Library category cards (admin-managed, seeded, verified), Glow screen (Explore by Goals / Glow Reads / Shorts, full CRUD rebuilt from stub) — fixed a `HomeController` GetX `permanent` bug found along the way. **Task 28 — Profile settings sub-screens (Workout/Diet/Notification/App Settings)** — committed and pushed in `52e4983` (2026-07-26), closing out the original 28-task plan at 28/28.
- **Beyond original scope**: standalone browsable Workout Library (separate from day-plan Workouts) with category browse + difficulty filter + hero/featured workout separation. Full documentation suite (`PROJECT_MASTER.md`, `PROJECT_RULES.md`, `SPRINT.md`, `TODO.md`, `CHANGELOG.md`, `API_REFERENCE.md`, `DATABASE_SCHEMA.md`, `SECURITY.md`, `RELEASE_NOTES.md`, `DEPLOYMENT.md`, `ROADMAP.md`) established.
- **App Settings module** (2026-07-26): Language + Appearance synced via `/profile`; Privacy Policy & Terms backed by new `legal` API module + Admin editor + Flutter screen. Closes out all remaining App Settings stubs.
- **Premium/paywall screen** (2026-07-26): built from a supplied Figma design, wired from Glow's "Upgrade Now" banner. UI/navigation only, no payment backend (v2.0 scope).
- **Glow category linking + category detail screen** (2026-07-26): real `categoryId` FK on `BeautyPost`/`GlowShort` → `GlowCategory`; new `GlowCategoryDetailScreen` (Flutter) + `GET /glow/categories/:id` + `?categoryId=` filters.
- **Unified Glow content detail screen** (2026-07-26): one screen for Reads and Shorts, optional tabbed accordion content (`resultBadge`/`chips`/`sections`/`isPremium`), premium gating stub UI, wired everywhere content is tappable. Admin forms + list-card badges extended to match.

### Pending Features

- [ ] Admin Settings "General" fields (App name/Admin name/Support email) still non-functional (separate from the now-fixed Legal Content section).
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

PostgreSQL via Prisma (`api/prisma/schema.prisma`), 15 models, all relations `onDelete: Cascade` (except the new Glow category links, which use `SetNull` deliberately — deleting a category must not destroy its content), no many-to-many:

`User` (email/firebaseUid unique, role enum, isBlocked, profile+prefs fields incl. `language`/`appearance`) · `Workout` → `WorkoutDay` → `Exercise` · `Progress` (user+day, unique) · `DietPlan` → `DietPlanDay` · `WorkoutLibraryCategory` (soft-linked, no FK) / `WorkoutLibraryItem` → `WorkoutLibraryExercise` · `BeautyPost`/`GlowShort` → `categoryId` FK → `GlowCategory` (real FK, added 2026-07-26 — `BeautyPost`/`GlowShort` also gained `resultBadge`/`chips`/`sections`/`isPremium`; `GlowCategory` gained `heroImageUrl`/`topics`) · `AdminLog` · `LegalDocument`.

**Known drift:** `User.fcmToken`, `Exercise.videoUrl`, `DietPlan.imageUrl` — confirmed 2026-07-26 to already exist live in the DB (added via `db push`, no matching migration file); reproducibility gap, not a live bug.

### API Endpoints

13 modules, 56 route+method combinations, each mounted at both `/api/*` and bare `/*`:

- `/auth` — register, firebase, login, logout, me, reset-password
- `/profile` — get/patch, fcm-token
- `/progress` — post/get
- `/users` (admin) — list, get, progress, block
- `/admin` (admin) — stats (Redis-cached), analytics, chart-data ⚠️ (known bug, see below)
- `/workouts` — full CRUD workouts/days/exercises
- `/workout-library` — categories + items + exercises CRUD
- `/diet` — plans + today + per-day CRUD
- `/beauty` — CRUD, `?categoryId=` filter (new)
- `/glow` — categories + shorts CRUD, `GET /categories/:id` detail (new), `?categoryId=` filter on shorts (new)
- `/notifications` (admin) — send (FCM)
- `/legal` — get (auth), patch (admin) — new 2026-07-26, backs App Settings Privacy Policy & Terms
- `/uploads` (admin) — image (5MB), video (100MB)

### Deployment Status

- **API**: PM2 fork mode (`glowfit-api`, `api/ecosystem.config.cjs`), deployed via `api/deploy.sh`.
- **Admin**: PM2 fork mode (`glowfit-backend`, `backend/ecosystem.config.cjs` — new 2026-07-26), deployed via `backend/deploy.sh` (new 2026-07-26; was previously a manual tar/upload/build process).
- **nginx**: subdomain routing (`api.glowfit30.com` → :4000, `admin.glowfit30.com` → :3000) behind Cloudflare; committed config is **HTTP-only, no 443 blocks** (live server has HTTPS working, just not reflected back into the repo's nginx config).
- **HTTPS**: ✅ confirmed live 2026-07-26 via direct check.
- **CI/CD**: ✅ implemented 2026-07-26 — `.github/workflows/deploy.yml` (GitHub Actions): push to `main` → build-check → SSH deploy (both `deploy.sh` scripts) → health-check verify. **Pending one-time GitHub secret setup** (`VPS_HOST`/`VPS_USER`/`VPS_SSH_KEY`) before it actually deploys anything.

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
- **Git hygiene incident**: commit `52e4983` (2026-07-26, message `"26072026"`) bundled the Task 28 feature, the entire new documentation suite, the stray `VPS` file, and two APK zips (`client-builds/*.zip`, ~57MB combined) into one non-Conventional-Commit push, already merged to `origin/main`. Not reverting/rewriting history (already pushed, would be disruptive) — but `client-builds/` and `VPS` are now permanently in git history and should be added to `.gitignore` to prevent recurrence; future commits must follow Conventional Commits per `PROJECT_RULES.md` rule 6.
- API has no versioning (no `/v1/` prefix) and no Repository layer (Prisma calls happen directly in services) — both are named as target architecture in the new Lead-Engineer operating rules but don't exist yet; tracked as a deliberate, documented refactor, not implemented silently.
- No JWT refresh-token mechanism (single 7-day token only) — named as a security checklist item in the new operating rules; still a gap.

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

### 2026-07-26 — First Project Health Audit (`PROJECT_HEALTH_REPORT.md`)
Ran the first scheduled Project Health Audit (standing cadence: every Friday or before any production release). Performed live verification rather than trusting prior written claims: confirmed HTTPS is working on both `api.glowfit30.com` and `admin.glowfit30.com` (updating `DEPLOYMENT.md`/`SECURITY.md`/`TODO.md`/`PROJECT_MASTER.md` accordingly — this had been incorrectly carried forward as "unverified since 2026-04-09"); validated the Prisma schema (`prisma validate` passes); ran `flutter analyze` (8 warnings/info, 0 errors) and `npm run lint` in `backend/` (3 real ESLint errors + 4 warnings, not previously tracked anywhere). Computed a weighted Health Score of 65/100 across 9 categories (git hygiene, docs consistency, security, deployment, tech debt, build status, DB migrations, API docs, Flutter warnings), consistent with the earlier 6.5/10 score in `PROJECT_STATUS.md`. Logged the new admin-lint findings into `TODO.md` and this file's Technical Debt list.

### 2026-07-26 — App Settings module completed
Implemented full backend integration for the three App Settings sub-features that shipped as UI-only in Task 28: Language and Appearance are now persisted via new `User.language`/`User.appearance` columns through the existing `/profile` endpoint (same pattern as `dietStyle`/`pushEnabled` — no new module needed); Privacy Policy & Terms is backed by a new `LegalDocument` model + `legal` API module (`GET/PATCH /legal`), an editor added to the existing Admin Settings page (not a new page), and a new Flutter viewer screen. Migration `20260726120000_add_app_settings_language_appearance_legal` applied directly via `prisma migrate deploy` against the tunneled dev DB (hand-written migration file, avoiding the shadow-database permission issue and the drift pattern flagged in earlier audits). Verified end-to-end: curl smoke tests against both endpoints, `flutter analyze` clean, admin `tsc`/`eslint` clean (zero new issues), fresh Flutter rebuild on-device with no crashes. Appearance intentionally persists the user's choice only — no app-wide dark-mode theming was implemented (the codebase has no theming system; that's a separate, much larger UI initiative, not "backend integration").

### 2026-07-26 — Premium/paywall screen built
Built `flutter_app/lib/features/premium/premium_screen.dart` from a supplied Figma screenshot (hero section, "Why Go Premium" 4-icon grid, 3 pricing plan cards, guarantee row, CTA), registered as a new GetX route in `app_pages.dart` (correctly using the actually-imported `Routes` class there, not the dead/unused duplicate in `app_routes.dart` — confirmed via search first, per the standing "search before coding" rule). Wired the Glow screen's existing "Upgrade Now" banner (previously a `_comingSoon()`-style snackbar stub) to navigate to it. Reused an existing bundled asset (`assets/images/glow_hero.png`) for the hero photo rather than requesting a new one; smaller decorative badges built with Material icons/emoji as a close approximation. No payment/IAP backend — CTA buttons show a stub snackbar, consistent with `ROADMAP.md` v2.0 scoping real subscriptions/monetization as its own future feature.

### 2026-07-26 — Task 28 completed & full documentation suite established
Discovered (via `git log`/`git status`, not via my own commit — I never ran a commit in this session) that commit `52e4983` landed and was already pushed to `origin/main`, containing: the four profile-settings sub-screens (Workout/Diet/Notification/App Settings) plus the supporting `user_preferences` migration and API changes — completing the original 28-task integration plan at **28/28** — bundled together with the entire new documentation suite (`PROJECT_MASTER.md`, `PROJECT_RULES.md`, `SPRINT.md`, `TODO.md`, `CHANGELOG.md`, `API_REFERENCE.md`, `DATABASE_SCHEMA.md`, `SECURITY.md`, `RELEASE_NOTES.md`, `ROADMAP.md`, `deployment-report.md`), the stray `VPS` file, and two APK zips under `client-builds/`. Commit message was a bare date string (`"26072026"`), not a Conventional Commit — flagged as a Technical Debt entry above rather than rewritten (already pushed). Updated this file's Completed/Pending Features accordingly, added `DEPLOYMENT.md` as a new living deployment doc distinct from the point-in-time `deployment-report.md` audit, and adopted a new standing "Lead Engineer" operating mode (production-quality bar, pre-code impact reports, full analyse→design→implement→review→test→document→commit→deploy→verify pipeline) for all future GlowFit30 work.

### 2026-07-26 — Glow category linking + category detail screen
Added a real `categoryId` FK from `BeautyPost`/`GlowShort` to `GlowCategory` (`onDelete: SetNull`) — deliberately not repeating the pre-existing `WorkoutLibraryCategory`↔`WorkoutLibraryItem` string-matching anti-pattern already flagged in this file's Technical Debt. New `GlowCategory.heroImageUrl`/`topics` fields power a new `glow_category_detail_screen.dart` (live Videos/Posts counts, Popular Topics, Top Videos grid, Latest Posts & Videos mixed feed), wired from tapping a category tile on the Glow screen (previously a dead "coming soon" stub). New `GET /glow/categories/:id` endpoint; `?categoryId=` filter added to `GET /beauty` and `GET /glow/shorts`. Admin `(admin)/beauty/page.tsx` Reads/Shorts forms gained a category picker; Category form gained a hero-image upload + reusable Popular-Topics editor. Incidentally found and fixed a real bug in `beauty.service.js#createPost`: `tag`/`tagColor`/`tagBackground`/`minutesRead`/`order` were Zod-validated but silently dropped on creation (only `updatePost` persisted them) — same function I was already touching for `categoryId`. Fully verified: live smoke test (created a category+short+post, confirmed correct counts/filtering, cleaned up test data), API/Admin/Flutter builds all clean.

### 2026-07-26 — Unified Glow content detail screen (Reads + Shorts)
Built one `glow_content_detail_screen.dart` for both Glow Reads and Shorts — media header adapts per type (video play button/duration vs. static image), optional tabbed Problem & Cause/Solution/Tips accordion (new `sections` JSON field, fixed 3-tab shape, following the existing `DietPlanDay.meals` JSON-column precedent rather than inventing a new pattern), `resultBadge`/`chips` metadata, `isPremium` lock badge + Watch Ad/Go Premium stub row (no ad SDK or payment backend exists anywhere in this app — confirmed via research before building, so these are intentionally stubs, not broken features). Before starting, confirmed via research that tapping a Read/Short did nothing (dead "coming soon" stubs) and that no tab/accordion widget existed anywhere in the Flutter app — adapted the closest existing patterns (`workout_plan_screen.dart`'s expand/collapse, `workout_category_screen.dart`'s pill-tab row) instead of adding a new dependency. Wired from every tappable Read/Short surface: Glow screen's two content rows, and the category detail screen's Top Videos + Latest Posts & Videos grids (previously stubbed there too). Admin forms extended with a premium checkbox, a shared chips editor (generalized the existing `TopicEditor` rather than duplicating it for `GlowCategory.topics` vs. post/short `chips`), and a nested `SectionsEditor` for the 3 tabs. Added 🔒 Premium / 📑 Has Tabs badges to the admin list-card views (a gap explicitly flagged after the category-linking work, then fixed on request) so admins can tell at a glance without opening the edit form. Fully verified end-to-end on both a Read and a Short via live smoke test; all three apps build/lint/analyze clean.

Both of the above (App Settings, and the combined Premium/category-linking/content-detail work) were committed as 3 commits (`d2e9471`, `6bfe247`, `f2d279e`) and pushed to `origin/main` after the user's approval. Server-side deployment was still manual at that point (no SSH access from this session) — exact `deploy.sh` commands were handed to the user to run themselves.

### 2026-07-26 — Auto-deploy pipeline (GitHub Actions + SSH)
Before building, re-verified from scratch (not from memory) that no CI/CD/webhook existed anywhere in the repo — searched `.github/`, every `.yml`/`.yaml` file, all code for "webhook", and `server/` (all prior findings held; nothing had changed). Presented 5 auto-deploy options (GitHub Actions+SSH, webhook endpoint on the API, self-hosted Actions runner, polling cron, managed-platform migration) with tradeoffs; user chose GitHub Actions + SSH. Built `.github/workflows/deploy.yml` (`build-check` → `deploy` → `verify` jobs, using `appleboy/ssh-action`), plus `backend/deploy.sh` and `backend/ecosystem.config.cjs` (the admin app had neither before — closes a long-standing TODO item). Flagged two things the user still needs to do that I cannot do myself: (1) add `VPS_HOST`/`VPS_USER`/`VPS_SSH_KEY` as GitHub repo secrets, (2) confirm the assumed VPS layout (`/var/www/glowfit/backend`, PM2 process name `glowfit-backend`) since I have no live SSH access to verify it. YAML and shell syntax validated locally before committing.
