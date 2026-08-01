# GlowFit — Project Rules

**These rules are mandatory for every future development session on GlowFit.** They govern how work is done, not what work is done (see `PROJECT_MASTER.md`/`SPRINT.md`/`TODO.md` for that). Any deviation must be flagged to the user before proceeding, not silently applied.

---

### 1. Never create duplicate code
Before writing anything new, check whether equivalent functionality already exists (a service method, a component, a util, an endpoint). If it exists, extend or refactor it rather than adding a parallel implementation. Applies across all three apps (`api/`, `backend/`, `flutter_app/`) — e.g. don't add a second axios instance, a second CRUD pattern, or a second auth helper.

### 2. Never change architecture without documenting it
Any change to the system's shape — a new service boundary, a new data flow, a new external dependency, a new module pattern — must be reflected in `PROJECT_MASTER.md` §3 (Architecture) and, if relevant, `docs/ARCHITECTURE.md`, *before or as part of* the same change. Undocumented architecture drift is exactly what caused `docs/ARCHITECTURE.md` to go stale in the first place — don't repeat it.

### 3. Always update PROJECT_MASTER.md
After every completed feature or bug fix, update the relevant section(s) of `PROJECT_MASTER.md` in place (Completed/Pending Features, Known Issues, Technical Debt, Current Sprint, etc.) so it stays the accurate single source of truth.

### 4. Always update CHANGELOG.md
Append a new entry (never edit/delete a past one) describing what was added, changed, fixed, or flagged as a security concern.

### 5. Always update TODO.md
Check off completed items in place; add newly discovered tasks; never silently delete a task — if it's no longer relevant, mark it and note why in the same line or in `CHANGELOG.md`.

### 6. Always generate a Conventional Commit message
Every commit follows `type(scope): description` (see the Conventional Commits section in `RELEASE_PROCESS.md`). Never use generic messages like `update`, `changes`, `fixed`, `work`, `done`.

### 7. Always verify build before committing
Run the relevant build/typecheck/lint for whatever was touched (`npm run build` for `backend/`, a syntax/import sanity check for `api/`, `flutter analyze`/`flutter build` for `flutter_app/`) before proposing a commit. Never propose a commit for code known to fail its build.

### 8. Always verify deployment after push
After a push that's expected to reach production, check the deployed result (health endpoint, page load, or equivalent) rather than assuming the deploy succeeded. Note: this requires either manual verification by the user or CI/deploy tooling with actual access — see `RELEASE_PROCESS.md` → Verification.

### 9. Never remove existing features without confirmation
If a change would remove or disable user-facing functionality (not dead/unused code — an actual working feature), stop and confirm with the user first, even if the feature seems redundant or low-value.

### 10. Maintain coding standards
Follow the existing per-app conventions already documented in `docs/BACKEND_RULES.md`, `docs/FLUTTER_RULES.md`, `docs/ADMIN_RULES.md`, and `docs/API_CONVENTIONS.md`. Match the modular controller/service/routes/validation pattern in `api/`; match the existing component/hook conventions in `backend/`; match the existing GetX/service-layer conventions in `flutter_app/`.

### 11. Keep folder structure consistent
New modules/features go in the existing structural slot (e.g., a new API module gets `controller.js`/`routes.js`/`service.js`/`validation.js` like its siblings; a new admin page goes under the existing `(admin)` route group). Don't introduce a parallel structure for convenience.

### 12. Maintain API documentation
Any new/changed/removed endpoint must be reflected in `API_REFERENCE.md` in the same change.

### 13. Maintain database documentation
Any new/changed model, field, relationship, or migration must be reflected in `DATABASE_SCHEMA.md` in the same change — and must have an actual committed Prisma migration (no more schema/migration drift, see `PROJECT_MASTER.md` §16).

### 14. Maintain deployment documentation
Any change to how the app builds, runs, or deploys (PM2 config, nginx config, env vars, deploy steps) must be reflected in `docs/archive/deployment-report.md` and/or `RELEASE_PROCESS.md`.

---

## Enforcement

These rules apply to every session, every feature, every fix — regardless of size. "Before writing any code" and "after completing work" obligations are defined precisely in the standing workflow (see the project's saved development-process instructions); this file is the rulebook that workflow points back to. If a rule conflicts with an explicit, in-the-moment user instruction, the user's instruction wins for that instance — but the conflict should be surfaced, not silently resolved.

---
*Last Updated: 2026-07-26*
