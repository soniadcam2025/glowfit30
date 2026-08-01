import { prisma } from '../../database/prisma.js';
import { deleteFiles } from '../../config/storage.js';

// ── Categories ("Explore by Goals") ────────────────────────────────────────────

export function listCategories() {
  return prisma.glowCategory.findMany({ orderBy: { order: 'asc' } });
}

export async function getCategoryDetail(id) {
  const category = await prisma.glowCategory.findUnique({ where: { id } });
  if (!category) return null;
  const [postsCount, shortsCount] = await Promise.all([
    prisma.beautyPost.count({ where: { categoryId: id } }),
    prisma.glowShort.count({ where: { categoryId: id } }),
  ]);
  return { ...category, postsCount, shortsCount };
}

function normalizeHeroImage(data) {
  if (data.heroImageUrl === '') return { ...data, heroImageUrl: null };
  return data;
}

export function createCategory(data) {
  return prisma.glowCategory.create({ data: normalizeHeroImage(data) });
}

export function updateCategory(id, data) {
  return prisma.glowCategory.update({ where: { id }, data: normalizeHeroImage(data) });
}

export function deleteCategory(id) {
  return prisma.glowCategory.delete({ where: { id } });
}

// ── Shorts ("Shorts & Quick Tips") ──────────────────────────────────────────────

export function listShorts(categoryId) {
  return prisma.glowShort.findMany({
    where: categoryId ? { categoryId } : undefined,
    orderBy: { order: 'asc' },
    // Included so the Shorts story screen can label the category pill.
    include: { category: { select: { title: true } } },
  });
}

function normalizeCategoryId(data) {
  const normalized = { ...data };
  if (normalized.categoryId === '') normalized.categoryId = null;
  if (normalized.resultBadge === '') normalized.resultBadge = null;
  if (normalized.content === '') normalized.content = null;
  return normalized;
}

export function createShort(data) {
  return prisma.glowShort.create({ data: normalizeCategoryId(data) });
}

export function updateShort(id, data) {
  return prisma.glowShort.update({ where: { id }, data: normalizeCategoryId(data) });
}

export async function deleteShort(id) {
  const short = await prisma.glowShort.findUnique({ where: { id } });
  const row = await prisma.glowShort.delete({ where: { id } });
  if (short?.imageUrl) await deleteFiles([short.imageUrl]);
  return row;
}
