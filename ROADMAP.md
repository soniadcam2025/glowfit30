# GlowFit — Product & Technical Roadmap
Generated: 2026-07-26 · Based on current codebase state (~75% weighted completion, see `PROJECT_STATUS.md`), the original `App-Admin-Api connection Task.md` plan (27/28 done), the technical/security/deployment audits performed on this repo, and the long-term vision already sketched in `docs/ARCHITECTURE.md` (subscriptions, gamification, AI recommendations, OTP login).

> Prioritization uses MoSCoW (**Must Have** / **Should Have** / won't-have-yet = **Future Features**), plus two cross-cutting lanes — **Technical Improvements** and **Infrastructure Improvements** — repeated per version since code-quality and ops work should ship alongside features, not be deferred indefinitely.

---

## Version 1.0 — "Production Launch"
**Theme:** close the gap between "feature-complete beta" and "safe to put in front of real users and app stores." Nothing here is a new feature — this is the hardening pass the project currently lacks.

### Must Have
- **Ship the in-progress Task 28** (Workout/Diet/Notification/App Settings sub-screens) — the last item on the original integration plan; already mid-implementation, just needs finishing, committing, and pushing.
- **Fix the hardcoded password-reset vulnerability** (`/auth/reset-password` currently resets any admin account to a literal, UI-displayed default password with no OTP/token verification) — replace with a signed, time-limited, emailed reset token.
- **Rotate and purge exposed credentials** — VPS (`sprsadmin`) and PostgreSQL (`glowfit_user`) passwords are currently sitting in plaintext in git-tracked files (`server/SERVER_SETUP_SUMMARY.md`, `help`) that have already been pushed to the remote.
- **Fix `GET /admin/chart-data`** — raw SQL references mismatched table-name casing (`"User"`/`"Progress"` vs. actual `users`/`progress`), almost certainly broken today.
- **Confirm and complete HTTPS** on both `api.glowfit30.com` and `admin.glowfit30.com` — last recorded status showed Cloudflare 521 on both; commit the certbot-generated 443 config back into the repo so it's reproducible.
- **Make the Admin Settings page functional, or remove it** — currently a super_admin-gated page whose "Save" button does nothing.
- **Reconcile Prisma schema/migration drift** — `User.fcmToken`, `Exercise.videoUrl`, `DietPlan.imageUrl` exist in `schema.prisma` with no matching migration; generate and commit the missing migration before it causes a production drift incident.
- **Fix nginx upload limit** — add `client_max_body_size` matching the API's 100MB video-upload ceiling; currently likely rejected at the proxy layer with a 413.

### Should Have
- Real foreign key between `WorkoutLibraryCategory` and `WorkoutLibraryItem` (currently linked only by free-text string matching).
- CSRF defense-in-depth (a token, not just the CORS allow-list) given `sameSite: 'none'` cookies in production.
- Consistent enumeration protection between `/auth/register` and `/auth/reset-password`.
- Complete `.env.example` (currently missing Firebase and Vultr S3 vars, which breaks a fresh clone's uploads/push/social login).
- Basic smoke-test coverage for auth, profile, and progress endpoints (there are currently zero automated tests anywhere in the repo).
- Clean up dead/mock code in `backend/` (`content.service.ts`'s fake network calls, unused table/skeleton components, empty stub routes).

### Technical Improvements
- Add a linter + minimal devDependency set to `api/` (currently has none at all).
- Add a graceful-shutdown hook (`SIGTERM` → close Prisma + HTTP server cleanly) before PM2 restarts.
- Resolve the double route-mounting (`/api/*` and bare `/*` both serve every route) — confirm intent and document it, or remove the redundant mount.
- Convert free-text "enum-like" fields (`DietPlan.type`, `Workout.level`, `WorkoutLibraryItem.difficulty`) to real Prisma enums to prevent casing/typo drift.
- Add the missing index on `Progress.workoutDayId` (currently only covered by a composite index led by `userId`, forcing sequential scans as the table grows).

### Infrastructure Improvements
- Stand up a minimal CI pipeline (lint + build, at least for `api/` and `backend/`) — currently zero CI/CD of any kind.
- Add a real deploy trigger for the API (GitHub Actions SSH step, or a signed webhook) — `deploy.sh` exists but is never invoked automatically today.
- Add a PM2 `ecosystem.config.cjs` for the admin app (`backend/`) — it currently has no committed process definition and is started ad hoc on the server.
- Set up PostgreSQL backups — explicitly flagged as "not yet completed" in the server setup notes; currently no recovery path if the VPS is lost.
- Disable root SSH login / password auth on the VPS, key-only access going forward.

---

## Version 1.1 — "Stabilize & Scale-Ready"
**Theme:** the app is live; now make it resilient to real traffic and easier to operate day-to-day, without adding major new user-facing surface area.

### Must Have
- Move rate limiting and the admin-stats cache from in-memory to Redis-backed — currently tied to a single PM2 fork instance; would silently misbehave the moment the API scales to more than one process.
- Consistent RBAC enforcement across the admin panel — today only the `/settings` page uses the client-side role guard; extend it (or the equivalent server-side check) to every role-restricted route, and hide nav items by role.
- JWT handling hardening — eliminate the admin panel's `localStorage` JWT copy (XSS-exposed) in favor of routing all API calls through the existing Next.js BFF/cookie session.
- Expand automated test coverage beyond smoke tests — critical paths (auth, progress logging, admin content CRUD) should have real regression coverage before the next feature push.

### Should Have
- Refresh-token rotation for the JWT scheme (currently a single 7-day token with no rotation/blacklist beyond an `isBlocked` check) — mentioned as a future item in `docs/ARCHITECTURE.md`.
- Structured logging (replace ad hoc `console.log`/`console.error` calls, especially the `AUTH_DEBUG`-gated login logging) with a real logger and log levels.
- Extract shared CRUD/table/filter components in the admin panel — `workouts`, `workout-library`, `diet`, and `beauty` pages currently each hand-roll near-identical 400–1000 line form/list/delete patterns.
- Centralized PM2 log paths + rotation (`pm2-logrotate`) instead of default unmanaged log growth.

### Technical Improvements
- Standardize API error-response conventions across modules that currently validate inline (`admin`, `notifications`) vs. via the shared Zod middleware.
- Add deploy locking (e.g. `flock`) and a post-restart health check to `deploy.sh` so bad deploys are caught immediately instead of discovered by users.
- Document and enforce a git branching workflow (short-lived feature branches + PRs) now that the project is stable enough to benefit from review gates — history so far is 32 direct-to-`main` commits with no branches ever used.

### Infrastructure Improvements
- Introduce a staging environment separate from production (currently one VPS serves both roles conceptually — there's no isolated place to test a deploy before it hits real users).
- Prepare PM2 cluster-mode readiness (contingent on the Redis-backed rate-limit/cache work above) for horizontal scaling under load.
- Add uptime/alerting monitoring (even a simple external ping + Slack/email alert) — there is currently no automated way to know the API or admin app is down.

---

## Version 2.0 — "Growth & Monetization"
**Theme:** the platform-vision items already named in `docs/ARCHITECTURE.md` but never started — turning GlowFit from a content app into a business.

### Must Have
- **Subscriptions/monetization** — payment provider integration, subscription tiers, entitlement checks gating premium workout/diet/glow content (the admin panel's "Premium banner" is currently static, a placeholder for exactly this).
- **Gamification** — streaks (partially present via `Progress` streak calc), badges/achievements, and light competitive elements (leaderboards) to drive retention.
- **iOS release readiness** — current build artifacts (`client-builds/`) are Android APKs only; needs App Store packaging, Apple Sign-In (not just Google) for App Store compliance, and TestFlight distribution.

### Should Have
- **AI-driven recommendations** — personalized workout/diet suggestions based on onboarding profile + progress history (named as a future direction in the architecture doc).
- **OTP login** as an alternative to password/social login.
- Wearable data integration (Apple Health / Google Fit step & heart-rate sync) — natural extension of the existing progress-tracking feature set.
- Community/social layer (comments or reactions on Glow content, shared progress milestones).

### Technical Improvements
- Real media pipeline for uploads — video transcoding/thumbnailing rather than raw pass-through S3 storage, especially once subscription-gated premium video content exists.
- Product-analytics event pipeline (distinct from the current admin operational dashboard) to actually measure the growth/monetization features once shipped.
- Re-evaluate the API surface for a formal versioning scheme (`/v1/...`) now that breaking changes become more consequential with paying users.

### Infrastructure Improvements
- Containerize both services (Docker) for portability and reproducible environments — currently deployed via manual `npm ci` + PM2 directly on bare VPS.
- Move media storage/delivery behind a CDN in front of object storage (the architecture doc's original Cloudflare R2 intent, or Vultr's CDN equivalent) for global content delivery as user base grows.
- Payment-provider webhook infrastructure (signature verification, idempotent event handling) — new attack surface that needs the same rigor recommended for the GitHub deploy webhook in v1.1.

---

## Version 3.0 — "Platform Maturity & Scale"
**Theme:** GlowFit as a mature, scaled platform rather than a single-VPS app — this version is intentionally speculative and should be re-scoped once v2.0 usage data exists.

### Must Have
- Multi-region / high-availability infrastructure — outgrow the single Ubuntu VPS model entirely once real load or geographic user distribution demands it.
- Managed database migration (move off single-VPS PostgreSQL to a managed/replicated service) with point-in-time recovery.
- Full audit logging and data-privacy compliance tooling (GDPR-style user data export/delete) — `AdminLog` exists today but cascades away on user deletion, losing audit history; this needs a durable, compliance-grade design.

### Should Have
- Advanced admin analytics/BI (cohort retention, funnel analysis) beyond the current signups/completions charts.
- Marketplace or partner integrations (certified trainers/nutritionists offering content or coaching through the platform).
- AI chat-based coaching assistant (conversational layer on top of the v2.0 recommendation engine).

### Technical Improvements
- Evaluate splitting the monolithic API into focused services (e.g., content/CMS vs. user/auth vs. notifications) only if team size or deployment cadence actually demands it — avoid speculative microservices before there's a concrete scaling pain point.
- Event-driven architecture (message queue) for notifications, analytics ingestion, and media processing pipelines, decoupling them from the request/response cycle.

### Infrastructure Improvements
- Autoscaling compute and a full observability stack (metrics, distributed tracing, centralized log aggregation, alerting) — replacing the current PM2-on-one-VPS operational model.
- Multi-environment promotion pipeline (dev → staging → production) with automated rollback.
- Disaster-recovery plan with tested restore procedures, not just backups.

---

## Future Features (Beyond v3.0 / Unscheduled)

Long-horizon ideas worth tracking but not yet worth scheduling into a specific version — revisit once the platform has real usage data to justify investment:

- Live-streamed workout/beauty classes.
- Full social feed (posts, follows, shared routines) rather than lightweight reactions.
- White-label/multi-tenant support if a B2B offering (e.g., licensing GlowFit to gyms/studios) becomes a business direction.
- Localization/multi-language content and UI.
- In-house content creation tools for trainers (vs. admin-only content management today).

---

## How to Use This Roadmap

- **v1.0 is not optional feature work — it's debt repayment.** Every item in it already exists as a known issue in the current codebase (see `PROJECT_STATUS.md` → Known Issues); shipping v1.0 means the project reaches the production-readiness its feature set already earned.
- **Must Have** items block moving to the next version; **Should Have** items are strongly recommended but can slip one version if capacity is tight; **Future Features** are explicitly out of scope until a version is scoped around them.
- Re-derive this roadmap after each version ships — in particular, v2.0's monetization/gamification scope should be validated against actual v1.x user data before locking in, and v3.0 should be treated as directional, not committed.
