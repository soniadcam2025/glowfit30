import { prisma } from '../../database/prisma.js';

export function listPosts(categoryId) {
  return prisma.beautyPost.findMany({
    where: categoryId ? { categoryId } : undefined,
    orderBy: { order: 'asc' },
  });
}

export function getPost(id) {
  return prisma.beautyPost.findUnique({ where: { id } });
}

export function createPost(data) {
  const imageUrl = data.imageUrl === '' ? null : data.imageUrl ?? null;
  const categoryId = data.categoryId === '' ? null : data.categoryId ?? null;
  return prisma.beautyPost.create({
    data: {
      title: data.title,
      content: data.content,
      imageUrl,
      categoryId,
      tag: data.tag,
      tagColor: data.tagColor,
      tagBackground: data.tagBackground,
      minutesRead: data.minutesRead,
      resultBadge: data.resultBadge || null,
      chips: data.chips ?? [],
      sections: data.sections ?? {},
      isPremium: data.isPremium ?? false,
      order: data.order,
    },
  });
}

export function updatePost(id, data) {
  const patch = { ...data };
  if (patch.imageUrl === '') patch.imageUrl = null;
  if (patch.categoryId === '') patch.categoryId = null;
  if (patch.resultBadge === '') patch.resultBadge = null;
  return prisma.beautyPost.update({ where: { id }, data: patch });
}

export function deletePost(id) {
  return prisma.beautyPost.delete({ where: { id } });
}
