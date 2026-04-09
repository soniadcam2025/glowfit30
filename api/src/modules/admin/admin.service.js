import { prisma } from '../../database/prisma.js';
import { cacheGet, cacheSet } from '../../database/redis.js';

const STATS_TTL = 60;
const STATS_KEY = 'admin:stats';

export async function getStatsCached() {
  const hit = await cacheGet(STATS_KEY);
  if (hit) return hit;

  const [totalUsers, activeUsers] = await Promise.all([
    prisma.user.count(),
    prisma.user.count({ where: { isBlocked: false } }),
  ]);

  const payload = {
    totalUsers,
    activeUsers,
    blockedUsers: totalUsers - activeUsers,
    generatedAt: new Date().toISOString(),
  };

  await cacheSet(STATS_KEY, payload, STATS_TTL);
  return payload;
}

export async function getAnalytics() {
  const [usersByRole, workouts, dietPlans, beautyPosts, recentLogs] = await Promise.all([
    prisma.user.groupBy({
      by: ['role'],
      _count: { _all: true },
    }),
    prisma.workout.count(),
    prisma.dietPlan.count(),
    prisma.beautyPost.count(),
    prisma.adminLog.findMany({
      take: 20,
      orderBy: { createdAt: 'desc' },
      include: {
        admin: { select: { id: true, name: true, email: true, role: true } },
      },
    }),
  ]);

  return {
    usersByRole: usersByRole.map((r) => ({ role: r.role, count: r._count._all })),
    counts: {
      workouts,
      dietPlans,
      beautyPosts,
    },
    recentAdminLogs: recentLogs,
  };
}
