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
| GET | `/profile/` | Current user's profile — now includes `language`, `appearance` |
| PATCH | `/profile/` | Update profile fields — now accepts `language`, `appearance` (2026-07-26) |
| PATCH | `/profile/fcm-token` | Save device FCM push token |

## Legal — `/legal` (new, 2026-07-26)
| Method | Path | Auth | Notes |
|---|---|---|---|
| GET | `/legal/` | Auth | Returns the current Privacy Policy & Terms document; auto-creates a default on first call |
| PATCH | `/legal/` | Admin | Updates the document's `title`/`content` |

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
| Method | Path | Auth | Notes |
|---|---|---|---|
| GET `/beauty/` | Auth | Accepts `?categoryId=` filter (new 2026-07-26) |
| GET `/beauty/:id` | Auth | |
| POST/PATCH/DELETE `/beauty/[:id]` | Admin | Now accepts `categoryId`, `resultBadge`, `chips`, `sections`, `isPremium` (all optional, new 2026-07-26) |

## Glow — `/glow`
| Method | Path | Auth | Notes |
|---|---|---|---|
| GET `/glow/categories` | Auth | |
| GET `/glow/categories/:id` | Auth | New (2026-07-26) — category detail + live `postsCount`/`shortsCount` |
| GET `/glow/shorts` | Auth | Accepts `?categoryId=` filter (new 2026-07-26) |
| POST/PATCH/DELETE `/glow/categories[/:id]` | Admin | Now accepts `heroImageUrl`, `topics` (new 2026-07-26) |
| POST/PATCH/DELETE `/glow/shorts[/:id]` | Admin | Now accepts `categoryId`, `content`, `resultBadge`, `chips`, `sections`, `isPremium` (all optional, new 2026-07-26) |

## Notifications — `/notifications` (all Admin)
| Method | Path | Notes |
|---|---|---|
| POST | `/notifications/send` | FCM push, single user or broadcast |

## Uploads — `/uploads` (all Admin)
| Method | Path | Notes |
|---|---|---|
| POST | `/uploads/` | Image, memory storage, 5MB limit, `image/*` only |
| POST | `/uploads/video` | Video, 100MB limit, `video/mp4` only — ⚠️ nginx may reject before reaching Express, see deployment docs |

## Rate Limits section note
`/legal` is not currently in the auth-specific rate limiter — covered only by the global 400/15min limiter, same as other content modules (`beauty`, `glow`, etc.).

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
