# Changelog

Format loosely follows [Keep a Changelog](https://keepachangelog.com/). No versions have been tagged yet (`git tag -l` is empty) — entries below are reconstructed from git history and grouped by theme/date under `[Unreleased]` until a `v1.0.0` is cut. **Append-only from this point forward**: add new entries above `[Unreleased]`'s prior content or as new dated subsections; never delete or rewrite a past entry.

---

## [Unreleased]

### Added
- Profile settings sub-screens (Workout Preferences, Diet Preferences, Notifications, App Settings) — in progress, uncommitted.
- User preference fields (`waterGoalLiters`, `pushEnabled`) on `User` model + migration `20260714020000_add_user_preferences`.

### Known issues carried into this cycle
- `GET /admin/chart-data` raw SQL table-name casing bug (likely broken).
- Hardcoded default password reset (`Admin12345`).
- Schema/migration drift on `User.fcmToken`, `Exercise.videoUrl`, `DietPlan.imageUrl`.
- HTTPS status on `api.glowfit30.com` / `admin.glowfit30.com` unverified since 2026-04-09.

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
