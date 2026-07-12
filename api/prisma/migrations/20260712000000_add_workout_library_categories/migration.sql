-- Migration: workout library categories + per-item difficulty
-- Safe to run on DBs already updated via db push (uses IF NOT EXISTS)

CREATE TABLE IF NOT EXISTS "workout_library_categories" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "name" TEXT NOT NULL,
    "heading_line1" TEXT NOT NULL,
    "heading_line2" TEXT NOT NULL,
    "description" TEXT NOT NULL,
    "hero_image_url" TEXT,
    "tags" JSONB NOT NULL,
    "order" INTEGER NOT NULL DEFAULT 0,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "workout_library_categories_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX IF NOT EXISTS "workout_library_categories_name_key"
    ON "workout_library_categories"("name");

ALTER TABLE "workout_library_items"
    ADD COLUMN IF NOT EXISTS "difficulty" TEXT NOT NULL DEFAULT 'Beginner';
