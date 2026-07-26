# GlowFit Database Schema

PostgreSQL via Prisma (`api/prisma/schema.prisma`), generator `prisma-client-js`, no preview features. `migration_lock.toml` locks provider to `postgresql`.

## Enum
`UserRole { super_admin, admin, user }`

## Models (14)

| Model | Table | Notes |
|---|---|---|
| `User` | `users` | email/firebaseUid unique, password nullable (social-only accounts), role, isBlocked, onboarding profile fields (fitnessLevel, goal, dietStyle, targetWeight, focusAreas[], dob, height, weight), waterGoalLiters, pushEnabled, fcmToken |
| `Workout` | `workouts` | title, level, duration, imageUrl, description, goal → `WorkoutDay[]` |
| `WorkoutDay` | `workout_days` | workoutId→Workout (cascade), dayNumber, title, focus, imageUrl, durationMinutes, kcal → `Exercise[]`, `Progress[]` |
| `Exercise` | `exercises` | workoutDayId→WorkoutDay (cascade), name, sets, reps, duration, rest, imageUrl, gifUrl, videoUrl, order |
| `Progress` | `progress` | userId→User (cascade), workoutDayId→WorkoutDay (cascade), completedAt, caloriesBurned, durationMin; unique(userId, workoutDayId) |
| `DietPlan` | `diet_plans` | type, goal, calories, meals(Json, legacy), imageUrl → `DietPlanDay[]` |
| `DietPlanDay` | `diet_plan_days` | dietPlanId→DietPlan (cascade), dayNumber, meals(Json); unique(dietPlanId, dayNumber) |
| `WorkoutLibraryCategory` | `workout_library_categories` | name(unique), headingLine1/2, description, heroImageUrl, tags(Json), section, card* styling fields |
| `WorkoutLibraryItem` | `workout_library_items` | isFeatured, category(free-text), difficulty, titleLine1/Script, description, heroImageUrl, durationMinutes, kcalLabel, focusLabel, tags(Json) → `WorkoutLibraryExercise[]` |
| `WorkoutLibraryExercise` | `workout_library_exercises` | workoutLibraryItemId→Item (cascade), name, durationSeconds, imageUrl, videoUrl |
| `BeautyPost` | `beauty_posts` | title, content, imageUrl, tag, tagColor, tagBackground, minutesRead — standalone |
| `GlowCategory` | `glow_categories` | emoji, title, subtitle, background — standalone |
| `GlowShort` | `glow_shorts` | imageUrl, duration(String), title, views(String) — standalone |
| `AdminLog` | `admin_logs` | adminId→User (cascade), action, metadata(Json?) |

## Relationships

All one-to-many/many-to-one, all `onDelete: Cascade`, no many-to-many or one-to-one:

```
Workout ──< WorkoutDay ──< Exercise
                       └─< Progress >── User ──< AdminLog
DietPlan ──< DietPlanDay
WorkoutLibraryItem ──< WorkoutLibraryExercise
WorkoutLibraryCategory ⇢ WorkoutLibraryItem   (soft/string-matched, NOT a real FK)
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
11. `20260714020000_add_user_preferences` — water_goal_liters, push_enabled (newest)

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
