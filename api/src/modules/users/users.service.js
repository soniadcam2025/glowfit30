import { prisma } from '../../database/prisma.js';

export async function listUsers({ page, limit, q, status, goal, fitnessLevel, sortBy = 'createdAt', sortDir = 'desc' }) {
  const skip = (page - 1) * limit;

  const where = {
    role: 'user',
    ...(status === 'active' && { isBlocked: false }),
    ...(status === 'blocked' && { isBlocked: true }),
    ...(goal && { goal }),
    ...(fitnessLevel && { fitnessLevel }),
    ...(q && {
      OR: [
        { email: { contains: q, mode: 'insensitive' } },
        { name: { contains: q, mode: 'insensitive' } },
      ],
    }),
  };

  const [items, total] = await Promise.all([
    prisma.user.findMany({
      where,
      skip,
      take: limit,
      orderBy: { [sortBy]: sortDir },
      select: {
        id: true,
        name: true,
        email: true,
        role: true,
        isBlocked: true,
        createdAt: true,
        photoUrl: true,
        fitnessLevel: true,
        goal: true,
        firebaseUid: true,
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
      photoUrl: true,
      fitnessLevel: true,
      goal: true,
      dietStyle: true,
      targetWeight: true,
      focusAreas: true,
      dob: true,
      height: true,
      weight: true,
    },
  });
}

export async function getUserProgress(id) {
  const completions = await prisma.progress.findMany({
    where: { userId: id },
    orderBy: { completedAt: 'desc' },
    include: {
      workoutDay: { select: { title: true, dayNumber: true, workoutId: true } },
    },
  });

  const totalSessions = completions.length;
  const totalCalories = completions.reduce((s, c) => s + (c.caloriesBurned ?? 0), 0);
  const totalMinutes  = completions.reduce((s, c) => s + (c.durationMin ?? 0), 0);

  return { completions, stats: { totalSessions, totalCalories, totalMinutes } };
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
