# GlowFit Database Schema

PostgreSQL via Prisma (`api/prisma/schema.prisma`), generator `prisma-client-js`, no preview features. `migration_lock.toml` locks provider to `postgresql`.

## Enum
`UserRole { super_admin, admin, user }`

## Models (18)

| Model | Table | Notes |
|---|---|---|
| `WaterIntake` | `water_intakes` | userId→User (cascade), amountMl, loggedAt. Backs the hydration tracker and day-streak goal; was missing from this table until 2026-08-06. |
| `MediaAsset` | `media_assets` | Media pipeline output. baseKey unique, kind (`image`\|`video`), original/thumb/medium/large URLs + bytes, mime, blurhash, videoUrl, posterUrl, durationSeconds, width/height, legacyUrl unique (traceability for the backfill). Indexed on largeUrl and videoUrl, because a response is resolved by whichever URL the content row happens to hold. **Uncommitted, not deployed.** |
| `MediaEvent` | `media_events` | Client telemetry: type, ms, bytes, cacheHit, ok, url (path only), platform, appVersion, userId (nullable and unenforced — metrics must survive a deleted account). 60-day retention pruned on ingest. **Uncommitted, not deployed.** |
| `User` | `users` | email/firebaseUid unique, password nullable (social-only accounts), role, isBlocked, onboarding profile fields (fitnessLevel, goal, dietStyle, targetWeight, focusAreas[], dob, height, weight), waterGoalLiters, pushEnabled, fcmToken, **language** (new), **appearance** (new) |
| `LegalDocument` | `legal_documents` | title (default "Privacy Policy & Terms"), content (Text), updatedAt — singleton-style, no relations; new 2026-07-26 |
| `Workout` | `workouts` | title, level, duration, imageUrl, description, goal → `WorkoutDay[]` |
| `WorkoutDay` | `workout_days` | workoutId→Workout (cascade), dayNumber, title, focus, imageUrl, durationMinutes, kcal → `Exercise[]`, `Progress[]` |
| `Exercise` | `exercises` | workoutDayId→WorkoutDay (cascade), name, **duration** (seconds — this is what the player counts down), **rest** (seconds after the exercise), sets, reps (informational only), imageUrl, gifUrl, videoUrl, order. `duration`/`rest` are **NOT NULL as of 2026-08-08** (`20260808120000_exercise_duration_rest_not_null`). They were left nullable through the move to a time-driven player so exercises authored beforehand were neither rejected nor backfilled with an invented number; by the time the constraint went on, every row already carried a real value. The Flutter client keeps its `durationSeconds`/`restSeconds` fallbacks in `workout_model.dart` as cheap defensive code against an older API. |
| `Progress` | `progress` | userId→User (cascade), workoutDayId→WorkoutDay (cascade), completedAt, caloriesBurned, durationMin; unique(userId, workoutDayId) |
| `DietPlan` | `diet_plans` | type, goal, calories, meals(Json, legacy), imageUrl → `DietPlanDay[]` |
| `DietPlanDay` | `diet_plan_days` | dietPlanId→DietPlan (cascade), dayNumber, meals(Json); unique(dietPlanId, dayNumber) |
| `WorkoutLibraryCategory` | `workout_library_categories` | name(unique), headingLine1/2, description, heroImageUrl, tags(Json), section, card* styling fields |
| `WorkoutLibraryItem` | `workout_library_items` | isFeatured, category(free-text), difficulty, titleLine1/Script, description, heroImageUrl, durationMinutes, kcalLabel, focusLabel, tags(Json) → `WorkoutLibraryExercise[]` |
| `WorkoutLibraryExercise` | `workout_library_exercises` | workoutLibraryItemId→Item (cascade), name, durationSeconds, imageUrl, videoUrl |
| `BeautyPost` | `beauty_posts` | title, content, imageUrl, tag, tagColor, tagBackground, minutesRead, **categoryId→GlowCategory (SetNull)**, **resultBadge, chips(Json), sections(Json), isPremium** (all new 2026-07-26) |
| `GlowCategory` | `glow_categories` | emoji, title, subtitle, background, **heroImageUrl, topics(Json)** (new) → `posts BeautyPost[]`, `shorts GlowShort[]` |
| `GlowShort` | `glow_shorts` | imageUrl, duration(String), title, views(String), **categoryId→GlowCategory (SetNull)**, **content, resultBadge, chips(Json), sections(Json), isPremium** (all new 2026-07-26) |
| `AdminLog` | `admin_logs` | adminId→User (cascade), action, metadata(Json?) |

## Relationships

All one-to-many/many-to-one, all `onDelete: Cascade`, no many-to-many or one-to-one:

```
Workout ──< WorkoutDay ──< Exercise
                       └─< Progress >── User ──< AdminLog
DietPlan ──< DietPlanDay
WorkoutLibraryItem ──< WorkoutLibraryExercise
WorkoutLibraryCategory ⇢ WorkoutLibraryItem   (soft/string-matched, NOT a real FK)
GlowCategory ──< BeautyPost   (categoryId, onDelete: SetNull — real FK, added 2026-07-26)
GlowCategory ──< GlowShort    (categoryId, onDelete: SetNull — real FK, added 2026-07-26)
```

## Migration History (chronological)

1. `20250409120000_init` — users, workouts, diet_plans, beauty_posts, admin_logs
2. `20260614000000_add_profile_and_workout_models` — profile/social fields on users; workout_days, exercises, progress
3. `20260625220000_add_workout_day_image_url`
4. `20260626040000_add_workout_day_duration_kcal`
5. `20260709000000_add_diet_plan_days`
6. `20260711000000_add_workout_library` — workout_library_items/exercises
7. `20260712000000_add_workout_library_categories`
8. `20260713000000_add_workout_library_featured`
9. `20260714000000_add_workout_library_category_cards`
10. `20260714010000_add_glow_content` — glow_categories, glow_shorts
11. `20260714020000_add_user_preferences` — water_goal_liters, push_enabled
12. `20260726120000_add_app_settings_language_appearance_legal` — language, appearance on users; new legal_documents table
13. `20260726150000_add_glow_category_links` — categoryId FK on beauty_posts/glow_shorts → glow_categories; heroImageUrl/topics on glow_categories
14. `20260726170000_add_glow_content_detail_fields` — resultBadge/chips/sections/isPremium on beauty_posts and glow_shorts; content on glow_shorts
15. `20260802090000_add_glow_short_placement_flags`
16. `20260803120000_add_water_tracking` — water_intakes
17. `20260803140000_add_streak_goal`
18. `20260804180000_add_media_assets` — media_assets ⚠️ **not yet applied to production**
19. `20260804190000_add_video_and_blurhash_to_media_assets` ⚠️ **not yet applied to production**
20. `20260806120000_add_media_events` — media_events (newest) ⚠️ **not yet applied to production**

Entries 15–17 were missing from this list until 2026-08-06 — the files were on disk and committed, only the documentation had fallen behind; their applied state was not re-verified when this list was corrected. Entries 18–20 exist on disk and are **uncommitted and unapplied everywhere** — the local DB is reached through an SSH tunnel that needs an interactive password, so they could not be run even locally.

Migrations after `init` use defensive `IF NOT EXISTS`/`DO $$ EXCEPTION` guards — historically mixed `prisma migrate` and `prisma db push` usage across environments.

## ⚠️ Known Migration-History Gap (confirmed, not a live bug)

**Verified live 2026-07-26** (via `information_schema.columns` query against the actual database, and `prisma migrate diff`): all three of the columns below **already exist in the live database** — this is not an active schema mismatch or runtime risk. The gap is purely in the committed migration history: no migration file adds these columns, meaning they were applied out-of-band (almost certainly via `prisma db push`, consistent with the defensive `IF NOT EXISTS` guards seen in migrations after `init`). A fresh environment built from `prisma migrate deploy` alone (new staging server, CI, disaster recovery) would **not** get these columns and would drift from production. Still needs a migration generated and committed for reproducibility — just not urgent as a live-data risk:
- `User.fcmToken` (confirmed present in DB)
- `Exercise.videoUrl` (confirmed present in DB)
- `DietPlan.imageUrl` (confirmed present in DB)

`prisma migrate status` reports "Database schema is up to date!" (all 11 committed migrations applied) — this check does NOT catch the gap above since it only compares applied-migration records, not actual column-level schema; that's why the manual `information_schema` check was needed to confirm reality.

Additionally, the DB has a unique index `workout_days_workout_id_day_number_key` (workout_id, day_number) not mirrored by `@@unique` in the Prisma model.

## Design Issues (tracked in Technical Debt)

- `Progress.workoutDayId` has no standalone index (only covered by a composite unique led by `userId`) — will force sequential scans as the table grows.
- `WorkoutLibraryCategory` ↔ `WorkoutLibraryItem` is string-matched, not FK-enforced — orphaned/typo'd categories possible.
- Free-text fields that should be enums: `DietPlan.type`, `Workout.level`, `WorkoutLibraryItem.difficulty`, `GlowShort.duration`/`views` (should be numeric).
- `User.password` nullable with no CHECK ensuring at least one of `password`/`firebaseUid` is set.
- `DietPlan.meals` marked "legacy" in a code comment but never dropped — duplicated with `DietPlanDay.meals`.
- Cascading `User` deletes wipe `AdminLog` — no audit-trail preservation.

## Seed Scripts

- `api/scripts/seed.mjs` — idempotent (fixed UUIDs, upsert): 2 workouts, 3 workout-days, 10 exercises, 2 diet plans. Does **not** seed Progress, DietPlanDay, WorkoutLibrary*, BeautyPost, GlowCategory, GlowShort, AdminLog.
- `api/scripts/seed-admin.mjs` — bootstraps one `super_admin` from `ADMIN_EMAIL/PASSWORD/NAME` env vars.

---
*Source: `api/prisma/schema.prisma` + `api/prisma/migrations/`. Last verified: 2026-07-26.*
