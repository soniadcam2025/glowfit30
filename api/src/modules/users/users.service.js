import { prisma } from '../../database/prisma.js';

export async function listUsers({ page, limit, q }) {
  const skip = (page - 1) * limit;
  const where = q
    ? {
        OR: [
          { email: { contains: q, mode: 'insensitive' } },
          { name: { contains: q, mode: 'insensitive' } },
        ],
      }
    : {};

  const [items, total] = await Promise.all([
    prisma.user.findMany({
      where,
      skip,
      take: limit,
      orderBy: { createdAt: 'desc' },
      select: {
        id: true,
        name: true,
        email: true,
        role: true,
        isBlocked: true,
        createdAt: true,
      },
    }),
    prisma.user.count({ where }),
  ]);

  return { items, total, page, limit, pages: Math.ceil(total / limit) || 1 };
}

export async function getUserById(id) {
  return prisma.user.findUnique({
    where: { id },
    select: {
      id: true,
      name: true,
      email: true,
      role: true,
      isBlocked: true,
      createdAt: true,
    },
  });
}

export async function setBlocked(id, isBlocked) {
  return prisma.user.update({
    where: { id },
    data: { isBlocked },
    select: {
      id: true,
      name: true,
      email: true,
      role: true,
      isBlocked: true,
      createdAt: true,
    },
  });
}
