import { prisma } from '../../database/prisma.js';

export function listPosts() {
  return prisma.beautyPost.findMany({ orderBy: { createdAt: 'desc' } });
}

export function getPost(id) {
  return prisma.beautyPost.findUnique({ where: { id } });
}

export function createPost(data) {
  const imageUrl = data.imageUrl === '' ? null : data.imageUrl ?? null;
  return prisma.beautyPost.create({
    data: {
      title: data.title,
      content: data.content,
      imageUrl,
    },
  });
}

export function updatePost(id, data) {
  const patch = { ...data };
  if (patch.imageUrl === '') patch.imageUrl = null;
  return prisma.beautyPost.update({ where: { id }, data: patch });
}

export function deletePost(id) {
  return prisma.beautyPost.delete({ where: { id } });
}
