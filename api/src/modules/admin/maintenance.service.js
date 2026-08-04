import ExcelJS from 'exceljs';
import { prisma } from '../../database/prisma.js';
import { deleteFiles } from '../../config/storage.js';
import { env } from '../../config/env.js';

/**
 * Every table, in dependency order (parents before children) so a restore built
 * from this workbook can be inserted top to bottom without violating foreign
 * keys.
 */
const TABLES = [
  ['users', () => prisma.user.findMany()],
  ['workouts', () => prisma.workout.findMany()],
  ['workout_days', () => prisma.workoutDay.findMany()],
  ['exercises', () => prisma.exercise.findMany()],
  ['progress', () => prisma.progress.findMany()],
  ['water_intake', () => prisma.waterIntake.findMany()],
  ['diet_plans', () => prisma.dietPlan.findMany()],
  ['diet_plan_days', () => prisma.dietPlanDay.findMany()],
  ['workout_library_categories', () => prisma.workoutLibraryCategory.findMany()],
  ['workout_library_items', () => prisma.workoutLibraryItem.findMany()],
  ['workout_library_exercises', () => prisma.workoutLibraryExercise.findMany()],
  ['glow_categories', () => prisma.glowCategory.findMany()],
  ['beauty_posts', () => prisma.beautyPost.findMany()],
  ['glow_shorts', () => prisma.glowShort.findMany()],
  ['legal_documents', () => prisma.legalDocument.findMany()],
  ['admin_logs', () => prisma.adminLog.findMany()],
];

/** Excel rejects these in cell values, and sheet names have their own rules. */
function toCell(value) {
  if (value === null || value === undefined) return '';
  if (value instanceof Date) return value.toISOString();
  if (typeof value === 'object') return JSON.stringify(value);
  return value;
}

/**
 * Builds an .xlsx workbook with one sheet per table.
 *
 * Passwords are redacted: a backup file is far more likely to be emailed or left
 * in a downloads folder than the database is to be breached, and bcrypt hashes
 * are still credentials.
 */
/** Table names the admin can pick from, in the same dependency order. */
export const BACKUP_TABLES = TABLES.map(([name]) => name);

export async function buildBackupWorkbook(selected) {
  // No selection means everything — a bare "download backup" should not
  // silently produce an empty file.
  const chosen =
    Array.isArray(selected) && selected.length > 0
      ? TABLES.filter(([name]) => selected.includes(name))
      : TABLES;

  const wb = new ExcelJS.Workbook();
  wb.creator = 'GlowFit Admin';
  wb.created = new Date();

  const summary = wb.addWorksheet('_summary');
  summary.addRow(['Table', 'Rows']);
  summary.getRow(1).font = { bold: true };

  for (const [name, fetch] of chosen) {
    const rows = await fetch();
    summary.addRow([name, rows.length]);

    // Excel caps sheet names at 31 characters.
    const sheet = wb.addWorksheet(name.slice(0, 31));
    if (rows.length === 0) {
      sheet.addRow(['(no rows)']);
      continue;
    }

    const columns = Object.keys(rows[0]);
    sheet.addRow(columns);
    sheet.getRow(1).font = { bold: true };
    sheet.views = [{ state: 'frozen', ySplit: 1 }];

    for (const row of rows) {
      sheet.addRow(
        columns.map((c) => (c === 'password' ? '[redacted]' : toCell(row[c]))),
      );
    }
  }

  summary.addRow([]);
  summary.addRow(['Generated', new Date().toISOString()]);
  summary.addRow(['Note', 'The users.password column is redacted.']);

  return wb;
}

/**
 * Destructive resets.
 *
 * Each returns the counts it removed so the UI can report what actually
 * happened rather than a bare "done". Deletes run inside a transaction so a
 * partial failure cannot leave a half-emptied table.
 */
/**
 * Media URLs are collected *before* the rows are deleted — once the rows are
 * gone there is no way to find the objects, and they would sit in the bucket
 * forever paying storage for content nothing references.
 *
 * Object deletion happens after the transaction commits. Storage is not
 * transactional, so doing it inside would risk destroying files for a delete
 * that then rolled back.
 */
async function purgeMedia(urls) {
  const unique = [...new Set(urls.filter(Boolean))];
  if (unique.length === 0) return 0;
  await deleteFiles(unique);
  return unique.length;
}

export async function resetWorkouts({ deleteMedia = true } = {}) {
  const [workoutImages, exerciseMedia, dayImages] = await Promise.all([
    prisma.workout.findMany({ select: { imageUrl: true } }),
    prisma.exercise.findMany({ select: { imageUrl: true, videoUrl: true } }),
    prisma.workoutDay.findMany({ select: { imageUrl: true } }),
  ]);

  const result = await prisma.$transaction(async (tx) => {
    // Progress cascades from WorkoutDay, so it is counted before the delete to
    // report the real blast radius — users lose their completion history too.
    const progress = await tx.progress.count();
    const exercises = await tx.exercise.count();
    const days = await tx.workoutDay.count();
    const { count: workouts } = await tx.workout.deleteMany();
    return { workouts, days, exercises, progress };
  });

  result.mediaDeleted = deleteMedia
    ? await purgeMedia([
        ...workoutImages.map((w) => w.imageUrl),
        ...dayImages.map((d) => d.imageUrl),
        ...exerciseMedia.flatMap((e) => [e.imageUrl, e.videoUrl]),
      ])
    : 0;

  return result;
}

/** Pulls every imageUrl/videoUrl out of an arbitrarily shaped JSON column. */
function mediaFromJson(value) {
  const found = [];
  const walk = (node) => {
    if (Array.isArray(node)) return node.forEach(walk);
    if (node && typeof node === 'object') {
      for (const [k, v] of Object.entries(node)) {
        if ((k === 'imageUrl' || k === 'videoUrl') && typeof v === 'string') found.push(v);
        else walk(v);
      }
    }
  };
  walk(value);
  return found;
}

export async function resetDietPlans({ deleteMedia = true } = {}) {
  const [planImages, dayMeals] = await Promise.all([
    prisma.dietPlan.findMany({ select: { imageUrl: true } }),
    // DietPlanDay has no imageUrl column — meal images live inside `meals`.
    prisma.dietPlanDay.findMany({ select: { meals: true } }),
  ]);

  const result = await prisma.$transaction(async (tx) => {
    const days = await tx.dietPlanDay.count();
    const { count: plans } = await tx.dietPlan.deleteMany();
    return { plans, days };
  });

  result.mediaDeleted = deleteMedia
    ? await purgeMedia([
        ...planImages.map((p) => p.imageUrl),
        ...dayMeals.flatMap((d) => mediaFromJson(d.meals)),
      ])
    : 0;

  return result;
}

export async function resetGlowReads({ deleteMedia = true } = {}) {
  const posts = await prisma.beautyPost.findMany({
    select: { imageUrl: true, sections: true },
  });

  const result = await prisma.$transaction(async (tx) => {
    const { count } = await tx.beautyPost.deleteMany();
    return { posts: count };
  });

  // Section cards carry their own images and clips inside the JSON column.
  result.mediaDeleted = deleteMedia
    ? await purgeMedia([
        ...posts.map((p) => p.imageUrl),
        ...posts.flatMap((p) => mediaFromJson(p.sections)),
      ])
    : 0;

  return result;
}

export async function resetWorkoutLibrary({ deleteMedia = true } = {}) {
  const [categories, items, exercises] = await Promise.all([
    prisma.workoutLibraryCategory.findMany({
      select: { heroImageUrl: true, cardImageUrl: true },
    }),
    prisma.workoutLibraryItem.findMany({ select: { heroImageUrl: true } }),
    prisma.workoutLibraryExercise.findMany({
      select: { imageUrl: true, videoUrl: true },
    }),
  ]);

  const result = await prisma.$transaction(async (tx) => {
    const exerciseCount = await tx.workoutLibraryExercise.count();
    // Items are *not* a foreign-key child of categories — `category` is a plain
    // string tag — so deleting categories would leave every item orphaned.
    // Both are deleted explicitly; exercises cascade from items.
    const { count: itemCount } = await tx.workoutLibraryItem.deleteMany();
    const { count: categoryCount } = await tx.workoutLibraryCategory.deleteMany();
    return { categories: categoryCount, items: itemCount, exercises: exerciseCount };
  });

  result.mediaDeleted = deleteMedia
    ? await purgeMedia([
        ...categories.flatMap((c) => [c.heroImageUrl, c.cardImageUrl]),
        ...items.map((i) => i.heroImageUrl),
        ...exercises.flatMap((e) => [e.imageUrl, e.videoUrl]),
      ])
    : 0;

  return result;
}

export async function resetGlowContent({ deleteMedia = true } = {}) {
  const [categories, shorts] = await Promise.all([
    prisma.glowCategory.findMany({ select: { heroImageUrl: true } }),
    prisma.glowShort.findMany({ select: { imageUrl: true, sections: true } }),
  ]);

  const result = await prisma.$transaction(async (tx) => {
    const { count: shortCount } = await tx.glowShort.deleteMany();
    // Reads link to categories with onDelete: SetNull, so deleting categories
    // leaves the articles in place and simply unassigns them — that is why
    // Glow Reads has its own separate reset.
    const { count: categoryCount } = await tx.glowCategory.deleteMany();
    return { shorts: shortCount, categories: categoryCount };
  });

  result.mediaDeleted = deleteMedia
    ? await purgeMedia([
        ...categories.map((c) => c.heroImageUrl),
        ...shorts.map((s) => s.imageUrl),
        ...shorts.flatMap((s) => mediaFromJson(s.sections)),
      ])
    : 0;

  return result;
}

/** Current media-server configuration, with the secret masked. */
export function storageConfig() {
  const mask = (v) => (v ? `${String(v).slice(0, 4)}${'•'.repeat(8)}` : null);
  return {
    provider: 'Vultr Object Storage (S3-compatible)',
    endpoint: env.VULTR_S3_ENDPOINT ?? null,
    region: env.VULTR_S3_REGION ?? null,
    bucketExercises: env.VULTR_S3_BUCKET_EXERCISES ?? null,
    bucketDiet: env.VULTR_S3_BUCKET_DIET ?? null,
    accessKey: mask(env.VULTR_S3_ACCESS_KEY),
    secretKey: env.VULTR_S3_SECRET_KEY ? '••••••••' : null,
    configured: Boolean(
      env.VULTR_S3_ENDPOINT && env.VULTR_S3_ACCESS_KEY && env.VULTR_S3_SECRET_KEY,
    ),
    /** Config comes from environment variables, so it cannot be edited at runtime. */
    source: 'environment',
  };
}

export async function tableCounts() {
  const [
    workouts,
    workoutDays,
    exercises,
    progress,
    dietPlans,
    dietPlanDays,
    beautyPosts,
    libraryCategories,
    libraryItems,
    libraryExercises,
    glowCategories,
    glowShorts,
  ] = await Promise.all([
    prisma.workout.count(),
    prisma.workoutDay.count(),
    prisma.exercise.count(),
    prisma.progress.count(),
    prisma.dietPlan.count(),
    prisma.dietPlanDay.count(),
    prisma.beautyPost.count(),
    prisma.workoutLibraryCategory.count(),
    prisma.workoutLibraryItem.count(),
    prisma.workoutLibraryExercise.count(),
    prisma.glowCategory.count(),
    prisma.glowShort.count(),
  ]);
  return {
    workouts,
    workoutDays,
    exercises,
    progress,
    dietPlans,
    dietPlanDays,
    beautyPosts,
    libraryCategories,
    libraryItems,
    libraryExercises,
    glowCategories,
    glowShorts,
  };
}
