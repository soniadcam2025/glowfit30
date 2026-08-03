-- Target for the workout day-streak on the home screen.
-- Hand-written: a generated diff also carries six unrelated
-- ALTER COLUMN "id" DROP DEFAULT statements from pre-existing drift (see TODO.md).
ALTER TABLE "users" ADD COLUMN "streak_goal_days" INTEGER NOT NULL DEFAULT 30;
