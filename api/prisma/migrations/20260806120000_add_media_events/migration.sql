-- Written by hand rather than generated: `prisma migrate diff` also emits six
-- unrelated `ALTER COLUMN "id" DROP DEFAULT` statements from pre-existing drift
-- in this schema, which have nothing to do with this change.

CREATE TABLE "media_events" (
    "id" TEXT NOT NULL,
    "type" TEXT NOT NULL,
    "ms" INTEGER,
    "bytes" INTEGER,
    "cache_hit" BOOLEAN,
    "ok" BOOLEAN NOT NULL DEFAULT true,
    "url" VARCHAR(500),
    "platform" VARCHAR(32),
    "app_version" VARCHAR(32),
    "user_id" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "media_events_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "media_events_type_created_at_idx" ON "media_events"("type", "created_at");
CREATE INDEX "media_events_created_at_idx" ON "media_events"("created_at");
