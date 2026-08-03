import { prisma } from '../../database/prisma.js';

/** Fields making up the hydration settings screen. */
const SETTINGS_SELECT = {
  waterGoalLiters: true,
  waterReminderEnabled: true,
  waterReminderMinutes: true,
  waterQuietFromHour: true,
  waterQuietToHour: true,
  waterSoundEnabled: true,
  waterVibrationEnabled: true,
  waterSmartMode: true,
};

/**
 * Start of the day for a given moment, in the *server's* timezone.
 *
 * The app sends no offset today, so "today" is server-local. If users ever span
 * timezones this needs the client's offset, otherwise someone at UTC+13 rolls
 * over at the wrong time.
 */
function startOfDay(date = new Date()) {
  const d = new Date(date);
  d.setHours(0, 0, 0, 0);
  return d;
}

export function listForDay(userId, day = new Date()) {
  const from = startOfDay(day);
  const to = new Date(from);
  to.setDate(to.getDate() + 1);

  return prisma.waterIntake.findMany({
    where: { userId, loggedAt: { gte: from, lt: to } },
    orderBy: { loggedAt: 'desc' },
  });
}

export function createIntake(userId, { amountMl, loggedAt }) {
  return prisma.waterIntake.create({
    data: { userId, amountMl, ...(loggedAt ? { loggedAt: new Date(loggedAt) } : {}) },
  });
}

/** Scoped by userId as well as id, so one user cannot delete another's row. */
export async function deleteIntake(userId, id) {
  const result = await prisma.waterIntake.deleteMany({ where: { id, userId } });
  return result.count > 0;
}

export function getSettings(userId) {
  return prisma.user.findUnique({ where: { id: userId }, select: SETTINGS_SELECT });
}

export function updateSettings(userId, data) {
  return prisma.user.update({
    where: { id: userId },
    data,
    select: SETTINGS_SELECT,
  });
}

/**
 * Consecutive days ending today (or yesterday) with at least one logged drink.
 *
 * A streak that has not been continued *today* is still alive until the day
 * ends, so the walk is allowed to start at yesterday.
 */
export async function getStreak(userId) {
  const rows = await prisma.waterIntake.findMany({
    where: { userId },
    select: { loggedAt: true },
    orderBy: { loggedAt: 'desc' },
    take: 500,
  });

  const days = new Set(rows.map((r) => startOfDay(r.loggedAt).getTime()));
  if (days.size === 0) return 0;

  const today = startOfDay().getTime();
  const dayMs = 24 * 60 * 60 * 1000;

  let cursor = days.has(today) ? today : today - dayMs;
  if (!days.has(cursor)) return 0;

  let streak = 0;
  while (days.has(cursor)) {
    streak += 1;
    cursor -= dayMs;
  }
  return streak;
}
