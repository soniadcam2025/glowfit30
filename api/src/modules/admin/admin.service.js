import { prisma } from '../../database/prisma.js';
import { cacheGet, cacheSet } from '../../database/redis.js';

const STATS_TTL = 60;
const STATS_KEY = 'admin:stats';

export async function getStatsCached() {
  const hit = await cacheGet(STATS_KEY);
  if (hit) return hit;

  const today = new Date();
  today.setHours(0, 0, 0, 0);

  const [totalUsers, activeUsers, todayCompletions, totalWorkouts] = await Promise.all([
    prisma.user.count(),
    prisma.user.count({ where: { isBlocked: false } }),
    prisma.progress.count({ where: { completedAt: { gte: today } } }),
    prisma.workout.count(),
  ]);

  const payload = {
    totalUsers,
    activeUsers,
    blockedUsers: totalUsers - activeUsers,
    todayCompletions,
    totalWorkouts,
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

export async function getChartData() {
  const sevenDaysAgo  = new Date(); sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);   sevenDaysAgo.setHours(0, 0, 0, 0);
  const fourteenDaysAgo = new Date(); fourteenDaysAgo.setDate(fourteenDaysAgo.getDate() - 13); fourteenDaysAgo.setHours(0, 0, 0, 0);

  // Raw SQL gives us clean date-bucketed counts in one query each
  const [signupRows, completionRows, activeUsersRows] = await Promise.all([
    prisma.$queryRaw`
      SELECT TO_CHAR(DATE("createdAt"), 'YYYY-MM-DD') AS date, COUNT(*)::int AS count
      FROM "User"
      WHERE "createdAt" >= ${fourteenDaysAgo}
      GROUP BY DATE("createdAt")
      ORDER BY DATE("createdAt") ASC
    `,
    prisma.$queryRaw`
      SELECT TO_CHAR(DATE("completedAt"), 'YYYY-MM-DD') AS date, COUNT(*)::int AS count
      FROM "Progress"
      WHERE "completedAt" >= ${fourteenDaysAgo}
      GROUP BY DATE("completedAt")
      ORDER BY DATE("completedAt") ASC
    `,
    prisma.$queryRaw`
      SELECT COUNT(DISTINCT "userId")::int AS count
      FROM "Progress"
      WHERE "completedAt" >= ${sevenDaysAgo}
    `,
  ]);

  // Fill in missing days so charts have continuous x-axis
  const signupsPerDay     = _fillDays(signupRows,     14);
  const completionsPerDay = _fillDays(completionRows,  14);

  const activeUsersThisWeek      = activeUsersRows[0]?.count ?? 0;
  const totalSignupsThisWeek     = signupsPerDay.slice(-7).reduce((s, r) => s + r.count, 0);
  const totalCompletionsThisWeek = completionsPerDay.slice(-7).reduce((s, r) => s + r.count, 0);

  return { signupsPerDay, completionsPerDay, activeUsersThisWeek, totalSignupsThisWeek, totalCompletionsThisWeek };
}

function _fillDays(rows, days) {
  const map = Object.fromEntries(rows.map((r) => [r.date, r.count]));
  const result = [];
  for (let i = days - 1; i >= 0; i--) {
    const d = new Date();
    d.setDate(d.getDate() - i);
    const key = d.toISOString().slice(0, 10);
    result.push({ date: key, count: map[key] ?? 0 });
  }
  return result;
}
