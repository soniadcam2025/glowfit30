import { prisma } from '../../database/prisma.js';
import { deleteFiles } from '../../config/storage.js';

// ── Categories ("Explore by Goals") ────────────────────────────────────────────

export function listCategories() {
  return prisma.glowCategory.findMany({ orderBy: { order: 'asc' } });
}

export function createCategory(data) {
  return prisma.glowCategory.create({ data });
}

export function updateCategory(id, data) {
  return prisma.glowCategory.update({ where: { id }, data });
}

export function deleteCategory(id) {
  return prisma.glowCategory.delete({ where: { id } });
}

// ── Shorts ("Shorts & Quick Tips") ──────────────────────────────────────────────

export function listShorts() {
  return prisma.glowShort.findMany({ orderBy: { order: 'asc' } });
}

export function createShort(data) {
  return prisma.glowShort.create({ data });
}

export function updateShort(id, data) {
  return prisma.glowShort.update({ where: { id }, data });
}

export async function deleteShort(id) {
  const short = await prisma.glowShort.findUnique({ where: { id } });
  const row = await prisma.glowShort.delete({ where: { id } });
  if (short?.imageUrl) await deleteFiles([short.imageUrl]);
  return row;
}
