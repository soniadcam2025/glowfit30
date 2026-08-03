-- Water tracking: per-drink intake rows plus hydration reminder settings.
--
-- Hand-written rather than generated: a full `prisma migrate diff` against
-- production also contains six unrelated `ALTER COLUMN "id" DROP DEFAULT`
-- statements from pre-existing drift (see TODO.md), which must not ride along.

ALTER TABLE "users" ADD COLUMN "water_reminder_enabled" BOOLEAN NOT NULL DEFAULT true;
ALTER TABLE "users" ADD COLUMN "water_reminder_minutes" INTEGER NOT NULL DEFAULT 60;
ALTER TABLE "users" ADD COLUMN "water_quiet_from_hour" INTEGER NOT NULL DEFAULT 22;
ALTER TABLE "users" ADD COLUMN "water_quiet_to_hour" INTEGER NOT NULL DEFAULT 7;
ALTER TABLE "users" ADD COLUMN "water_sound_enabled" BOOLEAN NOT NULL DEFAULT true;
ALTER TABLE "users" ADD COLUMN "water_vibration_enabled" BOOLEAN NOT NULL DEFAULT true;
ALTER TABLE "users" ADD COLUMN "water_smart_mode" BOOLEAN NOT NULL DEFAULT true;

CREATE TABLE "water_intake" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "amount_ml" INTEGER NOT NULL,
    "logged_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "water_intake_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "water_intake_user_id_logged_at_idx" ON "water_intake"("user_id", "logged_at");

ALTER TABLE "water_intake" ADD CONSTRAINT "water_intake_user_id_fkey"
    FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
