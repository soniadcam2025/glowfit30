-- Editorial placement flags for the "Shorts & Quick Tips" hub.
-- Written by hand rather than via `prisma migrate dev`: a full diff of the
-- schema against production also contained five unrelated
-- `ALTER COLUMN "id" DROP DEFAULT` statements from pre-existing drift, which
-- must not ride along with this change.
ALTER TABLE "glow_shorts" ADD COLUMN "is_featured" BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE "glow_shorts" ADD COLUMN "is_trending" BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE "glow_shorts" ADD COLUMN "is_quick_tip" BOOLEAN NOT NULL DEFAULT false;
