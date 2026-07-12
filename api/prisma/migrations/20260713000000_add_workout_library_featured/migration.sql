-- Migration: featured flag separates the hero-card workout from category workouts
-- Safe to run on DBs already updated via db push (uses IF NOT EXISTS)

ALTER TABLE "workout_library_items"
    ADD COLUMN IF NOT EXISTS "is_featured" BOOLEAN NOT NULL DEFAULT false;
