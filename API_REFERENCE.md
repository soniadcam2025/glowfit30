# GlowFit API Reference

Base: Express 4 + Prisma 6, `api/src`. Every route below is mounted at **both** `/api/<path>` and bare `/<path>` (see Technical Debt — double mounting is unresolved/undocumented intent). Auth key: **Public** = no token, **Auth** = valid JWT (cookie `token` or `Authorization: Bearer`), **Admin** = Auth + role `admin`/`super_admin`.

## Auth — `/auth`
| Method | Path | Auth | Rate limit | Notes |
|---|---|---|---|---|
| POST | `/auth/register` | Public | 30/15min | Gated by `REGISTER_ENABLED` env flag |
| POST | `/auth/firebase` | Public | 30/15min | Verifies Firebase ID token, find-or-create user, returns API JWT |
| POST | `/auth/login` | Public | 30/15min | Email+password (admin/user) |
| POST | `/auth/logout` | Public | — | Clears auth cookie |
| GET | `/auth/me` | Auth | — | Returns sanitized current user |
| POST | `/auth/reset-password` | Public | 30/15min | ⚠️ Resets to hardcoded default password, see SECURITY.md |

## Profile — `/profile` (all Auth)
| Method | Path | Notes |
|---|---|---|
| GET | `/profile/` | Current user's profile |
| PATCH | `/profile/` | Update profile fields |
| PATCH | `/profile/fcm-token` | Save device FCM push token |

## Progress — `/progress` (all Auth)
| Method | Path | Notes |
|---|---|---|
| POST | `/progress/` | Log a workout-day completion |
| GET | `/progress/` | List + streak calculation |

## Users — `/users` (all Admin)
| Method | Path | Notes |
|---|---|---|
| GET | `/users/` | Paginated list, filters: `q`, `status`, `goal`, `fitnessLevel`, sort |
| GET | `/users/:id` | Detail |
| GET | `/users/:id/progress` | User's progress/streak history |
| PATCH | `/users/:id/block` | Block/unblock; invalidates `admin:stats` Redis cache |

## Admin — `/admin` (all Admin)
| Method | Path | Notes |
|---|---|---|
| GET | `/admin/stats` | Redis-cached 60s |
| GET | `/admin/analytics` | Weekly signups/completions/active users |
| GET | `/admin/chart-data` | ⚠️ **Likely broken** — raw SQL references `"User"`/`"Progress"` (case-sensitive, don't match actual lowercase tables) |

## Workouts — `/workouts`
| Method | Path | Auth | Notes |
|---|---|---|---|
| GET | `/workouts/` | Auth | List |
| GET | `/workouts/:id` | Auth | Detail |
| POST | `/workouts/` | Admin | Create |
| PATCH | `/workouts/:id` | Admin | Update |
| DELETE | `/workouts/:id` | Admin | Delete |
| GET | `/workouts/:id/days` | Auth | List days |
| POST | `/workouts/:id/days` | Admin | Create day |
| DELETE | `/workouts/days/:dayId` | Admin | Delete day |
| GET | `/workouts/days/:dayId/exercises` | Auth | List exercises |
| POST | `/workouts/days/:dayId/exercises` | Admin | Create exercise |
| PATCH | `/workouts/exercises/:id` | Admin | Update exercise |
| DELETE | `/workouts/exercises/:id` | Admin | Delete exercise |

## Workout Library — `/workout-library`
| Method | Path | Auth | Notes |
|---|---|---|---|
| GET | `/workout-library/categories` | Auth | Declared before `/:id` to avoid UUID-param collision |
| POST/PATCH/DELETE | `/workout-library/categories[/:categoryId]` | Admin | |
| GET | `/workout-library/` | Auth | List items |
| GET | `/workout-library/:id` | Auth | Detail |
| POST/PATCH/DELETE | `/workout-library/[:id]` | Admin | Item CRUD |
| GET | `/workout-library/:id/exercises` | Auth | |
| POST | `/workout-library/:id/exercises` | Admin | |
| PATCH/DELETE | `/workout-library/exercises/:exerciseId` | Admin | |

## Diet — `/diet`
| Method | Path | Auth | Notes |
|---|---|---|---|
| GET | `/diet/` | Auth | List plans |
| GET | `/diet/today` | Auth | Registered before `/:id` intentionally |
| GET | `/diet/:id` | Auth | Detail |
| POST/PATCH/DELETE | `/diet/[:id]` | Admin | Plan CRUD |
| GET | `/diet/:id/days` | Auth | Per-day meals |
| PUT/DELETE | `/diet/:id/days/:day` | Admin | Upsert/remove day |

## Beauty — `/beauty`
| Method | Path | Auth |
|---|---|---|
| GET `/beauty/`, GET `/beauty/:id` | Auth |
| POST/PATCH/DELETE `/beauty/[:id]` | Admin |

## Glow — `/glow`
| Method | Path | Auth |
|---|---|---|
| GET `/glow/categories`, GET `/glow/shorts` | Auth |
| POST/PATCH/DELETE `/glow/categories[/:id]` | Admin |
| POST/PATCH/DELETE `/glow/shorts[/:id]` | Admin |

## Notifications — `/notifications` (all Admin)
| Method | Path | Notes |
|---|---|---|
| POST | `/notifications/send` | FCM push, single user or broadcast |

## Uploads — `/uploads` (all Admin)
| Method | Path | Notes |
|---|---|---|
| POST | `/uploads/` | Image, memory storage, 5MB limit, `image/*` only |
| POST | `/uploads/video` | Video, 100MB limit, `video/mp4` only — ⚠️ nginx may reject before reaching Express, see deployment docs |

## Response Envelope

All endpoints return via `utils/response.js` helpers:
```json
{ "success": true, "data": { ... }, "message": "..." }
{ "success": false, "message": "...", "data": { ... } }
```
Validation failures (Zod) return HTTP 422 with `data` containing `.flatten()` field errors. `admin` and `notifications` modules validate inline rather than via the shared Zod middleware (inconsistency, tracked in Technical Debt).

## Rate Limits

- Global: 400 req / 15 min / IP (in-memory, per-process).
- Auth endpoints (`register`, `firebase`, `login`, `reset-password`): 30 req / 15 min / IP.

---
*Source: derived from `api/src/modules/*/[module].routes.js`. Last verified: 2026-07-26.*
