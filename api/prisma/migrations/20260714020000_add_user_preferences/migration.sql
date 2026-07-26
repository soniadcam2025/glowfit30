-- Migration: user preference fields — water goal + push notification opt-out
-- Safe to run on DBs already updated via db push (uses IF NOT EXISTS)

ALTER TABLE "users"
    ADD COLUMN IF NOT EXISTS "water_goal_liters" DOUBLE PRECISION NOT NULL DEFAULT 3.0,
    ADD COLUMN IF NOT EXISTS "push_enabled" BOOLEAN NOT NULL DEFAULT true;
