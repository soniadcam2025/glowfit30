-- Image derivative metadata.
--
-- Written by hand rather than generated: `prisma migrate diff` against this
-- database also emits six unrelated `ALTER COLUMN "id" DROP DEFAULT` statements
-- from long-standing drift, and shipping those would break inserts on tables
-- this change has nothing to do with.
--
-- Purely additive. No existing table is touched, so media uploaded before this
-- migration keeps working as a plain url with no row here.

CREATE TABLE "media_assets" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "base_key" TEXT NOT NULL,
    "bucket" TEXT NOT NULL,
    "original_url" TEXT NOT NULL,
    "original_mime" TEXT,
    "width" INTEGER,
    "height" INTEGER,
    "bytes" INTEGER,
    "thumb_url" TEXT,
    "thumb_bytes" INTEGER,
    "medium_url" TEXT,
    "medium_bytes" INTEGER,
    "large_url" TEXT,
    "large_bytes" INTEGER,
    "legacy_url" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "media_assets_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "media_assets_base_key_key" ON "media_assets"("base_key");

-- Unique so re-running the backfill cannot create a second set of derivatives
-- for a url that already has one.
CREATE UNIQUE INDEX "media_assets_legacy_url_key" ON "media_assets"("legacy_url");

-- `large_url` is what gets written into the content tables, so it is the url a
-- lookup arrives with.
CREATE INDEX "media_assets_large_url_idx" ON "media_assets"("large_url");
