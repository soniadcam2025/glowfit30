-- AlterTable: rich detail-screen content for Glow Reads (beauty_posts)
ALTER TABLE "beauty_posts" ADD COLUMN IF NOT EXISTS "result_badge" TEXT;
ALTER TABLE "beauty_posts" ADD COLUMN IF NOT EXISTS "chips" JSONB NOT NULL DEFAULT '[]';
ALTER TABLE "beauty_posts" ADD COLUMN IF NOT EXISTS "sections" JSONB NOT NULL DEFAULT '{}';
ALTER TABLE "beauty_posts" ADD COLUMN IF NOT EXISTS "is_premium" BOOLEAN NOT NULL DEFAULT false;

-- AlterTable: same, plus an optional plain-text description, for Glow Shorts (glow_shorts)
ALTER TABLE "glow_shorts" ADD COLUMN IF NOT EXISTS "content" TEXT;
ALTER TABLE "glow_shorts" ADD COLUMN IF NOT EXISTS "result_badge" TEXT;
ALTER TABLE "glow_shorts" ADD COLUMN IF NOT EXISTS "chips" JSONB NOT NULL DEFAULT '[]';
ALTER TABLE "glow_shorts" ADD COLUMN IF NOT EXISTS "sections" JSONB NOT NULL DEFAULT '{}';
ALTER TABLE "glow_shorts" ADD COLUMN IF NOT EXISTS "is_premium" BOOLEAN NOT NULL DEFAULT false;
