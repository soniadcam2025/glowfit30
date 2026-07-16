-- Migration: Glow screen content — extend beauty_posts, add glow_categories + glow_shorts
-- Safe to run on DBs already updated via db push (uses IF NOT EXISTS)

ALTER TABLE "beauty_posts"
    ADD COLUMN IF NOT EXISTS "tag" TEXT NOT NULL DEFAULT 'SKINCARE',
    ADD COLUMN IF NOT EXISTS "tag_color" TEXT NOT NULL DEFAULT '#C4185A',
    ADD COLUMN IF NOT EXISTS "tag_background" TEXT NOT NULL DEFAULT '#FCE4EC',
    ADD COLUMN IF NOT EXISTS "minutes_read" INTEGER NOT NULL DEFAULT 4,
    ADD COLUMN IF NOT EXISTS "order" INTEGER NOT NULL DEFAULT 0;

CREATE TABLE IF NOT EXISTS "glow_categories" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "emoji" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "subtitle" TEXT NOT NULL,
    "background" TEXT NOT NULL DEFAULT '#FCE4EC',
    "order" INTEGER NOT NULL DEFAULT 0,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "glow_categories_pkey" PRIMARY KEY ("id")
);

CREATE TABLE IF NOT EXISTS "glow_shorts" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "image_url" TEXT,
    "duration" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "views" TEXT NOT NULL DEFAULT '0 views',
    "order" INTEGER NOT NULL DEFAULT 0,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "glow_shorts_pkey" PRIMARY KEY ("id")
);
