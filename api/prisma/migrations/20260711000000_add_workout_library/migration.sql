-- Migration: workout library items + their exercises
-- Safe to run on DBs already updated via db push (uses IF NOT EXISTS)

CREATE TABLE IF NOT EXISTS "workout_library_items" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "category" TEXT NOT NULL,
    "title_line1" TEXT NOT NULL,
    "title_script" TEXT NOT NULL,
    "description" TEXT NOT NULL,
    "hero_image_url" TEXT,
    "duration_minutes" INTEGER NOT NULL,
    "kcal_label" TEXT NOT NULL,
    "focus_label" TEXT NOT NULL,
    "tags" JSONB NOT NULL,
    "order" INTEGER NOT NULL DEFAULT 0,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "workout_library_items_pkey" PRIMARY KEY ("id")
);

CREATE TABLE IF NOT EXISTS "workout_library_exercises" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "workout_library_item_id" UUID NOT NULL,
    "name" TEXT NOT NULL,
    "duration_seconds" INTEGER NOT NULL,
    "image_url" TEXT,
    "video_url" TEXT,
    "order" INTEGER NOT NULL DEFAULT 0,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "workout_library_exercises_pkey" PRIMARY KEY ("id")
);

CREATE INDEX IF NOT EXISTS "workout_library_exercises_workout_library_item_id_idx"
    ON "workout_library_exercises"("workout_library_item_id");

DO $$
BEGIN
    ALTER TABLE "workout_library_exercises"
        ADD CONSTRAINT "workout_library_exercises_workout_library_item_id_fkey"
        FOREIGN KEY ("workout_library_item_id") REFERENCES "workout_library_items"("id")
        ON DELETE CASCADE ON UPDATE CASCADE;
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;
