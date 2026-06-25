-- Add image_url to workout_days (day-level cover image, shown in the app's day list)
ALTER TABLE "workout_days" ADD COLUMN IF NOT EXISTS "image_url" TEXT;
