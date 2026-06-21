# GlowFit — App · Admin · API Connection Task List

---

## Architecture Overview

- **Flutter App** — 22 screens (onboarding + core features), GetX state management, Firebase Auth (Google Sign-In)
- **API** — Express.js REST API, Prisma ORM, PostgreSQL, Redis, JWT auth
- **Admin Dashboard** — Next.js 14 App Router, React Query, TypeScript, Role-based access
- **Database** — PostgreSQL (project: `glowfit-beta-829ea`)

### Auth Flow (decided & implemented)
```
Flutter → Google Sign-In → Firebase Auth
        → Flutter gets Firebase ID Token
        → POST /auth/firebase  (sends ID Token to API)
        → API verifies with Firebase Admin SDK
        → API finds or creates user in DB (no password stored)
        → API returns own JWT → Flutter stores it for all future requests
```
Admin dashboard login → `POST /auth/login` (email + password, admins only)

---

## Phase 1 — API Foundation

> Expand the database schema and API endpoints. Nothing in Flutter or Admin can work without the correct data structure.

- [x] 1. Add user profile fields to DB schema — `fitnessLevel`, `goal`, `dietStyle`, `targetWeight`, `focusAreas`, `dob`, `height`, `weight` + `firebaseUid`, `photoUrl`. Also added `WorkoutDay`, `Exercise`, `Progress` models. Schema validated ✓
- [x] 2. `POST /auth/firebase` endpoint — Flutter sends Firebase ID Token → API verifies with Firebase Admin SDK (service account configured ✓) → finds or creates user → returns JWT. `password` field made optional. `POST /auth/register` updated to also accept full profile fields.
- [x] 3. Create `GET /profile` and `PATCH /profile` endpoints for the logged-in user
- [x] 4. ~~Add `WorkoutDay` model~~ — Done in Task 1 (schema)
- [x] 5. ~~Add `Exercise` model~~ — Done in Task 1 (schema)
- [x] 6. `GET /workouts/:id/days`, `GET /workouts/days/:dayId/exercises` + admin write endpoints (POST/PATCH/DELETE for days & exercises)
- [x] 7. ~~Add `Progress` model~~ — Done in Task 1 (schema). `POST /progress` and `GET /progress` with streak calculation
- [x] 8. Seed script created (`npm run db:seed`). Migration ready — run commands below when DB tunnel is active

> **Note:** Tasks 4 and 5 (models) were completed as part of Task 1 schema work. Task 7 model was also done in Task 1.

---

## Phase 2 — Flutter App · API Integration

> Connect every screen to real data from the API. Replace all hardcoded values.

- [x] 9.  Create `ApiService` in Flutter — base HTTP client with JWT token header and base URL config
- [x] 10. On Google Sign-In complete → call `POST /auth/firebase` with Firebase ID Token, store returned JWT in GetStorage
- [x] 11. Replace hardcoded home screen data (420 kcal, 45 min, DAY 3/30, Full Body Fat Burn) with live API data
- [x] 12. Workout plan screen → fetch real workout + day data from `GET /workouts`
- [x] 13. Workout day detail screen → use real exercises from API (`GET /workouts/days/:dayId/exercises`)
- [x] 14. On workout complete → call `POST /progress` to save completion to DB
- [x] 15. Diet screen → fetch real diet plan from `GET /diet`
- [x] 16. Add token refresh / auto logout on 401 unauthorized errors

---

## Phase 3 — Admin Dashboard · Content Management

> Give the admin full control over the content that appears in the Flutter app.

- [x] 17. Workout creation form → add day-by-day builder with an exercise list per day
- [x] 18. Exercise manager page — add / edit / delete exercises with image upload support
- [x] 19. Diet plan form → assign plans to user fitness goal types (weight loss, muscle gain, etc.)
- [x] 20. Dashboard stats → add "Today's active workouts" and "Completions today" from real DB data
- [x] 21. User detail page → show each user's full onboarding profile + workout progress history

---

## Phase 4 — Polish & Professional

> Final integrations to make the product production-ready.

- [x] 22. Push notifications — admin sends notification from dashboard → users receive it in Flutter app
- [x] 23. Image upload for exercises and diet plans — Vultr Object Storage (S3-compatible)
- [x] 24. User streak logic on API — calculate and return current streak count daily
- [x] 25. Analytics page in admin — signups per day, workout completion rate, active users chart

---

## Progress Tracker

| Phase | Total Tasks | Completed | Status |
|-------|------------|-----------|--------|
| Phase 1 — API Foundation | 8 | 8 | ✅ Complete |
| Phase 2 — Flutter Integration | 8 | 8 | ✅ Complete |
| Phase 3 — Admin Dashboard | 5 | 5 | ✅ Complete |
| Phase 4 — Polish | 4 | 4 | ✅ Complete |
| **Total** | **25** | **25** | ✅ All tasks complete |

---

## Environment & Keys

| Item | Status |
|------|--------|
| Firebase Project | `glowfit-beta-829ea` |
| Firebase Admin SDK | Installed (v14) ✓ |
| Service Account Key | Configured in `api/.env` ✓ (gitignored — never commit) |
| PostgreSQL | `glowfit_db` on port 5433 |
| JWT Secret | ⚠️ Change `JWT_SECRET` in `.env` before going to production |
| Vultr Object Storage | ⚠️ Add `VULTR_S3_*` vars to `api/.env` (see Task 23 notes below) before image upload will work |

---

## Notes

- Complete Phase 1 fully before starting Phase 2 or Phase 3.
- Phase 2 and Phase 3 can be worked on in parallel once Phase 1 is done.
- Phase 4 begins only after Phase 2 and Phase 3 are stable.
- Update the Progress Tracker above as each task is completed.
- **NEVER commit `api/.env`** — it contains the Firebase service account private key.
