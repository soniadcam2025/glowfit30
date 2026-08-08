-- Exercises are time-driven: `duration` is what the player counts down and
-- `rest` is the gap before the next one. Both have been required by the API and
-- the admin form since 2026-08-07, but the columns stayed nullable so that
-- exercises authored before that change were neither rejected nor backfilled
-- with a number nobody chose.
--
-- Verified before writing this: every row already carries both values, and
-- `api/scripts/seed.mjs` no longer produces rows without them. The constraint
-- now expresses an invariant the data already satisfies.
--
-- Hand-written rather than generated. `prisma migrate dev` would sweep five
-- unrelated `ALTER COLUMN "id" DROP DEFAULT` statements — pre-existing drift
-- between the schema and production — into this migration and apply them as a
-- side effect. Only the two statements below belong here.
--
-- Reversible: `ALTER TABLE "exercises" ALTER COLUMN "duration" DROP NOT NULL;`
-- and the same for "rest".

ALTER TABLE "exercises" ALTER COLUMN "duration" SET NOT NULL;
ALTER TABLE "exercises" ALTER COLUMN "rest" SET NOT NULL;
