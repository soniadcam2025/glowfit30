-- Migration: add user profile fields, workout_days, exercises, progress
-- Safe to run on DBs already updated via db push (uses IF NOT EXISTS / exception handling)

-- Make password nullable (was NOT NULL in init)
ALTER TABLE "users" ALTER COLUMN "password" DROP NOT NULL;

-- User profile fields
ALTER TABLE "users" ADD COLUMN IF NOT EXISTS "firebase_uid" TEXT;
ALTER TABLE "users" ADD COLUMN IF NOT EXISTS "photo_url" TEXT;
ALTER TABLE "users" ADD COLUMN IF NOT EXISTS "fitness_level" TEXT;
ALTER TABLE "users" ADD COLUMN IF NOT EXISTS "goal" TEXT;
ALTER TABLE "users" ADD COLUMN IF NOT EXISTS "diet_style" TEXT;
ALTER TABLE "users" ADD COLUMN IF NOT EXISTS "target_weight" DOUBLE PRECISION;
ALTER TABLE "users" ADD COLUMN IF NOT EXISTS "focus_areas" TEXT[] NOT NULL DEFAULT '{}';
ALTER TABLE "users" ADD COLUMN IF NOT EXISTS "dob" TIMESTAMP(3);
ALTER TABLE "users" ADD COLUMN IF NOT EXISTS "height" DOUBLE PRECISION;
ALTER TABLE "users" ADD COLUMN IF NOT EXISTS "weight" DOUBLE PRECISION;

CREATE UNIQUE INDEX IF NOT EXISTS "users_firebase_uid_key" ON "users"("firebase_uid");

-- Workouts: new optional fields
ALTER TABLE "workouts" ADD COLUMN IF NOT EXISTS "description" TEXT;
ALTER TABLE "workouts" ADD COLUMN IF NOT EXISTS "image_url" TEXT;
ALTER TABLE "workouts" ADD COLUMN IF NOT EXISTS "goal" TEXT;

-- workout_days table
CREATE TABLE IF NOT EXISTS "workout_days" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "workout_id" UUID NOT NULL,
    "day_number" INTEGER NOT NULL,
    "title" TEXT NOT NULL,
    "focus" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "workout_days_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX IF NOT EXISTS "workout_days_workout_id_day_number_key" ON "workout_days"("workout_id", "day_number");
CREATE INDEX IF NOT EXISTS "workout_days_workout_id_idx" ON "workout_days"("workout_id");

DO $$ BEGIN
  ALTER TABLE "workout_days" ADD CONSTRAINT "workout_days_workout_id_fkey"
    FOREIGN KEY ("workout_id") REFERENCES "workouts"("id") ON DELETE CASCADE ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- exercises table
CREATE TABLE IF NOT EXISTS "exercises" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "workout_day_id" UUID NOT NULL,
    "name" TEXT NOT NULL,
    "sets" INTEGER,
    "reps" INTEGER,
    "duration" INTEGER,
    "rest" INTEGER,
    "image_url" TEXT,
    "gif_url" TEXT,
    "order" INTEGER NOT NULL DEFAULT 0,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "exercises_pkey" PRIMARY KEY ("id")
);

CREATE INDEX IF NOT EXISTS "exercises_workout_day_id_idx" ON "exercises"("workout_day_id");

DO $$ BEGIN
  ALTER TABLE "exercises" ADD CONSTRAINT "exercises_workout_day_id_fkey"
    FOREIGN KEY ("workout_day_id") REFERENCES "workout_days"("id") ON DELETE CASCADE ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- progress table
CREATE TABLE IF NOT EXISTS "progress" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "user_id" UUID NOT NULL,
    "workout_day_id" UUID NOT NULL,
    "completed_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "calories_burned" INTEGER,
    "duration_min" INTEGER,
    CONSTRAINT "progress_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX IF NOT EXISTS "progress_user_id_workout_day_id_key" ON "progress"("user_id", "workout_day_id");
CREATE INDEX IF NOT EXISTS "progress_user_id_idx" ON "progress"("user_id");

DO $$ BEGIN
  ALTER TABLE "progress" ADD CONSTRAINT "progress_user_id_fkey"
    FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  ALTER TABLE "progress" ADD CONSTRAINT "progress_workout_day_id_fkey"
    FOREIGN KEY ("workout_day_id") REFERENCES "workout_days"("id") ON DELETE CASCADE ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
