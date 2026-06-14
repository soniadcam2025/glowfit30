import { prisma } from '../../database/prisma.js';

export async function logProgress(userId, { workoutDayId, caloriesBurned, durationMin }) {
  return prisma.progress.upsert({
    where: { userId_workoutDayId: { userId, workoutDayId } },
    create: {
      userId,
      workoutDayId,
      caloriesBurned: caloriesBurned ?? null,
      durationMin:    durationMin    ?? null,
    },
    update: {
      completedAt:    new Date(),
      caloriesBurned: caloriesBurned ?? undefined,
      durationMin:    durationMin    ?? undefined,
    },
    include: {
      workoutDay: { select: { id: true, title: true, dayNumber: true, workoutId: true } },
    },
  });
}

export async function getUserProgress(userId) {
  const rows = await prisma.progress.findMany({
    where: { userId },
    orderBy: { completedAt: 'desc' },
    include: {
      workoutDay: {
        select: {
          id: true,
          title: true,
          dayNumber: true,
          workout: { select: { id: true, title: true, level: true } },
        },
      },
    },
  });

  const totalCalories = rows.reduce((sum, r) => sum + (r.caloriesBurned ?? 0), 0);
  const totalMinutes  = rows.reduce((sum, r) => sum + (r.durationMin   ?? 0), 0);
  const streak        = calcStreak(rows.map((r) => r.completedAt));

  return { completions: rows, stats: { totalSessions: rows.length, totalCalories, totalMinutes, streak } };
}

function calcStreak(dates) {
  if (!dates.length) return 0;
  const days = [...new Set(dates.map((d) => d.toISOString().slice(0, 10)))].sort().reverse();
  let streak = 0;
  let cursor = new Date();
  cursor.setHours(0, 0, 0, 0);
  for (const day of days) {
    const d = new Date(day);
    const diff = Math.round((cursor - d) / 86400000);
    if (diff > 1) break;
    streak++;
    cursor = d;
  }
  return streak;
}
