-- AlterTable: link beauty_posts and glow_shorts to glow_categories
ALTER TABLE "beauty_posts" ADD COLUMN IF NOT EXISTS "category_id" UUID;
ALTER TABLE "glow_shorts" ADD COLUMN IF NOT EXISTS "category_id" UUID;

-- AlterTable: category detail-screen fields
ALTER TABLE "glow_categories" ADD COLUMN IF NOT EXISTS "hero_image_url" TEXT;
ALTER TABLE "glow_categories" ADD COLUMN IF NOT EXISTS "topics" JSONB NOT NULL DEFAULT '[]';

-- Indexes
CREATE INDEX IF NOT EXISTS "beauty_posts_category_id_idx" ON "beauty_posts"("category_id");
CREATE INDEX IF NOT EXISTS "glow_shorts_category_id_idx" ON "glow_shorts"("category_id");

-- Foreign keys (SetNull: deleting a category must not destroy its content)
DO $$ BEGIN
  ALTER TABLE "beauty_posts" ADD CONSTRAINT "beauty_posts_category_id_fkey"
    FOREIGN KEY ("category_id") REFERENCES "glow_categories"("id") ON DELETE SET NULL ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  ALTER TABLE "glow_shorts" ADD CONSTRAINT "glow_shorts_category_id_fkey"
    FOREIGN KEY ("category_id") REFERENCES "glow_categories"("id") ON DELETE SET NULL ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
