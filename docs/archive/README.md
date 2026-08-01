# Archived documentation

These files are **historical records, not current state**. They were moved out of the
repo root on 2026-08-01 because several of them read as authoritative but had gone
stale, which is worse than having no document at all.

Nothing here is deleted — per `PROJECT_RULES.md`, project history is preserved.

| File | What it is | Superseded by |
|---|---|---|
| `documentation.md` | Original project doc, last updated 2026-05-23 | `PROJECT_MASTER.md` |
| `App-Admin-Api connection Task.md` | The original 28-task App↔Admin↔API integration plan — **completed 28/28** on 2026-07-26 | — (finished) |
| `PROJECT_HEALTH_REPORT.md` | Point-in-time health audit, 2026-07-26 (score 65/100) | Regenerated per audit; see `PROJECT_RULES.md` cadence |
| `PROJECT_STATUS.md` | Point-in-time status snapshot, 2026-07-26 | `PROJECT_MASTER.md` + `SPRINT.md` |
| `deployment-report.md` | Point-in-time infra audit, 2026-07-26 | `DEPLOYMENT.md` (living doc) + `server/nginx/live/` |

**Do not treat figures in these files as current** — notably, the port mappings and
"HTTPS unverified" claims in `deployment-report.md` are both known to be wrong as of
2026-08-01. See `server/nginx/live/README.md` for verified production config.

## Current canonical docs (repo root)

`PROJECT_MASTER.md` · `PROJECT_RULES.md` · `SPRINT.md` · `TODO.md` · `CHANGELOG.md` ·
`PROJECT_MEMORY.md` · `ROADMAP.md` · `API_REFERENCE.md` · `DATABASE_SCHEMA.md` ·
`SECURITY.md` · `RELEASE_NOTES.md` · `RELEASE_PROCESS.md` · `DEPLOYMENT.md`
