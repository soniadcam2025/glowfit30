import { prisma } from '../../database/prisma.js';
import { deleteFiles } from '../../config/storage.js';

function exerciseFileUrls(exercise) {
  return [exercise.imageUrl, exercise.videoUrl];
}

// ── Categories ────────────────────────────────────────────────────────────────

export function listCategories() {
  return prisma.workoutLibraryCategory.findMany({ orderBy: { order: 'asc' } });
}

export function getCategory(id) {
  return prisma.workoutLibraryCategory.findUnique({ where: { id } });
}

export function createCategory(data) {
  return prisma.workoutLibraryCategory.create({ data });
}

export function updateCategory(id, data) {
  return prisma.workoutLibraryCategory.update({ where: { id }, data });
}

export async function deleteCategory(id) {
  const category = await prisma.workoutLibraryCategory.findUnique({ where: { id } });

  const row = await prisma.workoutLibraryCategory.delete({ where: { id } });

  if (category) {
    await deleteFiles([category.heroImageUrl]);
  }

  return row;
}

// ── Items ─────────────────────────────────────────────────────────────────────

export function listItems(category) {
  return prisma.workoutLibraryItem.findMany({
    where: category ? { category } : undefined,
    orderBy: { order: 'asc' },
    include: { _count: { select: { exercises: true } } },
  });
}

export function getItem(id) {
  return prisma.workoutLibraryItem.findUnique({
    where: { id },
    include: { exercises: { orderBy: { order: 'asc' } } },
  });
}

export function createItem(data) {
  return prisma.workoutLibraryItem.create({ data });
}

export function updateItem(id, data) {
  return prisma.workoutLibraryItem.update({ where: { id }, data });
}

export async function deleteItem(id) {
  const item = await prisma.workoutLibraryItem.findUnique({
    where: { id },
    include: { exercises: true },
  });

  const row = await prisma.workoutLibraryItem.delete({ where: { id } });

  if (item) {
    const urls = [item.heroImageUrl, ...item.exercises.flatMap(exerciseFileUrls)];
    await deleteFiles(urls);
  }

  return row;
}

// ── Exercises ─────────────────────────────────────────────────────────────────

export function getExercises(workoutLibraryItemId) {
  return prisma.workoutLibraryExercise.findMany({
    where: { workoutLibraryItemId },
    orderBy: { order: 'asc' },
  });
}

export function createExercise(workoutLibraryItemId, data) {
  return prisma.workoutLibraryExercise.create({
    data: { ...data, workoutLibraryItemId },
  });
}

export function updateExercise(id, data) {
  return prisma.workoutLibraryExercise.update({ where: { id }, data });
}

export async function deleteExercise(id) {
  const exercise = await prisma.workoutLibraryExercise.findUnique({ where: { id } });

  const row = await prisma.workoutLibraryExercise.delete({ where: { id } });

  if (exercise) {
    await deleteFiles(exerciseFileUrls(exercise));
  }

  return row;
}
