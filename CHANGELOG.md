# Changelog

Format loosely follows [Keep a Changelog](https://keepachangelog.com/). No versions have been tagged yet (`git tag -l` is empty) — entries below are reconstructed from git history and grouped by theme/date under `[Unreleased]` until a `v1.0.0` is cut. **Append-only from this point forward**: add new entries above `[Unreleased]`'s prior content or as new dated subsections; never delete or rewrite a past entry.

---

## [Unreleased]

### Added (2026-07-26)
- **App Settings module completed**: Language and Appearance preferences now sync via `User.language`/`User.appearance` through the existing `/profile` endpoint; Privacy Policy & Terms backed by a new `LegalDocument` model and `/legal` API module, editable from the Admin Settings page, displayed in a new Flutter screen.
- **Premium/paywall screen**: new Flutter screen (`features/premium/premium_screen.dart`) matching a supplied Figma design — hero section, "Why Go Premium" grid, 3 pricing plans, guarantee row, CTA. Wired from the Glow screen's "Upgrade Now" banner. UI/navigation only, no payment backend (tracked in `ROADMAP.md` v2.0).
- **Glow category linking + category detail screen**: `BeautyPost`/`GlowShort` now have a real `categoryId` FK to `GlowCategory` (not string-matched — avoids repeating the `WorkoutLibraryCategory` anti-pattern). New `GlowCategoryDetailScreen` (Flutter) shows live Videos/Posts counts, Popular Topics, Top Videos grid, Latest Posts & Videos — wired from tapping a category tile on the Glow screen. New `GET /glow/categories/:id` endpoint; `?categoryId=` filter added to `/beauty` and `/glow/shorts`.
- **Unified Glow content detail screen**: one `GlowContentDetailScreen` (Flutter) for both Reads and Shorts — media header adapts per type, optional tabbed Problem&Cause/Solution/Tips accordion content (`resultBadge`/`chips`/`sections`/`isPremium`, all new optional fields on `BeautyPost`/`GlowShort`), premium lock badge + Watch Ad/Go Premium stub row. Wired from every Read/Short/mixed-content card in the app. Admin Reads/Shorts forms extended with a category picker, premium checkbox, chips editor, and a nested 3-tab section editor; list cards show 🔒 Premium / 📑 Has Tabs badges.
- **CI/CD — auto-deploy pipeline**: `.github/workflows/deploy.yml` (GitHub Actions) triggers on push to `main` — verifies both apps build, then SSHes into the VPS to run `api/deploy.sh` and the new `backend/deploy.sh`, then health-checks both public endpoints. Also added `backend/ecosystem.config.cjs` (the admin app previously had no PM2 process definition in git at all). Requires a one-time `VPS_HOST`/`VPS_USER`/`VPS_SSH_KEY` GitHub secret setup before it actually deploys — see `DEPLOYMENT.md`.

### Fixed (2026-07-26, incidental)
- `beauty.service.js#createPost` was validating `tag`/`tagColor`/`tagBackground`/`minutesRead`/`order` but silently dropping them on creation (only `updatePost` persisted them) — found and fixed while adding category linking to the same function.
- **CI build-check ESLint errors** (`c993b3f`): the new pipeline's first real run caught 3 pre-existing errors — unescaped quotes in `(admin)/workouts/page.tsx`'s delete-confirmation copy, and a dead `useEffect` in `login/page.tsx` that synchronously called `setState` on pathname change (the real loading-reset logic was already handled correctly in the submit handler's `catch` block). Removed the dead effect and its now-unused imports; `npm run lint` exits 0.

### Ops (2026-07-26)
- GitHub secrets (`VPS_HOST`, `VPS_USER`, `VPS_SSH_KEY`) configured with a dedicated deploy keypair — auto-deploy pipeline is now fully wired end-to-end.
- First client-test APK built and packaged: `client-builds/GlowFit30-2026-07-26.zip` (`flutter build apk --release`, debug-signed — no release keystore exists yet).

### Fixed (2026-07-26)
- Admin Settings page (`/settings`) is now partially functional — the Legal Content section persists real data; the unrelated "General" fields remain a stub (separately tracked).

### Known issues carried into this cycle
- `GET /admin/chart-data` raw SQL table-name casing bug (likely broken).
- Hardcoded default password reset (`Admin12345`).
- Schema/migration drift on `User.fcmToken`, `Exercise.videoUrl`, `DietPlan.imageUrl`.
- ~~HTTPS status unverified~~ — confirmed live and healthy 2026-07-26 (see the Project Health Audit entry below); committed nginx config just needs the live certbot config pulled back in.
- `client-builds/` and `VPS` committed to git in `52e4983` — need `.gitignore` entries to prevent recurrence.

---

## 2026-07-26 — First Project Health Audit

### Added
- `PROJECT_HEALTH_REPORT.md` — first run of the new weekly/pre-release health audit (Health Score 65/100).

### Fixed (documentation, not code)
- Corrected stale "HTTPS unverified" claims across `DEPLOYMENT.md`, `SECURITY.md`, `TODO.md`, `PROJECT_MASTER.md` — live-checked, both subdomains are healthy over HTTPS.

### Discovered
- 3 ESLint errors + 4 warnings in `backend/` (admin panel), not previously tracked — logged to `TODO.md` and `PROJECT_MASTER.md` Technical Debt.
- `flutter_app/` has 8 `flutter analyze` issues (all warnings/info, 0 errors).

---

## 2026-07-26 — Task 28 complete: Profile settings sub-screens

### Added
- Profile settings sub-screens: Workout Preferences, Diet Preferences, Notifications, App Settings (Flutter).
- User preference fields (`waterGoalLiters`, `pushEnabled`) on `User` model + migration `20260714020000_add_user_preferences`.
- Full project documentation suite: `PROJECT_MASTER.md`, `PROJECT_RULES.md`, `SPRINT.md`, `RELEASE_PROCESS.md`, `DEPLOYMENT.md`, plus the earlier `PROJECT_STATUS.md`/`PROJECT_MEMORY.md`/`ROADMAP.md`/`deployment-report.md`/`API_REFERENCE.md`/`DATABASE_SCHEMA.md`/`SECURITY.md`/`RELEASE_NOTES.md`/`TODO.md`.

### Process note
This closes the original 28-task integration plan (`App-Admin-Api connection Task.md`) at **28/28**. Committed as `52e4983` with a non-Conventional-Commit message (`"26072026"`) that also bundled unrelated build artifacts (`client-builds/*.zip`, stray `VPS` file) — flagged in `PROJECT_MEMORY.md` as a git-hygiene item to prevent going forward, not rewritten since already pushed.

---

## 2026-07-13 → 2026-07-16 — Content & Glow

### Added
- Glow (beauty/content hub) screen: Explore by Goals categories, Glow Reads, Shorts & Quick Tips — full admin CRUD, `GlowCategory`/`GlowShort` models, `/glow` API module.
- Workout Library category cards made fully admin-managed (section, tagline, card image, colors).
- Profile & Settings screen (Figma match), avatar + GlowFit tab wiring.
- Progress screen, wired to bottom navigation.

### Fixed
- Bottom-nav highlight now always reflects the tab actually on screen.
- `HomeController` (GetX) not marked `permanent` — was being silently disposed on `Get.offAllNamed` route-stack replacement, crashing any screen (including Home) that read it afterward.

---

## 2026-07-09 → 2026-07-13 — Workout Library & Diet

### Added
- Standalone browsable Workout Library (separate from day-plan Workouts): categories table, API CRUD, admin builder, difficulty filter.
- Hero/featured workout separated from category workouts.
- Per-day diet meal plans end-to-end (DB, API, admin builder, app wiring).
- "Liquid Glass" active-workout screen v2, ready-screen redesign, settings/music screens.

### Fixed
- Admin workout-library form now shows real validation errors and blocks save until required fields are filled.

---

## 2026-06-14 → 2026-06-26 — Core Feature Buildout

### Added
- Full workout flow in Flutter (5 new screens).
- Phase 2+3 milestone: API integration, admin dashboard, core Flutter screens.
- Push notifications (FCM), image/video uploads (Vultr Object Storage).
- Analytics page (signups, completions, active users charts) and user-streak logic.
- Diet screen (Day X plan view), post-Google-Sign-In profile sync.
- Per-day workout cover images, required media uploads, storage-bucket cleanup on delete.
- Per-day duration/kcal stats, restyled home hero card.

### Fixed
- Splash↔home 401 redirect loop after Google Sign-In.
- `UserDetail` type conflict blocking the Next.js admin build.

---

## 2026-04-09 → 2026-04-10 — Foundation

### Added
- Initial project setup: monorepo structure, Express API, Next.js admin dashboard, PostgreSQL/Prisma schema.
- JWT + cookie authentication, CORS configuration for local dev vs. production.
- Admin UI Lottie loaders and login DotLottie strip.
- VPS provisioned (Ubuntu 22.04, nginx, PM2, PostgreSQL, Redis, `ufw` + `fail2ban`).
- nginx subdomain routing and SSL automation scripts (`setup-subdomains.sh`).

### Known issues at this stage
- TLS/HTTPS not yet completed (Cloudflare 521 on both subdomains as of last check).
