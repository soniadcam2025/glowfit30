-- Migration: per-day diet meals + optional goal tag on diet plans
-- Safe to run on DBs already updated via db push (uses IF NOT EXISTS)

-- Optional fitness-goal tag on plans (type now strictly means diet style)
ALTER TABLE "diet_plans" ADD COLUMN IF NOT EXISTS "goal" TEXT;

-- diet_plan_days table
CREATE TABLE IF NOT EXISTS "diet_plan_days" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "diet_plan_id" UUID NOT NULL,
    "day_number" INTEGER NOT NULL,
    "meals" JSONB NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "diet_plan_days_pkey" PRIMARY KEY ("id")
);

CREATE INDEX IF NOT EXISTS "diet_plan_days_diet_plan_id_idx"
    ON "diet_plan_days"("diet_plan_id");

CREATE UNIQUE INDEX IF NOT EXISTS "diet_plan_days_diet_plan_id_day_number_key"
    ON "diet_plan_days"("diet_plan_id", "day_number");

DO $$
BEGIN
    ALTER TABLE "diet_plan_days"
        ADD CONSTRAINT "diet_plan_days_diet_plan_id_fkey"
        FOREIGN KEY ("diet_plan_id") REFERENCES "diet_plans"("id")
        ON DELETE CASCADE ON UPDATE CASCADE;
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;
