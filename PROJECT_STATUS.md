# GlowFit — Project Status
Generated: 2026-07-26 · Source: codebase inspection + `App-Admin-Api connection Task.md` + `docs/ARCHITECTURE.md` + `documentation.md` + git history (32 commits, no tags, no releases cut)

> **Note on sources:** `documentation.md` (last updated 2026-05-23) and `docs/ARCHITECTURE.md` are both stale/aspirational in places — they describe things not present in the actual code (Zustand, refresh tokens, a `subscriptions` module, Cloudflare R2 storage, a `/mobile` folder). This report is grounded in the **actual code and git history**, and calls out doc drift separately in Developer Notes rather than repeating outdated claims as fact.

---

## Completed Features

Per `App-Admin-Api connection Task.md`, the original 28-task integration plan is **27/28 complete (96.4%)**, confirmed against actual code:

**Phase 1 — API Foundation (8/8 ✅)**
- User profile schema (fitnessLevel, goal, dietStyle, targetWeight, focusAreas, dob, height, weight, firebaseUid, photoUrl) + `WorkoutDay`, `Exercise`, `Progress` models
- `POST /auth/firebase` (Firebase ID token → API JWT, find-or-create user)
- `GET/PATCH /profile`
- Workout days/exercises endpoints (read + admin write)
- `POST/GET /progress` with streak calculation
- Seed script (`db:seed`)

**Phase 2 — Flutter ↔ API Integration (8/8 ✅)**
- `ApiService` (Dio, JWT header, base URL config)
- Google Sign-In → Firebase ID token → `POST /auth/firebase` → JWT stored in GetStorage
- Home, workout plan, and workout-day-detail screens wired to live API data (hardcoded values removed)
- Workout completion → `POST /progress`
- Diet screen wired to `GET /diet`
- 401 auto-logout handling

**Phase 3 — Admin Dashboard Content Management (5/5 ✅)**
- Workout builder (day-by-day, exercise list per day)
- Exercise manager with image upload
- Diet plan form (assign to fitness-goal types)
- Dashboard stats (today's active workouts, completions)
- User detail page (onboarding profile + progress history)

**Phase 4 — Polish (4/4 ✅)**
- Push notifications (admin → Flutter via FCM)
- Image/video upload via Vultr Object Storage (S3-compatible)
- User streak logic
- Analytics page (signups, completion rate, active users — Recharts)

**Phase 5 — Content Completion (2/3 🔄, see In Progress)**
- Workout Library category cards — fully admin-managed, seeded, verified end-to-end
- Glow screen (Explore by Goals, Glow Reads, Shorts & Quick Tips) — full CRUD rebuilt from a non-functional stub, `GlowCategory`/`GlowShort` models added, Flutter wired with fallback content; fixed a real GetX bug along the way (`HomeController` not marked `permanent`, causing crashes on route-stack replacement)

**Beyond the original 28-task scope** (later commits, not in the task list):
- Standalone browsable Workout Library (separate from the day-plan Workouts model) — DB, API, admin builder, category browse screen with difficulty filter, hero/featured workout separated from category workouts
- Admin/API build-out for Glow content (reads, shorts, categories) as a full CMS

## In Progress

- **Task 28 — Profile settings sub-screens** (the one remaining item from the original plan): Workout Preferences, Diet Preferences, Notifications, App Settings rows currently show "coming soon" in the shipped app. Work is **actively underway right now** — uncommitted in the working tree:
  - Flutter: `app_settings_screen.dart`, `diet_preferences_screen.dart`, `notifications_screen.dart`, `workout_preferences_screen.dart` (new, untracked), plus edits to `profile_screen.dart`, `home_controller.dart`, `home_screen.dart`
  - API: new Prisma migration `20260714020000_add_user_preferences` (adds `water_goal_liters`, `push_enabled` to `User`) + matching `schema.prisma`, `profile.service.js`, `profile.validation.js`, `notifications.service.js` changes
  - This is a coherent, nearly-finished feature — **needs to be committed and pushed**, not re-planned.

## Pending Features

Not yet started/finished, in priority order:

1. **Functional Admin Settings page** — the `/settings` UI (super_admin-gated) exists but "Save Settings" performs no API call; needs a real backend settings model + endpoint.
2. **Fix `GET /admin/chart-data`** — raw SQL references quoted `"User"`/`"Progress"` identifiers that don't match the actual lowercase `users`/`progress` tables; almost certainly throws at runtime today.
3. **Reconcile schema/migration drift** — `User.fcmToken`, `Exercise.videoUrl`, `DietPlan.imageUrl` exist in `schema.prisma` with no corresponding migration; a `prisma migrate dev` needs to be generated and committed.
4. **`WorkoutLibraryCategory` ↔ `WorkoutLibraryItem` real foreign key** — currently linked only by matching free-text strings; introduced when categories were added but never finished.
5. **HTTPS/TLS completion & verification** — last recorded status check showed both public subdomains failing over HTTPS (Cloudflare 521); no later record confirms this was fixed.
6. **CI/CD / auto-deploy** — no webhook, no GitHub Actions; `deploy.sh` exists but is never triggered automatically, and the admin app has no deploy script at all.
7. **Automated test suite** — zero tests exist anywhere in the repo (API, admin, or Flutter) beyond a manual DB-connectivity script.
8. **Dead code cleanup** — `backend/src/services/content.service.ts` (fake mocked methods), several unused admin components/hooks, empty stub routes/directories, unused Prisma scaffolding in `backend/`.
9. **Password-reset hardening** — replace the hardcoded default-password reset flow with a token/OTP-based one.
10. Longer-horizon, doc-only aspirations not yet started: subscriptions, gamification, AI-driven recommendations, OTP login (all mentioned in `docs/ARCHITECTURE.md` as future/planned, no code exists for any of them yet).

## Current Version

No unified project version or git tags exist (`git tag -l` is empty — nothing has ever been formally released/tagged). Per-app versions, all still at pre-1.0/initial defaults:

| App | Version (from source) |
|---|---|
| `api/package.json` | `1.0.0` |
| `backend/package.json` (admin panel) | `0.1.0` |
| `flutter_app/pubspec.yaml` | `1.0.0+1` |

Recommend adopting a single, meaningful version scheme (e.g., tag `v0.9.0-beta` now, reserve `v1.0.0` for first public/store release) rather than leaving these as scaffolding defaults.

## Architecture

```
Flutter mobile app (flutter_app/, GetX, Dio)  ──┐
                                                  ├──HTTP/JSON──▶  Express + Prisma API (api/)  ──▶ PostgreSQL + Redis
Next.js admin panel (backend/, React Query)  ────┘                                            └──▶ Vultr S3-compatible storage
                                                                                                 └──▶ Firebase (Auth + FCM push)
```

- **`api/`** — Node.js (ESM) + Express 4 + Prisma 6 + PostgreSQL, modular `controller/service/routes/validation` pattern per feature (auth, profile, progress, users, admin, workouts, workout-library, diet, beauty, glow, notifications, uploads), optional Redis read-through caching, Firebase Admin for social login + push, JWT (cookie + Bearer) auth.
- **`backend/`** — misleadingly named; this is the **admin web frontend** (Next.js 16 App Router, React 19, TanStack React Query, Tailwind v4), not a backend service. Talks to `api/` over HTTP only.
- **`flutter_app/`** — Flutter/Dart mobile app, GetX state management, Firebase Auth (Google Sign-In), Dio for networking.
- **`server/`** — nginx + PM2 + provisioning docs for the single Ubuntu VPS hosting both services behind Cloudflare, subdomain-routed (`api.glowfit30.com`, `admin.glowfit30.com`).
- **Documentation drift to be aware of:** `docs/ARCHITECTURE.md` describes an aspirational future state (Zustand for admin state — actual code uses React Query only; refresh tokens — not implemented; a `subscriptions` backend module — doesn't exist; Cloudflare R2 storage — actual storage is Vultr S3; a `/mobile` folder — actual folder is `flutter_app/`). Treat that file as a **roadmap/vision doc**, not a description of current reality.

## Known Issues

Carried over and consolidated from the technical, security, and deployment audits performed on this codebase:

- **Likely-broken endpoint**: `GET /admin/chart-data` uses raw SQL with mismatched table-name casing (`"User"`/`"Progress"` vs actual `users`/`progress`).
- **Security — hardcoded password reset**: `/auth/reset-password` resets any admin account to a literal `'Admin12345'` given only the account email, no OTP/token verification; the admin UI even displays this password in plaintext on success.
- **Security — JWT in `localStorage`**: the admin panel stores its JWT in `localStorage` (XSS-exposed) in addition to an httpOnly cookie, for direct-to-API Bearer calls.
- **Security — plaintext credentials committed to git**: `server/SERVER_SETUP_SUMMARY.md` and the root `help` file contain real VPS/DB passwords, already pushed to the GitHub remote — needs immediate rotation.
- **Schema/migration drift**: 3 Prisma schema fields have no corresponding migration SQL (see Pending #3).
- **HTTPS unverified**: last known status check showed Cloudflare 521 on both public subdomains; nginx config as committed has no 443 blocks.
- **No CI/CD**: deployment is 100% manual SSH for the API (`deploy.sh`, never auto-triggered) and even more manual (tar-and-SSH) for the admin app.
- **No automated tests** anywhere in the repo.
- **nginx missing `client_max_body_size`**: likely rejects the API's own 100MB video-upload feature with a 413 at the proxy layer.
- **Dead/mock code**: an entire fake service (`content.service.ts`) with mocked network calls, several unused admin components/hooks, empty stub routes.
- **Double route mounting**: every API route is reachable at both `/api/*` and bare `/*` — likely unintentional, undocumented.
- **Git hygiene**: stray untracked `VPS` file and `client-builds/` APK zips sitting in the working tree; not covered by `.gitignore`.

## Next Milestones

1. **Commit & push the in-progress profile-settings feature** (Task 28) — closes out the original 28-task integration plan at 100%.
2. **Fix `/admin/chart-data`** and verify the analytics page renders correctly end-to-end.
3. **Generate and commit the pending Prisma migration** to eliminate schema/migration drift.
4. **Harden the password-reset flow** (token/OTP-based, no more hardcoded default).
5. **Rotate exposed VPS/DB credentials** and remove them from tracked files (and history, if the repo could go public).
6. **Confirm/complete HTTPS** on both subdomains and commit the certbot-updated nginx config back into the repo.
7. **Stand up basic CI** (lint + a smoke test) and a real deploy trigger (webhook or GitHub Actions) for at least the API.
8. **Make the Admin Settings page functional**, or remove it until it is.
9. **Clean up dead code** in `backend/` (mock service, unused components/hooks, empty stubs) as a low-risk hygiene pass.

## Estimated Completion Percentage

| Scope | Estimate | Basis |
|---|---|---|
| **Original integration task list** (`App-Admin-Api connection Task.md`, 28 tasks) | **~96%** | 27/28 tasks explicitly checked off and verified in code; only Task 28 (profile settings sub-screens) remains, and it's already mid-implementation |
| **Core product feature set** (workouts, diet, glow/beauty, workout library, progress, notifications, admin CMS) | **~90%** | All major content domains have working end-to-end CRUD + app consumption; remaining gaps are polish (settings page, category FK) not missing features |
| **Production-readiness** (security, deploy automation, testing, monitoring) | **~45–55%** | Solid foundations (JWT, Helmet, rate limiting, Redis caching, PM2) undercut by no CI/CD, no tests, unresolved HTTPS status, a hardcoded-password vulnerability, and committed plaintext credentials |
| **Overall weighted estimate** | **~75%** | Feature-complete for an MVP/beta; needs a focused hardening pass (security fixes, TLS confirmation, CI, tests) before a confident production/store launch |

## Project Health Score

**Score: 6.5 / 10 — Functional beta, needs a hardening pass before production launch**

| Dimension | Score | Notes |
|---|---|---|
| Feature completeness | 8.5/10 | 27/28 planned tasks done, broad real content-management surface across 3 apps |
| Code organization | 7.5/10 | Consistent modular pattern (controller/service/routes/validation) in the API; admin panel has some duplicated CRUD boilerplate and abandoned "generic component" attempts |
| Security posture | 4/10 | Real vulnerabilities present today: hardcoded reset password, JWT in localStorage, plaintext credentials committed to git, no CSRF defense beyond CORS allow-list |
| Deployment maturity | 4/10 | Works, but entirely manual, no CI/CD, no rollback/health-check, HTTPS status unverified, admin app has no reproducible deploy config at all |
| Test coverage | 1/10 | No automated tests exist anywhere in the repo |
| Documentation accuracy | 5/10 | Task tracker (`App-Admin-Api connection Task.md`) is accurate and well-maintained; `docs/ARCHITECTURE.md` and `documentation.md` are stale/aspirational and would mislead a new contributor |
| Git hygiene | 6.5/10 | Clean Conventional Commits for the last 2 months of history, but a few junk commits (`fc1`, `test deploy`), no branches/PRs ever used, some untracked clutter (`VPS`, `client-builds/`) |

**Overall trend: positive.** The gap between "feature work" (strong) and "production hardening" (weak) is the defining characteristic of this project's current state — typical of a fast-moving solo-developer MVP that hasn't yet had a dedicated security/ops pass.

## Developer Notes

- **Trust the task tracker over the architecture docs.** `App-Admin-Api connection Task.md` is current, specific, and matches the actual code precisely (confirmed by cross-checking against real migrations/modules). `docs/ARCHITECTURE.md` and `documentation.md` describe an earlier or aspirational vision and should either be updated or clearly marked as "future roadmap" to avoid misleading future contributors (or future-you, six months from now).
- **The `backend/` folder name is a persistent source of confusion** — it's the admin *frontend*, not a backend service. The real backend is `api/`. Worth a rename or at least a prominent note at the top of any README.
- **This is effectively a solo-developer project with no branching model** — all 32 commits are direct to `main`, no PRs, no merges ever. That's fine at this stage, but the security/credential issues found (passwords in git-tracked docs) are exactly the kind of thing a second reviewer or a pre-commit secret scanner would have caught — worth adding one (e.g., `gitleaks`) even solo.
- **Two features were fixed as side-effects of other work**, not tracked as their own issues — worth remembering when reading old commits: the `HomeController` GetX `permanent` bug (fixed during the Glow screen build) and the admin CORS/cookie fixes (early April commits). Neither has a dedicated issue/changelog entry.
- **Immediate action item, unrelated to feature work**: rotate the VPS (`sprsadmin`) and PostgreSQL (`glowfit_user`) passwords recorded in `server/SERVER_SETUP_SUMMARY.md` — they're sitting in git history in plaintext right now.
- Firebase project in use: `glowfit-beta-829ea` — still a "beta" project name, worth confirming whether a production Firebase project is planned before public launch.

## Release Notes

No formal releases have been tagged (`git tag -l` is empty) — this project has been in continuous, untagged development since 2026-04-09. What follows is a reconstructed changelog grouped by theme, suitable as a first-ever `v0.x` release note if one were cut today.

### Unreleased (working tree, uncommitted)
- Profile settings: Workout/Diet/Notification/App Settings sub-screens (Flutter) + `user_preferences` support (water goal, push toggle) on the API/DB.

### 2026-07-13 → 2026-07-16 — Content & Glow
- Glow (beauty/content hub) screen shipped: Explore-by-Goals categories, Glow Reads, Shorts & Quick Tips, all admin-managed with graceful fallback content.
- Workout Library category cards made fully admin-managed (section, tagline, card image, colors).
- Profile & Settings screen rebuilt to match Figma; avatar + GlowFit tab wiring.
- Progress screen built and wired to bottom navigation.
- Bottom-nav highlight bug fixed (now always reflects the tab actually on screen).

### 2026-07-09 → 2026-07-13 — Workout Library & Diet
- Standalone browsable Workout Library shipped (separate from day-plan Workouts): categories, difficulty filter, hero/featured workout, full admin builder.
- Per-day diet meal plans shipped end-to-end (DB, API, admin builder, app wiring).
- "Liquid Glass" active-workout screen v2, ready-screen redesign, settings/music screens.

### 2026-06-14 → 2026-06-26 — Core Feature Buildout
- Full workout flow shipped in Flutter (5 new screens).
- Phase 2+3 milestone: API integration, admin dashboard, and core Flutter screens completed together.
- Push notifications, image/video uploads (Vultr Object Storage) added.
- Analytics page (signups, completions, active users charts) and user-streak logic added.
- Diet screen (Day X plan view) and post-Google-Sign-In profile sync added.
- Fixed a splash↔home 401 redirect loop after Google Sign-In.

### 2026-04-09 → 2026-04-10 — Foundation
- Initial project setup: monorepo structure, Express API, Next.js admin dashboard, PostgreSQL/Prisma schema, JWT + cookie auth, CORS configuration for local vs. production, admin UI Lottie loaders.
- VPS provisioned (Ubuntu 22.04, nginx, PM2, PostgreSQL, Redis, `ufw` + `fail2ban`); nginx subdomain routing and SSL automation scripts added (TLS completion status unverified as of the last recorded check).
