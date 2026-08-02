# GlowFit Release Notes

No formal release has been tagged yet (`git tag -l` is empty) — the project has been in continuous, untagged development since 2026-04-09. These notes summarize progress at a milestone level; see `CHANGELOG.md` for the granular technical log.

## 2026-08-02 — Glow module, deployment integrity, and the admin UI foundation

Three milestones landed in one day, each deployed and verified independently.

**Glow module** (`f7e7028`) — the "View All" headers on the Glow screen finally do something: a Glow Reads hub and a Shorts & Quick Tips hub, both filterable. Shorts gained editorial placement flags (Featured / Trending / Quick Tip) so the hub's layout is an admin decision rather than an accident of sort order. The article detail screen was rebuilt to a new design.

**Deployment integrity** (`d32a740`) — the most consequential fix. Admin deploys had been reporting success for five days without ever updating the live site: the pipeline restarted a PM2 process that had never started successfully, while the process actually serving production was never touched. The health check passed throughout because it only asked "is something answering?", not "is it the thing we just built?". Deployment verification now proves the running application matches the deployed commit, and a stale deploy fails instead of passing.

**Admin UI Foundation, Phase 1** (`b574f22`) — a semantic design-token system and System/Light/Dark theming, laying the groundwork for a staged admin redesign. No pages migrated yet; this is the layer the rest builds on. The admin is also no longer blocked on mobile.

## Unreleased — v1.0 Candidate ("Production Launch")

**Status:** ~75% weighted completion (see `docs/archive/PROJECT_STATUS.md` for the full breakdown). Feature-complete for an MVP; a hardening pass is required before this becomes a real `v1.0.0`.

**What's in it:**
- Complete fitness + beauty content platform: workouts (day-plan + standalone library), diet plans, Glow beauty content, progress tracking with streaks, push notifications, media uploads.
- Full admin CMS for every content type, with dashboard stats and analytics charts.
- Firebase social login (Google Sign-In) + traditional email/password admin login.

**What's blocking the tag:**
- A hardcoded admin password-reset vulnerability.
- Plaintext credentials currently committed to the repo.
- Unverified HTTPS status on both public subdomains.
- A likely-broken analytics endpoint (`/admin/chart-data`).
- Zero automated test coverage.

See `TODO.md` 🔴 Critical/Security and `ROADMAP.md` v1.0 for the exact punch list.

## Milestone History (pre-tag)

### Content & Glow (2026-07-13 → 2026-07-16)
Shipped the Glow beauty/content hub, made Workout Library category cards fully admin-managed, rebuilt Profile & Settings to match Figma, added the Progress screen, fixed a persistent bottom-nav highlight bug.

### Workout Library & Diet (2026-07-09 → 2026-07-13)
Shipped a standalone browsable Workout Library separate from day-plan workouts (categories, difficulty filter, hero workout), and per-day diet meal plans end-to-end.

### Core Feature Buildout (2026-06-14 → 2026-06-26)
The largest single push: full Flutter workout flow, API + admin dashboard integration (Phase 2+3 of the original plan), push notifications, media uploads, analytics page, user streaks, diet screens.

### Foundation (2026-04-09 → 2026-04-10)
Initial monorepo setup — Express API, Next.js admin, Postgres/Prisma schema, JWT+cookie auth, VPS provisioning (nginx, PM2, Postgres, Redis, firewall).

## Versioning Going Forward

See `RELEASE_PROCESS.md` → Version Numbering for the proposed SemVer scheme once `v1.0.0` is ready to tag.

---
*Last updated: 2026-07-26*
