# GlowFit — Release Process

Defines how a change moves from idea to verified production deployment. **Current reality check:** most of the automation described below (CI, auto-deploy, automated tests) does not exist yet — this document defines the target process and is honest about which steps are currently manual. See `TODO.md` 🟢 Infrastructure for the work needed to close each gap.

---

## Development Flow

```
Read PROJECT_MASTER.md / PROJECT_RULES.md / SPRINT.md / TODO.md / CHANGELOG.md
        │
        ▼
Determine: does this already exist? → refactor instead of duplicating (Rule 1)
        │
        ▼
Code the feature/fix (Coding)
        │
        ▼
Verify build (Testing)
        │
        ▼
Update docs (PROJECT_MASTER.md, CHANGELOG.md, TODO.md, API_REFERENCE.md/DATABASE_SCHEMA.md if relevant)
        │
        ▼
Git Commit (Conventional Commits)
        │
        ▼
Git Push (only after explicit confirmation)
        │
        ▼
Auto Deployment (where wired up) / manual deploy runbook (current reality)
        │
        ▼
Verification (health check / manual confirmation)
```

## Coding

- Follow `PROJECT_RULES.md` (no duplication, consistent folder structure, existing per-app coding standards in `docs/BACKEND_RULES.md`/`FLUTTER_RULES.md`/`ADMIN_RULES.md`/`API_CONVENTIONS.md`).
- Keep changes scoped to one logical feature/fix — avoid bundling unrelated changes into one commit (see `PROJECT_MASTER.md` §11 Git Status re: past oversized commits).

## Testing

**Current state:** zero automated tests exist in any of the three apps. Until that's fixed (`TODO.md` 🟡):
- `api/`: manually exercise the changed endpoint(s) (e.g. via curl/Postman) and confirm the Prisma schema/migration pair is consistent (`npx prisma validate`, `npx prisma migrate status`).
- `backend/`: run `npm run build` (Next.js build catches type errors and most runtime-breaking issues) and manually click through the changed page.
- `flutter_app/`: run `flutter analyze` and, where feasible, `flutter test`; manually verify the changed screen on an emulator/device.
- **Target state (v1.1+):** minimal smoke-test suite per app wired into CI, required to pass before merge.

## Git Commit

- Every commit uses Conventional Commits: `type(scope): description`. Valid types: `feat`, `fix`, `refactor`, `perf`, `docs`, `style`, `test`, `chore`.
- Never generic (`update`, `changes`, `fixed`, `work`, `done`).
- One commit per logical unit of work — don't squash unrelated changes together (contrast with the project's largest historical commits, e.g. 252-file/16k-line commits that are hard to bisect/revert).

## Git Push

- Push only to `main` (no branching model currently in use — see `PROJECT_MASTER.md` §11).
- **Always ask before pushing** — a drafted commit is not authorization to push; confirm with the user first every time, per standing git-safety rules.
- Never force-push.

## Auto Deployment

**Target state:** a GitHub Actions workflow or signed webhook triggers `api/deploy.sh` on push to `main` (see `TODO.md` 🟢). **Current reality:** none exists — `api/deploy.sh` must be run manually over SSH; the admin app (`backend/`) has no deploy script at all and is deployed via a manual tar/upload/build/PM2-start sequence (see `deployment-report.md`).
- Until automation exists, treat every deploy as a manual runbook step and say so explicitly rather than implying it happened automatically.

## Verification

After any deploy (manual or automated):
1. `curl -sI https://api.glowfit30.com/` → expect `200` + JSON health payload.
2. `curl -sI https://admin.glowfit30.com/` → expect `200`/`3xx` from Next.js.
3. Spot-check the specific feature/fix that was deployed (the actual changed behavior, not just "is the server up").
4. Check PM2 process status (`pm2 status`) and recent logs for crash loops.

If any check fails → proceed to Rollback.

## Rollback

1. Identify the last known-good commit (the one before the bad deploy).
2. On the VPS: `git checkout <previous-commit-or-tag>` in the app directory, then re-run the deploy steps (`npm ci --omit=dev`, `npx prisma migrate deploy` **only if safe to reverse** — see note below, `pm2 restart`).
3. **Migration caveat:** if the bad deploy included a destructive/irreversible migration, a code rollback alone won't fix the DB — you may need a compensating migration instead of a pure revert. Never blindly roll back code past an already-applied irreversible migration.
4. Re-run Verification above to confirm the rollback actually fixed the issue.

## Production Checklist

Before any deploy reaches `api.glowfit30.com` / `admin.glowfit30.com`:
- [ ] Build verified (see Testing).
- [ ] `PROJECT_MASTER.md`, `CHANGELOG.md`, `TODO.md` updated.
- [ ] Conventional Commit message generated and reviewed.
- [ ] No secrets/plaintext credentials in the diff (checked, not assumed).
- [ ] Migration (if any) reviewed for reversibility.
- [ ] User has explicitly approved the push.

## Version Numbering

No versions are tagged yet. Recommended scheme once `v1.0.0` is ready (see `ROADMAP.md` for what "ready" means):
- **SemVer** (`MAJOR.MINOR.PATCH`) per the overall project, tagged in git (`git tag v1.0.0`), independent of the three apps' own `package.json`/`pubspec.yaml` versions (which can stay per-app but should be bumped in lockstep with a project tag for any release that touches them).
- `MAJOR` — breaking API changes, major architecture shifts (aligns with the version boundaries already defined in `ROADMAP.md`: v1→v2→v3).
- `MINOR` — new features, backward-compatible.
- `PATCH` — bug fixes, security patches, no new features.
- Pre-1.0 hardening work can be tagged `v0.9.0-beta` etc. if a staging checkpoint is useful before the real v1.0.0.

## Release Checklist

- [ ] All Must Have items for the target version (see `ROADMAP.md`) are done.
- [ ] `RELEASE_NOTES.md` updated with the version's narrative summary.
- [ ] `CHANGELOG.md` entries for the cycle consolidated under the new version heading.
- [ ] Git tag created (`git tag vX.Y.Z && git push origin vX.Y.Z`) — only after explicit user approval.
- [ ] `PROJECT_MASTER.md` §19 Version History updated.

## Deployment Checklist

- [ ] Confirmed target environment (`api/` vs `backend/`, or both).
- [ ] `.env` on the server has all required vars (cross-check `API_REFERENCE.md`/`DATABASE_SCHEMA.md` for anything new).
- [ ] Prisma migration applied (`npx prisma migrate deploy`) **before** app restart.
- [ ] PM2 process restarted, `pm2 save` run.
- [ ] Verification steps (above) completed and confirmed passing.

## Hotfix Process

For urgent production-breaking bugs (skip normal sprint planning, not normal quality gates):
1. Reproduce and confirm the bug against production behavior.
2. Fix with the smallest possible diff — no unrelated cleanup in a hotfix.
3. Still run Testing and Verification in full — a hotfix that isn't checked can make things worse.
4. Commit as `fix(scope): description` — hotfixes still use Conventional Commits, no exceptions.
5. Deploy immediately via the same manual/automated path as a normal release.
6. Update `CHANGELOG.md`, `TODO.md`, and `PROJECT_MASTER.md` §16 Known Issues immediately after, not "later."

## Emergency Rollback Process

For when a deploy is actively causing user-facing failures right now:
1. **Don't diagnose first — roll back first.** Restore the last known-good commit and restart the process (see Rollback above) before investigating root cause.
2. If the bad deploy included an irreversible migration, prioritize a compensating fix over a full rollback (see Rollback §3 caveat).
3. Confirm recovery via Verification steps immediately.
4. Only after service is restored: investigate root cause, document it in `CHANGELOG.md` and `PROJECT_MASTER.md` §16, and add a regression check (test, or at minimum a manual verification step) so it can't silently recur.

---
*Last Updated: 2026-07-26*
