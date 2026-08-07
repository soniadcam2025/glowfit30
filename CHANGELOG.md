# Changelog

Format loosely follows [Keep a Changelog](https://keepachangelog.com/). No versions have been tagged yet (`git tag -l` is empty) — entries below are reconstructed from git history and grouped by theme/date under `[Unreleased]` until a `v1.0.0` is cut. **Append-only from this point forward**: add new entries above `[Unreleased]`'s prior content or as new dated subsections; never delete or rewrite a past entry.

---

## [Unreleased]

### Added (2026-08-07, spoken countdown cues)
- **The "READY TO GO" countdown now speaks.** `assets/audio/321.aac` (2.1s) starts the moment the circle turns 3, so "three · two · one" lands on zero; `assets/audio/readytogo.aac` (1.2s) then plays with the circle held at zero, and the exercise screen opens when it finishes. **Skipping ahead plays nothing** — tapping the arrow silences any cue mid-word and goes straight through, because someone who skips the countdown has said they do not want to wait for it.
- **`AudioCue`** (`flutter_app/lib/services/audio_cue.dart`) — one-shot cue playback built on the existing `video_player` rather than a new audio dependency. An audio-only clip allocates no graphics buffers, so cues stay clear of the decoder pool the exercise clips compete for. Every failure path is silent by design: a missing or undecodable cue costs a sound, never the start of a workout.

### Fixed (2026-08-07, rest screen's next-exercise card)
- **The "up next" card has never shown an exercise.** It called `Image.asset` on `nextExerciseImage`, which is a URL for every exercise the API returns, so the load failed every time and the dumbbell placeholder rendered instead. Network paths now go through `GlowImage` (cached, right-sized, blurhash-backed) and the media object is threaded through from all four call sites; the asset branch stays for exercises still built from bundled assets. The card also carries the exercise name and duration over a bottom gradient.

### Changed (2026-08-07, active workout capsule)
- **The player capsule is now 4% black instead of 32%**, so it reads as glass over the clip rather than a panel on top of it. The 35-sigma backdrop blur is what keeps the white text legible at that tint.

### Added (2026-08-07, exercise clip audio)
- **Exercise demo clips now play their audio.** `ExerciseVideoPlayer` called `setVolume(0)` unconditionally, so every clip was silent regardless of what was uploaded. Volume is now a `muted` flag defaulting to sound on. The clips do carry audio — both sampled files probe as `h264 + aac`, and the pipeline transcodes audio to AAC rather than stripping it.

### Changed (2026-08-07, ready screen shows the clip's poster)
- **The "READY TO GO" screen now shows the first exercise's poster frame** instead of the day's cover image, so the user sees the exercise they are about to do. The poster is a still taken from the clip itself, which the media pipeline already produces for every video.

### Fixed (2026-08-07, workout countdown)
- **The active workout countdown decremented a counter once a second**, so every tick the device failed to deliver lost a whole second, and a bad stall left the number frozen where it stood. It now reads from a wall-clock deadline, like the rest and ready screens already did — a recovered stall catches up and the exercise still ends on the seconds an admin set. Pause credits its time back to the deadline rather than shortening the exercise.
- **Elapsed time and calories assumed every exercise shared the current one's duration** (`_currentIndex * durationSeconds`). With a 30s exercise followed by a 25s one that is simply wrong; both now sum each exercise's own duration. The leave-workout dialog's "time elapsed" used the same broken formula.

### Reverted (2026-08-07)
- **A prewarmed video controller on the ready screen.** It opened the clip during the countdown and handed the controller to the exercise screen so playback started instantly. Two codec instances for one clip exhausted the device's graphics buffer pool: the decoder spent tens of seconds failing to dequeue an output buffer (`C2BqBuffer: ... 3457 consecutive failures`), which presents as a clip playing in bursts — a few seconds, a stall, a few more. Reverted in favour of the poster, which costs no decoder. **Reachability of a frame is not the same as capacity to decode it.**

### Changed (2026-08-07, exercises are time-driven)
- **`duration` and `rest` are now required** when creating or editing an exercise — in the API (`createExerciseSchema`) and in the admin form, which previously labelled seconds "Seconds (alt)" and left it optional. `duration` is what the player counts down; reps are informational and now optional and clearable. The columns stay **nullable on purpose**: exercises authored before this change have no value, and a NOT NULL column would mean either rejecting those rows or inventing a number for them. Requiring it at the edge means everything new or edited carries a real duration while the old rows keep working on the client fallback.
- **The admin exercises table leads with Seconds** and flags a missing value as a "Not set" badge rather than an em dash, so the rows still running on the client's estimate are visible instead of blending in with an empty optional field.

### Fixed (2026-08-07)
- **The admin-authored `rest` value never reached the player.** `WorkoutRestScreen` was never passed `restSeconds`, so every rest between exercises ran on its hardcoded 20-second default regardless of what was saved. The rest screen now uses the rest of the exercise just finished — recovery belongs to what was performed, not to what is coming up.
- **Clearing reps on an existing exercise did nothing.** The admin sent `undefined`, which `JSON.stringify` drops, and the PATCH route reads an absent key as "leave it alone", so the old value survived. It now sends an explicit `null`, which the API already accepted for exactly this case.
- **`required_error` on a coerced number is unreachable** — `z.coerce` runs `Number()` first, so a missing field arrives at the type check as `NaN`, never `undefined`. `duration` and `rest` were reporting "Expected number, received nan" instead of "Seconds is required"; both now use `invalid_type_error`, which covers absent and non-numeric alike.
- **Android build failed on this machine** with `Could not close incremental caches` / `this and base files have different roots`: the pub cache is on `C:` and the project on `F:`, and Kotlin's relocatable incremental caches relativize plugin sources against the project root. `kotlin.incremental=false` in `android/gradle.properties`.

### Added (2026-08-06, Media phases 7–8)
- **Offline downloads** (`flutter_app/lib/services/media_downloader.dart`) — downloads a day's images, posters and clips to application support so a workout plays with no connection. LRU eviction against a 512 MB budget, 30-day expiry, orphan cleanup, atomic `.part` → rename, and a download/cancel/remove control in the Day Detail app bar. `GlowImage` and `ExerciseVideoPlayer` prefer a downloaded file over the network.
- **Storage controls in App Settings** — bytes used against the limit, and a Clear action. Media is the only thing this app puts on someone's phone at scale; a figure they cannot find or clear is how an app gets uninstalled.
- **Media analytics** — `MediaAnalytics` (Flutter) buffers image load time, video startup delay, cache hit/miss, buffer events, download failures and transferred bytes; flushes in batches of 25, every 30s, and on app pause, capped at 200 events. New API module `media-metrics`: `POST /api/media-metrics` (rate-limited, `optionalAuth`) and `GET /api/media-metrics/summary` (admin-only), backed by a new `MediaEvent` model with 60-day retention pruned on ingest.
- **`optionalAuth` middleware** (`api/src/middleware/auth.js`) — attaches `req.user` when a token is present and proceeds when it is not, for endpoints where identity is useful but a rejection would silently blind the metric.
- **Admin page: Settings → Media Performance** — medians *and* p95 rather than averages alone, cache hit ratio, average media size, buffer/failure counts, a per-day trend chart, and the assets failing most often.
- **Migration `20260806120000_add_media_events`** — hand-written, per the standing schema-drift rule.

### Fixed (2026-08-06)
- **`MediaDownloader.budgetBytes` clamped its floor to 1 MB**, silently substituting a different budget than the one requested so eviction never ran below that. Caught by a new integration test, not by reading. The floor was arbitrary and has been removed — only the ceiling is clamped now, and zero is a coherent instruction meaning "keep nothing".

### Added (2026-08-03)
- **`PATCH /workouts/days/:dayId`** — days were create/delete only, so editing one meant deleting and re-adding it, destroying its exercises in the process.
- **Workouts admin rebuilt as drill-down CRUD tables** (Workouts → Days → Exercises) with every create/edit in a modal and Zod range validation on all numeric fields. Previously three always-visible inline forms with no validation beyond a disabled button, and `sets`/`reps`/`kcal` were `parseInt`'d unbounded.
- **Sidebar/topbar redesigned** to a supplied reference: dot-marker nav with a pink active pill and accent bar, an account block pinned to the sidebar foot (name + role from `/auth/me`), and a minimal topbar carrying only a sectioned breadcrumb ("Content / Workouts") and a live sync indicator.
- **`SyncStatus`** — reads the newest successful fetch from the React Query cache; green when fresh, amber past 5 minutes, blue while fetching, red on error. Real state, not a decorative timestamp.

### Changed (2026-08-03)
- **Users page migrated onto the shared `DataTable`**, gaining column visibility, a sticky header, skeleton rows, a filter-aware empty state and name sorting (which the API already supported but the UI never exposed). Sorting remains server-side.
- Logout and the theme switch moved from the topbar into the sidebar account menu, and the desktop collapse control into the sidebar brand row — the reference design has no topbar controls, but removing the functions outright would have traded working features for a visual match.

### Added (2026-08-02, Admin UI Phases 2–7)
- **Phase 2 — core primitives** (`ccbde4d`): badge, skeleton, alert, tabs, dialog, sheet, dropdown-menu (Radix-backed), plus card/input/state upgraded in place with signatures preserved.
- **Phase 3 — responsive shell** (`3da6712`): desktop collapsible rail, tablet auto-collapse to icons, mobile Sheet drawer, breadcrumbs derived from the nav table. `/desktop-only` deleted.
- **Phase 4 — dashboard** (`20a833c`): spring-based animated counters honouring `prefers-reduced-motion`, tone-coded stat cards, Quick Actions, and a System Status panel.
- **Phase 5 — DataTable** (`443e7d3`): generic TanStack table with sortable headers (`aria-sort`), column visibility, sticky header, row selection and horizontal scroll. Sorting is manual when controlled, since these pages paginate server-side.
- **Phase 6 — form layer**: React Hook Form + Zod bindings that auto-wire `id`/`aria-invalid`/`aria-describedby` and announce errors via `role="alert"`; login page migrated.

### Fixed (2026-08-02, Admin UI — five undefined CSS classes)
The upgrade surfaced a recurring class of defect: utility classes referenced throughout the codebase but **defined nowhere**, so the elements using them silently rendered unstyled.
- `glass` — secondary buttons had no background (Phase 1)
- `glass-strong` — `ConfirmModal` had no panel background (Phase 2)
- `border-border-soft` — sidebar and three form controls had no border (Phases 3, 7)
- `focus-ring` — five form controls had no focus affordance (Phase 7)
- `ConfirmModal` was also inaccessible: no focus trap, focus restore, Escape handling, or background inerting. Now Radix-backed.

### Security (2026-08-02)
- The admin login page's "Forgot password?" dialog **displayed the shared default password `Admin12345` on screen** after resetting the account — a second surface of the unauthenticated-takeover vulnerability. It now explains that a super admin issues one-time passwords, rather than posting to an endpoint that would return 401.

### Added (2026-08-02, Admin UI Foundation — Phase 1)
- **Semantic design token system** (`globals.css`): `background / surface / surface-2 / foreground / muted / muted-foreground / border / input / ring / primary / secondary / success / warning / danger / info` as HSL variables for light and dark, registered as Tailwind utilities via `@theme inline`. Components now style against `bg-surface` / `text-muted-foreground` rather than `bg-slate-900`, so re-theming is a one-file change. Primary is the app's brand pink `#FF136B`.
- **Theme system**: System / Light / Dark via `next-themes`, with a segmented toggle in the topbar. Required `@custom-variant dark` (without it Tailwind v4 keeps following `prefers-color-scheme` and the in-app toggle does nothing) and `suppressHydrationWarning` on `<html>`.
- **Tooltip primitive** (Radix) and an accessible **ThemeToggle** with `role="radiogroup"`, ARIA labels and mounted-guard to avoid a pre-hydration flash.
- Libraries added, none removed: `next-themes`, `@tanstack/react-table`, `react-hook-form`, `zod`, `@hookform/resolvers`, and Radix primitives (dialog, dropdown-menu, tabs, tooltip, slot, checkbox, select, label). Only three are imported so far; the rest are staged for the table and form phases.

### Changed (2026-08-02, Admin UI Foundation — Phase 1)
- **Button** keeps all four existing variant names (no call site changed), moves onto tokens, and gains `size` (sm/md/lg/icon), `outline`/`link` variants, `asChild` and a forwarded ref.
- **Topbar** rebuilt with icon buttons, tooltips, ARIA labels and a sticky frosted header.
- **Mobile block removed**: the middleware user-agent sniff that redirected every phone to `/desktop-only` is gone, so later responsive work can reach real devices. `/desktop-only` is now unreachable and will be deleted in Phase 3.

### Fixed (2026-08-02, deployment)
- **Admin deploys had never updated the live site.** `ecosystem.config.cjs` declared the app as `glowfit-backend` with no PORT, so Next defaulted to 3000 — held by the API — and the process crash-looped on `EADDRINUSE`, never starting once (45 restarts). Production was actually served by a separate `glowfit-admin` entry on 3001 that deploys never touched, so the live admin served a build from 2026-07-28 for five days while every deploy reported success. The health check only asserted HTTP 200, which a stale process answers identically.
- `.glass` was referenced by the secondary Button variant but had never been defined anywhere — secondary buttons rendered with no background.

### Added (2026-08-02, deployment)
- **`server/scripts/verify-deployment.sh`**: proves the running apps match the deployed commit — git SHA, PM2 status, stray PM2 entries, `BUILD_ID` and build timestamp against process start, ports, local HTTP and the three public endpoints. The decisive assertion is that the process started *after* the build was written. Wired into the CI `verify` job with `github.sha`, and mirrored as a post-restart gate inside `backend/deploy.sh`.

### Added (2026-08-02, Glow module)
- **Glow Reads hub** (`glow_reads_hub_screen.dart`): the "View All" destination for Glow Reads — hero, live stats card, Popular Topics chips that actually filter, Top Videos grid and a Latest Posts & Videos feed. Reached from the Glow screen's Reads header, which was previously decorative text with no tap handler at all.
- **Shorts & Quick Tips hub** (`glow_shorts_hub_screen.dart`): the "View All" destination for Shorts — title block, live title search, category filter pills, a Featured hero card, 2-column grid, and Trending Now / Quick Tips rows. Sections hide themselves when empty.
- **Editorial placement flags** on `GlowShort` — `isFeatured` / `isTrending` / `isQuickTip` (migration `20260802090000_add_glow_short_placement_flags`), surfaced as a "Placement" checkbox group in the admin. Chosen over deriving placement from sort order, view counts or duration so that featuring a clip is a deliberate editorial act rather than a side effect of how the list happens to sort.
- **`glow_common.dart`**: shared Glow constants, helpers and cards (`GlowVideoCard`, `GlowMixedCard`, `GlowFilterChips`, `GlowSectionHeader`) plus a single `openGlowItem()` router, so every Glow surface renders identical cards and routes taps the same way instead of each screen keeping its own copy.
- Admin short list now shows ★ Featured / 🔥 Trending / ⚡ Quick Tip badges, and warns when more than one short is marked Featured (the app shows only the first).

### Changed (2026-08-02, Glow module)
- **Glow content detail screen redesigned** to the supplied spec: bordered segmented tab bar with per-tab icons and a pink active underline, section heading plus intro line, and cards rebuilt as white bordered panels with a 96px image beside the title and description. Descriptions written as `-`/`*`/`•` lines now render as real bullet lists.
- Glow screen's "Explore Now" opened a "coming soon" snackbar; it now routes to the Premium screen via the same named route the Upgrade Now banner uses.

### Fixed (2026-08-02, Glow module)
- Section 3 of the admin Glow page still claimed "the first one (lowest sort order) is featured as the big tile", which stopped being true once placement flags existed.

### Added (2026-08-02)
- **Glow Shorts full-screen story player** (`glow_short_story_screen.dart`): tapping a Short in "Shorts & Quick Tips" now opens a story-style viewer — segmented progress bar, category pill, two-tone serif/script title, hashtag chips, timed scrubber, pink tip card with thumbnails, swipe-up paging, long-press to pause. Driven entirely by the existing `sections.tips` JSON, so **no schema change was required**. Each step shows its own media; a Short with no authored tips routes to the tabbed detail screen instead.
- **Per-tip video clips**: each Tips card can carry an optional MP4 (`videoUrl` inside the existing `sections` JSON — again no migration). Admin enforces a **30s maximum, checked client-side from file metadata before upload**, so over-length clips are rejected without consuming bandwidth or storage. In the app the clip plays full-screen with audio and its progress segment runs for the clip's real duration; only the visible tip holds a player, and an unreachable clip falls back to the still image.
- **Premium gating on Shorts**: premium Shorts show a `🔒 PREMIUM` badge, play the first tip as a free preview, then present Watch Ad / Go Premium (stubs, matching the detail screen — no ad SDK or payment backend exists yet).
- Admin `/beauty` Shorts editor now states that each Tips card becomes one step of the full-screen player, and marks the other two groups as reachable only via "View full details".

### Fixed (2026-08-02)
- **Silent data loss in the Glow sections editor**: `cleanSections()` drops any card missing a title or description, discarding uploaded images and clips with it. The save appeared to succeed and the content simply vanished. The editor now shows an explicit warning on any incomplete card.
- **`GET /glow/shorts` 500'd** after an `include` was added using `category.name` — `GlowCategory` has no `name` column, its display field is `title`. The app's blanket `catch` turned the 500 into an empty list, which rendered placeholder tiles and made the failure look like missing content.
- Shorts story background used the Short's cover image for every step, so per-tip images only ever appeared as small thumbnails of *upcoming* tips (and not at all on the last one). Each step now shows its own image or clip.
- `sectionItemSchema` stripped unknown keys, silently discarding `videoUrl` on save; it is now part of the schema.

### Ops (2026-08-02)
- Admin `/beauty` "Video thumbnail" relabelled "Cover image (full-screen background)" — there is no video field on `GlowShort`, so the old label implied an upload that does not exist.

### Added (2026-08-01)
- **Marketing landing page live at `glowfit30.com`**: the previously-unhosted homepage (separate repo <https://github.com/mayax2O/glowfit-homepage>, Vite + React 19 + framer-motion, pnpm, builds to `dist/`) is now served from the existing VPS. New `glowfit-web` nginx vhost serves static files from `/var/www/glowfit/web/current` with SPA fallback, 1-year immutable caching on `/assets/*`, and no-cache on `index.html`. Deploys use a release-directory + atomic symlink-swap scheme (`releases/<timestamp>/`, last 5 retained) so rollback is a single `ln -sfn` with no nginx reload. Let's Encrypt cert issued for the apex + `www`; all four public domains verified 200 over HTTPS.
- **`server/nginx/live/`**: verbatim mirrors of the four production vhosts (`api`, `admin`, `glowfit`, `glowfit-web`) plus a README documenting ports, the deploy/rollback scheme, and the backup location. The repo now has an accurate record of production nginx config for the first time.

### Fixed (2026-08-01)
- **Latent production-breaking port mismatch in the committed nginx config**: `server/nginx/glowfit30-subdomains.conf` mapped `api.glowfit30.com`→`:4000` and `admin.glowfit30.com`→`:3000`, but production actually runs the API on `:3000` and the Next.js admin on `:3001`. Applying that file (via `server/scripts/setup-subdomains.sh`) would have pointed the API subdomain at the admin panel, taken `admin.glowfit30.com` down entirely, and stripped every certbot TLS block. Found while reconciling live config during the landing-page work. The stale file is now marked DEPRECATED and the install script refuses to run without an explicit `I_KNOW_THIS_CONFIG_IS_STALE=yes` override.

### Ops (2026-08-01)
- Pre-landing-page nginx config backed up on the VPS at `/root/nginx-backup-20260801/`.
- Verified `client_max_body_size 110M` is **already present** in the live `api` vhost — the long-standing TODO item for it was stale, not outstanding.
- Noted (not yet resolved) that the apps run under `sprsadmin`'s PM2 (`/home/sprsadmin/.pm2`) and that an undocumented `webhook.service` auto-deploy is running alongside the newer GitHub Actions pipeline.

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
- `docs/archive/PROJECT_HEALTH_REPORT.md` — first run of the new weekly/pre-release health audit (Health Score 65/100).

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
- Full project documentation suite: `PROJECT_MASTER.md`, `PROJECT_RULES.md`, `SPRINT.md`, `RELEASE_PROCESS.md`, `DEPLOYMENT.md`, plus the earlier `docs/archive/PROJECT_STATUS.md`/`PROJECT_MEMORY.md`/`ROADMAP.md`/`docs/archive/deployment-report.md`/`API_REFERENCE.md`/`DATABASE_SCHEMA.md`/`SECURITY.md`/`RELEASE_NOTES.md`/`TODO.md`.

### Process note
This closes the original 28-task integration plan (`docs/archive/App-Admin-Api connection Task.md`) at **28/28**. Committed as `52e4983` with a non-Conventional-Commit message (`"26072026"`) that also bundled unrelated build artifacts (`client-builds/*.zip`, stray `VPS` file) — flagged in `PROJECT_MEMORY.md` as a git-hygiene item to prevent going forward, not rewritten since already pushed.

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
