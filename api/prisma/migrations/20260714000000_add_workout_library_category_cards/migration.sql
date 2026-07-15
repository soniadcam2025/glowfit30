-- Migration: card-grid fields for workout library categories
-- Safe to run on DBs already updated via db push (uses IF NOT EXISTS)

ALTER TABLE "workout_library_categories"
    ADD COLUMN IF NOT EXISTS "section" TEXT NOT NULL DEFAULT 'Body Goals',
    ADD COLUMN IF NOT EXISTS "card_tagline" TEXT NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS "card_image_url" TEXT,
    ADD COLUMN IF NOT EXISTS "card_background" TEXT NOT NULL DEFAULT '#EAE3FA',
    ADD COLUMN IF NOT EXISTS "card_title_color" TEXT NOT NULL DEFAULT '#3D2E7C';
