-- Add duration_minutes and kcal to workout_days (admin-entered, shown in the day list/card)
ALTER TABLE "workout_days" ADD COLUMN IF NOT EXISTS "duration_minutes" INTEGER;
ALTER TABLE "workout_days" ADD COLUMN IF NOT EXISTS "kcal" INTEGER;
