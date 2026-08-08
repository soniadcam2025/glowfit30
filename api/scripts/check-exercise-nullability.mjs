// One-off verification for the duration/rest NOT NULL migration.
//
// Reports whether any row would violate the constraint, what the columns look
// like right now, and — with --dry-run — actually applies the ALTERs inside a
// transaction that is rolled back. That last part is the only honest way to
// test this here: local development points at the production database, so
// there is no separate database to trial the migration against.
import { prisma } from '../src/database/prisma.js';

const dryRun = process.argv.includes('--dry-run');

// Raw SQL rather than `where: { duration: null }`: once the schema marks these
// non-nullable the typed filter is a validation error, and this script has to
// keep working on both sides of the migration.
const [counts] = await prisma.$queryRawUnsafe(
  `select count(*)::int as total,
          count(*) filter (where duration is null)::int as "nullDuration",
          count(*) filter (where rest is null)::int as "nullRest"
   from "exercises"`,
);
console.log('DATA:', JSON.stringify(counts));

const columns = await prisma.$queryRawUnsafe(
  `select column_name, is_nullable from information_schema.columns
   where table_name = 'exercises' and column_name in ('duration','rest')
   order by column_name`,
);
console.log('COLUMNS:', JSON.stringify(columns));

if (dryRun) {
  try {
    await prisma.$transaction(async (tx) => {
      await tx.$executeRawUnsafe('ALTER TABLE "exercises" ALTER COLUMN "duration" SET NOT NULL');
      await tx.$executeRawUnsafe('ALTER TABLE "exercises" ALTER COLUMN "rest" SET NOT NULL');

      const after = await tx.$queryRawUnsafe(
        `select column_name, is_nullable from information_schema.columns
         where table_name = 'exercises' and column_name in ('duration','rest')
         order by column_name`,
      );
      console.log('DRY_RUN_APPLIED:', JSON.stringify(after));

      // Prove the constraint actually bites before giving the whole thing back.
      try {
        await tx.$executeRawUnsafe(
          `update "exercises" set "duration" = null where id = (select id from "exercises" limit 1)`,
        );
        console.log('DRY_RUN_REJECTS_NULL: false  <-- constraint did NOT bite');
      } catch (error) {
        console.log('DRY_RUN_REJECTS_NULL: true  (' + error.message.split('\n').pop().trim() + ')');
      }

      throw new Error('__rollback__');
    });
  } catch (error) {
    if (error.message.includes('__rollback__')) {
      console.log('DRY_RUN_ROLLED_BACK: true');
    } else {
      console.log('DRY_RUN_FAILED:', error.message.split('\n')[0]);
      process.exit(1);
    }
  }

  const restored = await prisma.$queryRawUnsafe(
    `select column_name, is_nullable from information_schema.columns
     where table_name = 'exercises' and column_name in ('duration','rest')
     order by column_name`,
  );
  console.log('AFTER_ROLLBACK:', JSON.stringify(restored));
}

process.exit(0);
