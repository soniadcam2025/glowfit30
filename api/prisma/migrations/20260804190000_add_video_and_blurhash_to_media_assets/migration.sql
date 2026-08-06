-- Video pipeline fields and blurhash placeholders.
--
-- Hand-written for the same reason as the previous migration: a generated diff
-- against this database also carries six unrelated `ALTER COLUMN "id" DROP
-- DEFAULT` statements from pre-existing drift.

ALTER TABLE "media_assets" ADD COLUMN "kind" TEXT NOT NULL DEFAULT 'image';
ALTER TABLE "media_assets" ADD COLUMN "mime" TEXT;
ALTER TABLE "media_assets" ADD COLUMN "blurhash" TEXT;
ALTER TABLE "media_assets" ADD COLUMN "video_url" TEXT;
ALTER TABLE "media_assets" ADD COLUMN "poster_url" TEXT;
ALTER TABLE "media_assets" ADD COLUMN "duration_seconds" DOUBLE PRECISION;

-- Video keeps its source only when KEEP_ORIGINAL_VIDEO is on: a second copy of
-- every clip is by far the largest thing in the bucket, and unlike an image the
-- derivative is not a lossy shrink of something irreplaceable.
ALTER TABLE "media_assets" ALTER COLUMN "original_url" DROP NOT NULL;

CREATE INDEX "media_assets_video_url_idx" ON "media_assets"("video_url");
