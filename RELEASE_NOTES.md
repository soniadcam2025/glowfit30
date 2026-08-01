# GlowFit Release Notes

No formal release has been tagged yet (`git tag -l` is empty) — the project has been in continuous, untagged development since 2026-04-09. These notes summarize progress at a milestone level; see `CHANGELOG.md` for the granular technical log.

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
