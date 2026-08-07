# GlowFit — Project Memory

**Maintenance rules for this file (read before editing):**
- This file has two parts: a **Current State** snapshot (top) and an **Update Log** (bottom, append-only).
- The **Current State** section reflects "as of Last Updated" — it gets edited in place each time something changes, because it's a pointer to *now*, not history.
- The **Update Log** is **never edited or deleted** — every completed feature/fix appends one new dated entry at the bottom describing what changed. History is preserved permanently there even after the Current State section above it moves on.
- Last Updated: **2026-08-07**

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

Per `docs/archive/App-Admin-Api connection Task.md` (27/28 tasks) plus later work:

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
├── docs/archive/PROJECT_STATUS.md, ROADMAP.md, docs/archive/deployment-report.md, PROJECT_MEMORY.md (this file)
```

### Database Models

PostgreSQL via Prisma (`api/prisma/schema.prisma`), 15 models, all relations `onDelete: Cascade` (except the new Glow category links, which use `SetNull` deliberately — deleting a category must not destroy its content), no many-to-many:

`User` (email/firebaseUid unique, role enum, isBlocked, profile+prefs fields incl. `language`/`appearance`) · `Workout` → `WorkoutDay` → `Exercise` · `Progress` (user+day, unique) · `DietPlan` → `DietPlanDay` · `WorkoutLibraryCategory` (soft-linked, no FK) / `WorkoutLibraryItem` → `WorkoutLibraryExercise` · `BeautyPost`/`GlowShort` → `categoryId` FK → `GlowCategory` (real FK, added 2026-07-26 — `BeautyPost`/`GlowShort` also gained `resultBadge`/`chips`/`sections`/`isPremium`; `GlowCategory` gained `heroImageUrl`/`topics`) · `AdminLog` · `LegalDocument`.

**Known drift:** `User.fcmToken`, `Exercise.videoUrl`, `DietPlan.imageUrl` — confirmed 2026-07-26 to already exist live in the DB (added via `db push`, no matching migration file); reproducibility gap, not a live bug.

**`Exercise.duration`/`Exercise.rest` are nullable by design, not by omission** (2026-08-07): both are required by the API and the admin form, but the columns stay nullable so exercises authored before the player became time-driven are neither rejected nor backfilled with an invented number. The Flutter client covers them with `durationSeconds`/`restSeconds` fallbacks in `workout_model.dart`, and the admin exercises table badges them "Not set" so they can be found and fixed. **No migration was needed for this change** — it is a validation and UI change only.

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
- **CI/CD**: ✅ implemented and configured 2026-07-26 — `.github/workflows/deploy.yml` (GitHub Actions): push to `main` → build-check → SSH deploy (both `deploy.sh` scripts) → health-check verify. GitHub secrets (`VPS_HOST`/`VPS_USER`/`VPS_SSH_KEY`, dedicated deploy keypair) are configured. First real run caught and required fixing 3 pre-existing lint errors (`c993b3f`) — not yet confirmed whether a subsequent run has gone fully green end-to-end (deploy + verify against the real VPS).

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
Created `PROJECT_MEMORY.md` and populated the Current State snapshot above by aggregating findings already produced this session: the full technical audit (backend/admin/database/deployment), the git repository analysis, the deployment-system analysis (`docs/archive/deployment-report.md`), `docs/archive/PROJECT_STATUS.md`, and `ROADMAP.md`. No code changed — this is a documentation-only baseline. Established the maintenance convention: this file will be updated after every completed feature or bug fix going forward, with the Current State section revised in place and a new dated entry appended here summarizing what changed.

### 2026-07-26 — First Project Health Audit (`docs/archive/PROJECT_HEALTH_REPORT.md`)
Ran the first scheduled Project Health Audit (standing cadence: every Friday or before any production release). Performed live verification rather than trusting prior written claims: confirmed HTTPS is working on both `api.glowfit30.com` and `admin.glowfit30.com` (updating `DEPLOYMENT.md`/`SECURITY.md`/`TODO.md`/`PROJECT_MASTER.md` accordingly — this had been incorrectly carried forward as "unverified since 2026-04-09"); validated the Prisma schema (`prisma validate` passes); ran `flutter analyze` (8 warnings/info, 0 errors) and `npm run lint` in `backend/` (3 real ESLint errors + 4 warnings, not previously tracked anywhere). Computed a weighted Health Score of 65/100 across 9 categories (git hygiene, docs consistency, security, deployment, tech debt, build status, DB migrations, API docs, Flutter warnings), consistent with the earlier 6.5/10 score in `docs/archive/PROJECT_STATUS.md`. Logged the new admin-lint findings into `TODO.md` and this file's Technical Debt list.

### 2026-07-26 — App Settings module completed
Implemented full backend integration for the three App Settings sub-features that shipped as UI-only in Task 28: Language and Appearance are now persisted via new `User.language`/`User.appearance` columns through the existing `/profile` endpoint (same pattern as `dietStyle`/`pushEnabled` — no new module needed); Privacy Policy & Terms is backed by a new `LegalDocument` model + `legal` API module (`GET/PATCH /legal`), an editor added to the existing Admin Settings page (not a new page), and a new Flutter viewer screen. Migration `20260726120000_add_app_settings_language_appearance_legal` applied directly via `prisma migrate deploy` against the tunneled dev DB (hand-written migration file, avoiding the shadow-database permission issue and the drift pattern flagged in earlier audits). Verified end-to-end: curl smoke tests against both endpoints, `flutter analyze` clean, admin `tsc`/`eslint` clean (zero new issues), fresh Flutter rebuild on-device with no crashes. Appearance intentionally persists the user's choice only — no app-wide dark-mode theming was implemented (the codebase has no theming system; that's a separate, much larger UI initiative, not "backend integration").

### 2026-07-26 — Premium/paywall screen built
Built `flutter_app/lib/features/premium/premium_screen.dart` from a supplied Figma screenshot (hero section, "Why Go Premium" 4-icon grid, 3 pricing plan cards, guarantee row, CTA), registered as a new GetX route in `app_pages.dart` (correctly using the actually-imported `Routes` class there, not the dead/unused duplicate in `app_routes.dart` — confirmed via search first, per the standing "search before coding" rule). Wired the Glow screen's existing "Upgrade Now" banner (previously a `_comingSoon()`-style snackbar stub) to navigate to it. Reused an existing bundled asset (`assets/images/glow_hero.png`) for the hero photo rather than requesting a new one; smaller decorative badges built with Material icons/emoji as a close approximation. No payment/IAP backend — CTA buttons show a stub snackbar, consistent with `ROADMAP.md` v2.0 scoping real subscriptions/monetization as its own future feature.

### 2026-07-26 — Task 28 completed & full documentation suite established
Discovered (via `git log`/`git status`, not via my own commit — I never ran a commit in this session) that commit `52e4983` landed and was already pushed to `origin/main`, containing: the four profile-settings sub-screens (Workout/Diet/Notification/App Settings) plus the supporting `user_preferences` migration and API changes — completing the original 28-task integration plan at **28/28** — bundled together with the entire new documentation suite (`PROJECT_MASTER.md`, `PROJECT_RULES.md`, `SPRINT.md`, `TODO.md`, `CHANGELOG.md`, `API_REFERENCE.md`, `DATABASE_SCHEMA.md`, `SECURITY.md`, `RELEASE_NOTES.md`, `ROADMAP.md`, `docs/archive/deployment-report.md`), the stray `VPS` file, and two APK zips under `client-builds/`. Commit message was a bare date string (`"26072026"`), not a Conventional Commit — flagged as a Technical Debt entry above rather than rewritten (already pushed). Updated this file's Completed/Pending Features accordingly, added `DEPLOYMENT.md` as a new living deployment doc distinct from the point-in-time `docs/archive/deployment-report.md` audit, and adopted a new standing "Lead Engineer" operating mode (production-quality bar, pre-code impact reports, full analyse→design→implement→review→test→document→commit→deploy→verify pipeline) for all future GlowFit30 work.

### 2026-07-26 — Glow category linking + category detail screen
Added a real `categoryId` FK from `BeautyPost`/`GlowShort` to `GlowCategory` (`onDelete: SetNull`) — deliberately not repeating the pre-existing `WorkoutLibraryCategory`↔`WorkoutLibraryItem` string-matching anti-pattern already flagged in this file's Technical Debt. New `GlowCategory.heroImageUrl`/`topics` fields power a new `glow_category_detail_screen.dart` (live Videos/Posts counts, Popular Topics, Top Videos grid, Latest Posts & Videos mixed feed), wired from tapping a category tile on the Glow screen (previously a dead "coming soon" stub). New `GET /glow/categories/:id` endpoint; `?categoryId=` filter added to `GET /beauty` and `GET /glow/shorts`. Admin `(admin)/beauty/page.tsx` Reads/Shorts forms gained a category picker; Category form gained a hero-image upload + reusable Popular-Topics editor. Incidentally found and fixed a real bug in `beauty.service.js#createPost`: `tag`/`tagColor`/`tagBackground`/`minutesRead`/`order` were Zod-validated but silently dropped on creation (only `updatePost` persisted them) — same function I was already touching for `categoryId`. Fully verified: live smoke test (created a category+short+post, confirmed correct counts/filtering, cleaned up test data), API/Admin/Flutter builds all clean.

### 2026-07-26 — Unified Glow content detail screen (Reads + Shorts)
Built one `glow_content_detail_screen.dart` for both Glow Reads and Shorts — media header adapts per type (video play button/duration vs. static image), optional tabbed Problem & Cause/Solution/Tips accordion (new `sections` JSON field, fixed 3-tab shape, following the existing `DietPlanDay.meals` JSON-column precedent rather than inventing a new pattern), `resultBadge`/`chips` metadata, `isPremium` lock badge + Watch Ad/Go Premium stub row (no ad SDK or payment backend exists anywhere in this app — confirmed via research before building, so these are intentionally stubs, not broken features). Before starting, confirmed via research that tapping a Read/Short did nothing (dead "coming soon" stubs) and that no tab/accordion widget existed anywhere in the Flutter app — adapted the closest existing patterns (`workout_plan_screen.dart`'s expand/collapse, `workout_category_screen.dart`'s pill-tab row) instead of adding a new dependency. Wired from every tappable Read/Short surface: Glow screen's two content rows, and the category detail screen's Top Videos + Latest Posts & Videos grids (previously stubbed there too). Admin forms extended with a premium checkbox, a shared chips editor (generalized the existing `TopicEditor` rather than duplicating it for `GlowCategory.topics` vs. post/short `chips`), and a nested `SectionsEditor` for the 3 tabs. Added 🔒 Premium / 📑 Has Tabs badges to the admin list-card views (a gap explicitly flagged after the category-linking work, then fixed on request) so admins can tell at a glance without opening the edit form. Fully verified end-to-end on both a Read and a Short via live smoke test; all three apps build/lint/analyze clean.

Both of the above (App Settings, and the combined Premium/category-linking/content-detail work) were committed as 3 commits (`d2e9471`, `6bfe247`, `f2d279e`) and pushed to `origin/main` after the user's approval. Server-side deployment was still manual at that point (no SSH access from this session) — exact `deploy.sh` commands were handed to the user to run themselves.

### 2026-07-26 — Auto-deploy pipeline (GitHub Actions + SSH)
Before building, re-verified from scratch (not from memory) that no CI/CD/webhook existed anywhere in the repo — searched `.github/`, every `.yml`/`.yaml` file, all code for "webhook", and `server/` (all prior findings held; nothing had changed). Presented 5 auto-deploy options (GitHub Actions+SSH, webhook endpoint on the API, self-hosted Actions runner, polling cron, managed-platform migration) with tradeoffs; user chose GitHub Actions + SSH. Built `.github/workflows/deploy.yml` (`build-check` → `deploy` → `verify` jobs, using `appleboy/ssh-action`), plus `backend/deploy.sh` and `backend/ecosystem.config.cjs` (the admin app had neither before — closes a long-standing TODO item). Flagged two things the user still needs to do that I cannot do myself: (1) add `VPS_HOST`/`VPS_USER`/`VPS_SSH_KEY` as GitHub repo secrets, (2) confirm the assumed VPS layout (`/var/www/glowfit/backend`, PM2 process name `glowfit-backend`) since I have no live SSH access to verify it. YAML and shell syntax validated locally before committing.

### 2026-07-26 — Secrets configured, CI caught real lint errors, first client APK built
Generated a dedicated ed25519 deploy keypair locally (in the scratchpad, never inside the repo), walked the user through appending the public key to `sprsadmin`'s `authorized_keys` on the VPS and adding it plus `VPS_HOST`/`VPS_USER` as the 3 GitHub secrets; deleted the local key files once both were confirmed done. The very first real CI run then did exactly what a build gate is supposed to do: `build-check` failed on 3 pre-existing ESLint errors (tracked since the first Project Health Audit) that had never blocked anything before because no CI existed. Fixed both root causes — escaped literal quotes in a `ConfirmModal` message, removed a dead `useEffect` in the admin login page that synchronously called `setState` on pathname change (the real reset logic already lived correctly in the submit handler's `catch` block) — and cleaned up the now-unused imports/variable that removing it left behind. Committed as `c993b3f` and pushed. Separately, built the first client-test APK (`flutter build apk --release`, debug-signed — no release keystore exists) and packaged it as `client-builds/GlowFit30-2026-07-26.zip`, matching the naming convention of the two pre-existing dated builds already in that folder; saved this as a standing request for future "build an APK for the client" asks.

### 2026-08-01 — Landing page deployed to glowfit30.com + live nginx config reconciled
First session with working SSH access to the VPS (`glowfit` host alias → `139.84.149.147`, key already present locally — no credentials needed from the user). Deployed the marketing homepage, which lives in a **separate repo** (`mayax2O/glowfit-homepage`, Vite + React 19 + framer-motion, pnpm 11, `pnpm build` → `dist/`), to the apex domain on the existing VPS alongside the API and admin panel.

Approach: surveyed live config read-only before touching anything, backed up `/etc/nginx/sites-{available,enabled}` to `/root/nginx-backup-20260801/`, then added a **new standalone vhost file** (`glowfit-web`) rather than editing any existing one — api/admin were verified 200 before, during, and after. Static files are served from `/var/www/glowfit/web/current`, a symlink into `releases/<timestamp>/`; deploys extract a new release and flip the symlink atomically (`ln -sfn` + `mv -Tf`), keeping the last 5 for instant rollback. Cloned and built the site locally to confirm the toolchain (caught that it uses **pnpm, not npm** — the first workflow draft was wrong), then did the first deploy by hand.

Two `certbot` and one `pm2 kill` invocation were blocked by the permission classifier; rather than working around them, handed the exact command to the user, who ran certbot themselves. (A stray empty root-owned PM2 daemon spawned by a `pm2 list` probe was left behind — harmless, still needs `pm2 kill` as root.)

**The significant find was incidental**: the committed `server/nginx/glowfit30-subdomains.conf` had the **wrong ports** — api→4000/admin→3000, when production is **api→3000/admin→3001** — and no TLS blocks. Running `setup-subdomains.sh` against production would have swapped the API and admin panel and stripped HTTPS from all subdomains. This also contradicted the ports recorded in prior session memory and several project docs. Fixed by mirroring the four live vhosts verbatim into `server/nginx/live/` (with a README covering ports, the deploy/rollback scheme, and the backup path), marking the old file DEPRECATED, and adding a hard refusal guard to the install script. Also confirmed `client_max_body_size 110M` was **already live** (that TODO was stale), and discovered the apps run under `sprsadmin`'s PM2 with an undocumented `webhook.service` auto-deploy running in parallel with the newer GitHub Actions pipeline — logged as a TODO, since two deploy mechanisms racing is a real hazard.

Remaining for the user: install the drafted `.github/workflows/deploy.yml` + the three `VPS_*` secrets in the `glowfit-homepage` repo (landing deploys are manual until then).

### 2026-08-02 — Glow Shorts story player, per-tip video, and two silent-failure bugs
Built a full-screen story-style viewer for Glow Shorts from a supplied design (`glow_short_story_screen.dart`), reached by tapping a card under "Shorts & Quick Tips". Before writing any code, checked what the data could already support and found that `sections.tips` — authored in the admin as `{imageUrl, title, description}` cards for the old tabbed detail screen — maps exactly onto the design's progress segments, "Tip N of 5" counter, card copy and thumbnails. **No schema change or migration was needed for either this or the later per-tip video work**, since `sections` is a JSON column; `videoUrl` simply became another key (it did have to be whitelisted in `sectionItemSchema`, which strips unknown keys).

Deliberate scoping decisions: the scrubber is a **timed pager, not video playback**, because `GlowShort` has no `videoUrl` of its own — only `duration` and a still; a Short with no authored tips routes to the tabbed detail screen rather than rendering a one-segment shell; and Shorts with `problemCause`/`solution` content get a "View full details" button so nothing authored in the admin is unreachable. Premium Shorts play the first tip free then gate behind Watch Ad / Go Premium — stubs, matching the existing detail screen, since no ad SDK or payment backend exists.

**Two silent failures cost most of the session and are the real lesson.** First, an `include: { category: { select: { name: true } } }` added to `listShorts` threw (`GlowCategory`'s display field is `title`, not `name`); the endpoint 500'd, `api_service.dart`'s blanket `catch (_) { return []; }` turned that into an empty list, the Glow screen fell back to hardcoded placeholder tiles — **which use the same titles as the seed data** — and tapping them showed the old "coming soon" snackbar. It looked exactly like a wiring problem in the new screen and prompted a full uninstall/`flutter clean`/reinstall cycle before the API log revealed the Prisma error. Second, `cleanSections()` in the admin drops any card missing a title or description, silently discarding uploaded images and clips with it, which presented to the user as "I uploaded a video, it saved, then it was gone." Both now surface: the sections editor warns on incomplete cards, and both `catch`-swallowing patterns are logged in `TODO.md`. **When a symptom looks like missing data, check whether an error is being swallowed before touching the feature code.**

Also discovered this session: **local development runs against the production database** — `api/.env` points at `127.0.0.1:5433`, which is the SSH tunnel to the VPS Postgres. Any content authored while testing is live for real users, so no test data was seeded. The `flutter clean` also hit a Windows Gradle file-lock (`Could not close incremental caches`) that needed `gradlew --stop` plus deleting `build/google_sign_in_android`.

### 2026-08-02 — Glow module: View All hubs, post redesign, editorial placement flags
Second working day on the Glow feature. Delivered in three user-verified steps: a **Glow Reads hub** and a **Shorts & Quick Tips hub** behind the two "View All" headers (which turned out to be *decorative text with no tap handler at all* — nothing had ever been wired), a redesign of the content detail screen's tab bar and cards to a supplied mockup, and admin-controlled placement flags for the Shorts hub.

**Two judgement calls worth remembering.** First, the user's "gl" mockup was in fact the *existing* `glow_category_detail_screen.dart` layout scoped to a category; rather than guess, asked whether Reads → View All should be a new all-content hub, reuse the category screen, or be a reads-only list — they chose the hub. Second, the "sq" mockup implied Featured / Trending / Quick Tips sections that no schema field backed. Offered derived-from-data (order/views/duration, zero migration) versus real fields, recommended a middle path, and the user chose **real fields** — so `isFeatured`/`isTrending`/`isQuickTip` now exist with admin checkboxes. Deriving would have made "Featured" an accident of sort order.

**The migration nearly caused real damage.** Running `prisma migrate diff` before applying anything revealed that a full schema diff against production contains **five unrelated `ALTER COLUMN "id" DROP DEFAULT` statements** across `diet_plan_days`, `glow_categories`, and three `workout_library_*` tables — pre-existing drift. A routine `prisma migrate dev` would have swept all five into the same migration and applied them to production as a side effect of adding three booleans. Wrote the migration by hand with only the three `ADD COLUMN` statements and applied it with `migrate deploy`. **Never use `migrate dev` on this project until that drift is reconciled** — it is now logged in `TODO.md`. Regenerating the Prisma client afterwards also required stopping the API (Windows locks the query-engine DLL), and `TaskStop` left orphaned node processes that had to be killed by PID.

Followed `PROJECT_RULES.md`'s refactor-over-duplicate rule by extracting `glow_common.dart` (shared cards, helpers, and a single `openGlowItem()` router) instead of copying ~500 lines from the category screen; `openGlowItem` also centralises the story-player-vs-detail-screen decision that had been duplicated at each call site. Admin review found the flow structure already correct (numbered `1 · Explore by Goals` → `2 · Glow Reads` → `3 · Shorts & Quick Tips`, mirroring the app), but three descriptions had gone stale or invisible — fixed with placement badges in the list and a warning when multiple shorts are marked Featured.

Committed separately from the Admin UI Foundation work at the user's instruction: they explicitly required one logical unit per commit, each independently reviewable, deployable and reversible. An earlier claim that the two units were entangled at hunk level was **wrong** — checking all seven hunks in `beauty/page.tsx` showed every one belonged to the Glow unit, so the split was clean at file level and no interactive staging was needed.

### 2026-08-02 — Deployment pipeline hotfix + Admin UI Foundation (Phase 1)
Two commits, deliberately kept separate at the user's instruction that every logical unit stay independently reviewable, deployable and reversible.

**The hotfix is the important one.** While verifying the Glow deploy (`f7e7028`) against the user's checklist — which explicitly asked for PM2 verification rather than just an HTTP check — PM2 showed three processes where two were expected: `glowfit-api` (online), `glowfit-admin` (online, **4 days uptime**), and `glowfit-backend` (**errored, 45 restarts, pid 0**). The `ecosystem.config.cjs` added on 2026-08-01 had named the app `glowfit-backend` with no PORT, so Next defaulted to 3000 — the port the API already holds — and it died on `EADDRINUSE` every single time. Production had always been served by `glowfit-admin` on 3001, created by the older webhook script which knew the right port. So every admin deploy pulled, built, restarted a corpse, and left the live admin serving a build from 2026-07-28. **Five days of "successful" admin deploys had shipped nothing** — including the previous day's placement checkboxes and per-tip clip uploader.

The reason it stayed hidden is the lesson: the CI verify step asserted only `HTTP 200`, and a process serving a stale bundle answers 200 exactly like a fresh one. **Reachability is not freshness.** The fix corrects the name and port, and replaces the health check with `server/scripts/verify-deployment.sh`, whose decisive assertion is that the serving process started *after* `.next/BUILD_ID` was written — the same signal that had read "built today, started five days ago" and still passed. It also checks git SHA against `github.sha`, flags stray PM2 entries, and verifies ports and the three public endpoints. `backend/deploy.sh` runs the same gate immediately post-restart so a bad deploy fails at the source. The pipeline proved itself on its own run: build 17:11:00, process start 17:11:02.

**Phase 1** established semantic design tokens in `globals.css` (HSL, light + dark, registered via `@theme inline`) so components style against `bg-surface`/`text-muted-foreground` instead of raw palette classes, plus `next-themes` System/Light/Dark. Two non-obvious requirements: `@custom-variant dark` is needed or Tailwind v4 keeps following `prefers-color-scheme` and the in-app toggle silently does nothing; and `<html>` needs `suppressHydrationWarning`. Button was upgraded in place — all four existing variant names preserved so no call site broke. Also discovered `.glass`, referenced by the secondary Button variant, had never been defined anywhere. The mobile user-agent block was removed after asking, since the spec's responsive requirement was unreachable behind it.

Process note worth keeping: the user requires **development → testing → documentation → commit → push → deployment → verification** per phase, never combined. When a mixed working tree appeared, they asked for a staging plan before any commit. An earlier claim that the two units were entangled at hunk level proved **wrong** on inspection — all seven hunks in `beauty/page.tsx` belonged to the Glow unit, so the split was clean at file level. Check before asserting entanglement.

### 2026-08-02 — Production readiness audit: unauthenticated admin takeover found and closed
Ran a full live audit before starting admin UI Phase 2, at the user's instruction to fix any Critical finding first. Verified everything against the running system rather than the docs, which paid off twice: the docs claim Redis caching is disabled locally and say nothing about production, but **Redis is active on the VPS with `REDIS_URL` set** — which makes it the obvious OTP store for the pending reset flow, no new infrastructure needed.

**The Critical finding was `POST /auth/reset-password`.** `TODO.md` had recorded it for weeks as "hardcoded password-reset default", which undersold it badly. The endpoint took **no authentication at all** — only a rate limit — and reset any admin or super_admin account to `Admin12345`, a constant committed to the repo and echoed in the response body. Knowing an admin's email was enough for full takeover in one request; the rate limiter is irrelevant when a single call succeeds. Confirmed reachable on production by probing with a deliberately non-existent address, which exercises the no-such-account branch and mutates nothing. **Lesson: re-read known issues against the code rather than trusting their recorded description — the summary was accurate about the constant and silent about the missing auth.**

Fixed by requiring `verifyToken` + `requireRole('super_admin')` and generating a 24-char `randomBytes(18).base64url` password per call, returned once. Kept the identical-response branch so it still cannot enumerate admin emails. Explicitly flagged the tradeoff rather than hiding it: a sole locked-out admin can no longer self-serve, and every existing admin password must now be assumed compromised.

The user asked for the admin password mid-audit. Declined to paste it into the transcript — having just classified plaintext credentials as a High finding, echoing a live production credential into another artifact would contradict the advice — and instead gave the one-line command to read it from their own `.env`, plus the caveat that `.env` holds the seed value which may no longer match the DB hash. Not a refusal; the user owns the server and was never blocked.

Other confirmed findings: `/admin/chart-data` genuinely broken (queries `"User"`/`"Progress"`, real tables are `users`/`progress`), **no database backups exist at all**, `PermitRootLogin yes`, and the five-table schema drift still making `prisma migrate dev` unsafe. Healthy: PM2 (two processes, no strays after the hotfix), nginx valid, SSL 35/88 days, PostgreSQL 14.23 with 15 migrations and no drift, `NODE_ENV=production`, `AUTH_DEBUG=false`, CORS locked to the admin origin, disk 30%.

### 2026-08-02 — Admin UI upgrade, Phases 2–7 (one commit and deploy per phase)
Completed the remaining admin UI phases and landed them as five sequential commits, each pushed, deployed and CI-verified on its own before the next began, per the user's incremental-release rule. Phase 2 primitives (`ccbde4d`), Phase 3 responsive shell (`3da6712`), Phase 4 dashboard (`20a833c`), Phase 5 DataTable (`443e7d3`), Phase 6 forms + Phase 7 QA.

**The recurring finding is worth remembering: this codebase referenced five CSS utility classes that were never defined anywhere** — `glass`, `glass-strong`, `border-border-soft`, `focus-ring`, and by extension anything relying on them. Tailwind emits nothing for an unknown class and reports no error, so each of these silently rendered an element unstyled: secondary buttons and the confirm modal had no background, the sidebar had no border, five form controls had no focus ring. They surfaced one at a time across phases until a deliberate grep in Phase 7 (`grep custom class names in code vs. definitions in globals.css`) found the rest. **When adopting a design-token system in Tailwind, audit for referenced-but-undefined utilities early — the failure is invisible rather than loud.**

Two judgement calls to preserve. **System Status deliberately under-reports**: it shows the API health route with measured latency and marks database and deployment as "not reported", because the admin has no endpoint for those and a dashboard asserting unverified health is the same false-green that hid the five-day stale deploy. **The users page was not migrated onto the new DataTable**: the primitive is done, but that page threads server-driven sort, filters and pagination through 500 lines, and converting it while five phases sat uncommitted was how regressions get shipped — logged as a follow-up instead.

Also fixed a second surface of the password vulnerability found in the audit: the login page's "Forgot password?" dialog **printed `Admin12345` on screen** after resetting the account, advertising the takeover credential. Since the endpoint is now super-admin only, that form would have failed with 401 anyway; replaced with an honest explanation rather than a button that silently breaks.

Technical notes: `useMediaQuery` uses `useSyncExternalStore` rather than effect+setState (matchMedia is external mutable state, and the naive version tripped `react-hooks/set-state-in-effect`); the shell derives collapsed state from the breakpoint instead of syncing it, so an explicit user choice survives a resize; and TanStack's `ColumnDef` is invariant in its value type, so the generic table's column prop needs `any` rather than `unknown`.

### 2026-08-03 — Users/workouts pages onto the new primitives, and a shell redesign
Three independent commits, each deployed and verified on its own: users page onto the shared `DataTable` (`a8d339a`), workouts rebuilt as drill-down CRUD tables plus a new day-update endpoint (`350577f`), and the sidebar/topbar redesigned to a supplied mockup.

**The workouts work needed an API addition that only surfaced by checking.** The plan was a UI change, but `PATCH /workouts/days/:dayId` did not exist — days were create/delete only. Editing a day therefore meant deleting and re-adding it, **which cascades and destroys its exercises**. Rendering an Edit button on the days table without adding that route would have been a CRUD table that only looked complete. Added route, controller and service mirroring the existing exercise pattern. **Check the API surface before designing a CRUD screen; the missing verb is invisible from the UI side.**

Also replaced "disable the button while a field is blank" with real Zod range checks: `sets`, `reps` and `kcal` were `parseInt`'d with no bounds, so a typo like `999999` saved silently.

**The mockup omitted three working controls** — logout, theme switch and sidebar collapse. Rather than delete them to match the screenshot, logout and theme moved into a sidebar account menu and collapse into the brand row on hover; the mobile menu button survives because below `md` there is no rail and the drawer would otherwise be unreachable. Matching a design should not cost a feature the design simply didn't depict.

Two lint rules pushed back on the sync indicator in sequence: `react-hooks/purity` (calling `Date.now()` in the render body) and then `react-hooks/set-state-in-effect` (the obvious fix). The working answer is `useSyncExternalStore` with a snapshot **quantised to the tick interval** — an unquantised `Date.now()` snapshot re-renders forever, since the value differs on every read. Same underlying lesson as `useMediaQuery` in Phase 3: this codebase's lint config rejects the effect+setState idiom, and the external-store form is what it wants.

### 2026-08-06 — Media phases 7-8: background downloads + media analytics
Completed the last two items of the media programme, both of which were genuinely unbuilt (preloading was already done and verified 2026-08-05; the CDN code is written and blocked only on a DNS record).

**Background downloads.** New `flutter_app/lib/services/media_downloader.dart`, deliberately separate from `MediaPreloader`: preloading is a guess held in a cache the OS may evict, this is a promise, so files live in application support and include the video itself. LRU eviction against a 512 MB default budget, 30-day expiry swept on startup and after every download, orphan cleanup for files the index lost track of, atomic `.part` -> rename so an interrupted download can never be mistaken for a complete one, and `ValueNotifier<DownloadProgress>` driving a three-state download control in the Day Detail app bar. `GlowImage` and `ExerciseVideoPlayer` now prefer a downloaded file over the network, which is what makes an offline workout actually play. Storage used / limit / Clear added to App Settings.

**Media analytics.** New `MediaAnalytics` (Flutter) buffers image load time, video startup delay, cache hit/miss, buffer events, download failures and transferred bytes, flushing in batches of 25, every 30s, and on app pause; capped at 200 buffered events so a dead network cannot grow it without bound. New API module `media-metrics` (`POST /api/media-metrics` rate-limited + `optionalAuth`, `GET /api/media-metrics/summary` admin-only), `MediaEvent` model + hand-written migration `20260806120000_add_media_events`, 60-day retention pruned on ingest rather than by a scheduled job. New admin page **Settings -> Media Performance** showing medians and p95 (not just averages — the slow tail is the interesting part), cache hit ratio, average media size, buffer/failure counts, a per-day trend chart and the assets failing most often.

Image timing is measured through the cache manager rather than by wrapping the render path, so it reports time-to-bytes and not time-to-pixels; wrapping `CachedNetworkImage.imageBuilder` would have meant rebuilding every image widget by hand and risking a visual regression across the whole app for the sake of a number.

**Verification.** 13 new integration tests on the emulator, all passing, plus the 8 existing preloader tests re-run green after the `GlowImage` change (21 total). The budget test caught a real defect: a 1 MB clamp floor silently overrode the requested budget so eviction never ran — the floor was arbitrary and was removed, and eviction is now measured genuinely (103 KB -> 55 KB under a 56 KB budget, keeping the most-recently-used file). `flutter analyze` 0 errors / 8 pre-existing warnings; admin `tsc --noEmit` clean; API routes load (15 routers). Endpoints probed live: 422 on an invalid event type, 401 unauthenticated on the summary, and a valid POST reaching `prisma.mediaEvent.createMany()` and failing only on the unreachable DB (tunnel down) — so routing, validation, auth and the generated model are all confirmed. **The DB migration has never been applied and the dashboard has never rendered real data**, because the DB tunnel needs an interactive SSH password. Nothing committed, pushed or deployed.

### 2026-08-07 — Exercises made genuinely time-driven (finishing the in-flight change)
Picked up an uncommitted change that had reached the API and stopped there: `createExerciseSchema` had been rewritten to require `duration` and `rest`, with the reasoning written into the schema and the Prisma model as comments, but nothing downstream had been brought onto the new contract. Completed it across the admin and the app.

**The admin form was still the old contract.** Seconds was labelled "Seconds (alt)" and optional, sets and reps defaulted to 3 and 12, and duration defaulted to blank — precisely inverted from what now drives the workout. The form schema now mirrors the API field for field (a form that accepts what the API rejects produces a toast that explains nothing), seconds and rest lead the grid and are marked required, reps default to blank because a number nobody chose is worse than an empty field, and a line under the inputs says plainly which fields the timer reads. The exercises table leads with Seconds and badges a missing value **"Not set"** rather than an em dash, so rows still running on the client's estimate are findable instead of looking like an ordinary blank optional.

**Three real defects surfaced while wiring it up, none of them visible from reading the diff.**

First and worst: **`rest` was collected, validated, stored, and never used.** `WorkoutRestScreen` takes a `restSeconds` parameter defaulting to 20, and neither call site in `workout_active_screen_v2.dart` passed it — every rest in the app has always been 20 seconds regardless of what an admin saved. Making the field required without this would have been ceremony. Rest now comes from the exercise just *finished*, not the one coming up: recovery belongs to what was performed. That meant threading `restSeconds` through `ActiveExercise` (the view model, which carried only duration) and adding a `restSeconds` getter beside `durationSeconds` on the model. `WorkoutDetailScreen` deliberately does **not** pass one — its exercises come from `workout_library_exercises`, a different table with no rest column at all, so the default correctly stands.

Second: **clearing reps was impossible.** The API's schema comment anticipated it exactly — `nullish()` was chosen so a clear could be expressed — but the admin sent `undefined`, `JSON.stringify` drops undefined, and `createExerciseSchema.partial()` reads an absent key as "leave it alone", so the old value survived every attempt. The form now sends an explicit `null` on edit.

Third: **`required_error` on a coerced number can never fire.** `z.coerce` runs `Number()` before the type check, so a missing field arrives as `NaN`, never `undefined` — the carefully written "Seconds is required" was dead code and the user would have seen "Expected number, received nan". Verified by running the schema rather than reasoning about it; `invalid_type_error` covers absent and non-numeric together. **Lesson: `required_error` and `z.coerce` are mutually exclusive — always exercise a schema's failure paths, not just its happy path.**

Also checked and cleared a suspected fourth: `.partial()` on a field with `.default()` looked like it would silently reset `sets` to 1 and `order` to 0 on any PATCH that omitted them. Running it showed Zod 3's `.partial()` drops defaults, so the PATCH route is safe as written.

**Verification.** API schema exercised directly across eight cases (missing/short/valid duration, missing/negative rest, string coercion, explicit null reps, sets defaulting) — all correct. `tsc --noEmit` clean and `npm run lint` clean in the admin (one pre-existing unrelated warning). `flutter analyze` 0 errors / 8 pre-existing warnings, unchanged. App rebuilt and reinstalled on the Pixel8a emulator. **Not committed, not pushed, not deployed** — awaiting the user's on-device test.

**Environment finding:** the Android build fails on this machine with `Could not close incremental caches` / `this and base files have different roots`. The pub cache is on `C:` and the project on `F:`, and Kotlin's relocatable incremental caches relativize plugin sources against the project root, which cannot cross drives. Fixed with `kotlin.incremental=false` in `flutter_app/android/gradle.properties`. This is the same family as the Gradle file-lock noted on 2026-08-02 but a distinct cause — that one needed `gradlew --stop` and a directory delete, this one is structural and recurs on every clean build until the property is set.

### 2026-08-07 — Clip audio, a poster on the ready screen, and a countdown that stops losing seconds
Three user requests, one of which I got wrong first and had to back out.

**Sound.** `ExerciseVideoPlayer` called `setVolume(0)` unconditionally — every demo clip in the app has always been silent. Now a `muted` flag defaulting to sound on. Checked the obvious way this could be pointless before changing anything: ffprobe on two live clips shows `h264 + aac`, and `api/src/config/video.js` transcodes audio with `-c:a aac` rather than stripping it, so there was really something to hear. Confirmed on device via `dumpsys audio`: `AudioPlaybackConfiguration ... u/pid:10221 state:started ... USAGE_MEDIA CONTENT_TYPE_MOVIE mutedState:none ... 48000Hz stereo`. Note `setVolume(0)` only ever set the gain — ExoPlayer was decoding the audio track all along, so unmuting added no decode load.

**The ready screen, and the mistake.** The ask was for the ready screen to show the exercise clip as a thumbnail so the player would have no delay when the exercise starts. I built a prewarmed controller: the ready screen opened the clip, held it on its first frame, and handed the controller to the exercise screen through a small park/claim cache so it was opened once. It worked, and it broke playback. Two codec instances on one clip exhausted the device's graphics buffer pool and the decoder began failing to dequeue output buffers — `C2BqBuffer: last successful dequeue was 38083442 us ago, 3457 consecutive failures` — which the user sees as a clip that plays five seconds, stops, plays again. **The file's own comments had warned about exactly this** ("the pool is small — a handful of leaks and the next decoder can never dequeue a buffer"); I read them, wrote a handoff to keep only one controller alive, and still doubled peak codec usage across the transition.

Reverted to the clip's **poster frame** — a still the media pipeline already produces for every video, so it shows the same thing the paused player would have and costs no decoder at all. The lesson: the request was for a *thumbnail*, and I built a video player to display one still. **When the ask is for an image, an image is the implementation.**

Two things ruled out along the way rather than assumed. The buffer exhaustion was *not* accumulated damage from force-stopping the app mid-playback during testing — it reproduced within two minutes of a full `adb reboot`. And it was *not* the audio change, for the gain-vs-decode reason above.

**The countdown.** Yesterday's `e70717b` moved the ready and rest screens onto a wall-clock deadline because a decrementing counter loses a second per dropped tick and stops dead on a stall. **The active workout screen was never converted** and still decremented — which is what left it frozen at `00:24` with taps ignored while I was testing. Now on a deadline, with pause crediting its own time back so pausing cannot shorten an exercise. Also fixed the elapsed/kcal maths, which computed `_currentIndex * durationSeconds` — i.e. assumed every exercise is as long as the current one. This day has a 30s exercise followed by a 25s one, so it was already wrong in production; both now sum each exercise's own duration, as does the leave-dialog's "time elapsed".

**Confirmed the time-driven behaviour the user specified**, which needed no new code: the exercise ends on the admin's `duration` and the clip is set to loop, so a 32s clip under a 30s exercise is cut off at 30s, and a 28s clip under a 30s exercise restarts and plays 2s more. Progress and calories count from the exercise duration, never the clip length.

**Verification.** Full three-exercise workout driven on the emulator end to end: no freeze, rest screens counting the authored 15s, per-exercise durations honoured (30s / 25s / 30s), and back to the day screen. Playback sampled at 900ms intervals gave 6/6 distinct frames with **zero** `C2BqBuffer` lines. Ready screen visually confirmed showing the Jumping Jacks poster. `flutter analyze` 0 errors / 8 pre-existing warnings.

**Emulator note for future sessions:** driving this app by blind `adb shell input tap` is unreliable — the Workout tab is the *Library*, not the 30-day plan (that is Home -> Continue Workout), and the play button on a day card behaves differently depending on whether a workout is already in progress. Screenshot between taps rather than chaining them, and remember that real time passes between tool calls, so a 25s exercise can complete while a screenshot is being read.

### 2026-08-07 — Two workout-screen UI requests, and a card that had never worked
Both requested against screenshots, both verified on the emulator.

**Player capsule to 4%.** `_GlassCapsule`'s fill went from `black @ 0.32` to `0.04`. It still reads as glass rather than a flat panel because the 35-sigma `BackdropFilter` underneath is doing the legibility work, not the tint — worth remembering before anyone "simplifies" the blur away.

**The rest screen's "up next" card was broken, not merely unstyled.** It called `Image.asset(widget.nextExerciseImage)` — and that string is a URL for every exercise the API returns, so the asset load failed on every single render and fell through to the dumbbell placeholder. The card has never once shown an exercise in production; it read as a deliberate placeholder, which is why it survived this long. Now routed through `GlowImage` for `http` paths with the `MediaImage` threaded from all four `WorkoutRestScreen` call sites (both active screens, forward and backward), keeping the `Image.asset` branch for exercises still built from bundled assets.

The label gradient needed a second pass: these exercise stills are mostly white, and a straight `transparent -> black@0.55` fade left white text on near-white. Weighted it to `0.45` at 55% and `0.75` at the bottom.

**Same shape of bug as `Image.asset`-on-a-URL is worth watching for elsewhere** — it fails silently into a fallback that looks intentional.

### 2026-08-07 — Spoken countdown cues on the ready screen
`321.aac` fires the moment the circle turns 3 (the clip is 2.1s, so "three · two · one" lands on zero), then `readytogo.aac` plays with the circle held at zero and the exercise screen opens when it finishes. Skipping plays nothing and cuts off anything mid-word — a voice you cannot skip is exactly the wait the user declined by tapping the arrow.

**No new dependency.** The app had no audio package, and `video_player` decodes a bare AAC file fine on both platforms, so `AudioCue` (`lib/services/audio_cue.dart`) is built on it. The deciding factor was today's buffer-pool incident: an audio-only clip allocates no graphics buffers, so cues cannot compete with the exercise clips for decoder output buffers. Every failure path in `AudioCue` is deliberately silent — a missing or undecodable cue must cost a sound, never the start of a workout — and completion is driven by a position listener with a duration-plus-one-second timeout as a backstop.

Source files came from the repo root and were copied to `flutter_app/assets/audio/` with `- assets/audio/` added to pubspec. **A new asset directory needs a full rebuild; hot reload will not pick it up.**

**Verified on device by timing against `dumpsys audio`** rather than by listening, which is the only option here: at 7.4s into the 10s countdown an `AudioTrack` for uid 10221 reads `state:started` while a screenshot confirms the circle showing **3**; tapping the arrow at 7.6s leaves zero tracks by 8.4s with the exercise screen open at `00:30`. The normal path was confirmed separately — cue at 3, exercise screen afterwards with the clip's own audio running.

Careful with UI-driving timing when checking this: navigation taps take a few seconds, so an unmeasured `Start-Sleep` before tapping the skip arrow lands *after* the countdown has already finished and silently tests the normal path instead. Two runs did exactly that before the stopwatch was added.

### 2026-08-07 — First production deploy of the media system, plus today's workout work
Pushed 12 commits (`5cbe352..2b5e391`): the 8 media-system commits from 2026-08-06 that had been sitting unpushed, and today's 4. **This is the deploy that finally put the media pipeline into production** — it had been written, committed and never shipped.

Flagged the scope before pushing rather than after, because push to `main` auto-deploys: the user was choosing to release eight commits of never-deployed work, not just today's. They chose to push everything.

**The migration worry did not materialise.** `PROJECT_MEMORY` had recorded that `20260806120000_add_media_events` "has never been applied", so the expectation was that `prisma migrate deploy` would apply it mid-deploy. It reported `20 migrations found` / **`No pending migrations to apply`** — the migration was already live, presumably applied through the parallel `webhook.service` deploy path that runs alongside GitHub Actions. Worth remembering that a second deploy mechanism means the recorded DB state can be stale in either direction.

All three jobs green (build-check, deploy, verify). Probed live afterwards: `/api/workouts` 401, **`/api/media-metrics/summary` 401 rather than 404** — which is the proof the new module actually deployed, not merely that the server is up — admin 200, landing 200.

Client build `client-builds/GlowFit30-2026-08-07.zip` (60.3 MB APK, 29.6 MB zipped) built from this commit. Still debug-signed; no release keystore exists.

The two source cue files (`321.aac`, `readytogo.aac`) remain untracked at the repo root on purpose — the app ships the remuxed `.m4a` copies under `flutter_app/assets/audio/`, and the raw ADTS originals are what caused the 1ms-duration failure.
