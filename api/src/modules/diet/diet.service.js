import { prisma } from '../../database/prisma.js';

function normalizeMeals(meals) {
  if (meals && typeof meals === 'object' && !Array.isArray(meals)) return meals;
  return { items: meals };
}

export function listDietPlans() {
  return prisma.dietPlan.findMany({
    orderBy: { createdAt: 'desc' },
    include: { _count: { select: { days: true } } },
  });
}

export function getDietPlan(id) {
  return prisma.dietPlan.findUnique({
    where: { id },
    include: { days: { orderBy: { dayNumber: 'asc' } } },
  });
}

export function createDietPlan(data) {
  return prisma.dietPlan.create({
    data: {
      type: data.type,
      goal: data.goal,
      calories: data.calories,
      meals: normalizeMeals(data.meals),
      imageUrl: data.imageUrl,
    },
  });
}

export function updateDietPlan(id, data) {
  const patch = { ...data };
  if (patch.meals !== undefined) patch.meals = normalizeMeals(patch.meals);
  return prisma.dietPlan.update({ where: { id }, data: patch });
}

export function deleteDietPlan(id) {
  return prisma.dietPlan.delete({ where: { id } });
}

// ─── Per-day meals ──────────────────────────────────────────────────────────

export function listPlanDays(dietPlanId) {
  return prisma.dietPlanDay.findMany({
    where: { dietPlanId },
    orderBy: { dayNumber: 'asc' },
  });
}

export function upsertPlanDay(dietPlanId, dayNumber, meals) {
  const normalized = normalizeMeals(meals);
  return prisma.dietPlanDay.upsert({
    where: { dietPlanId_dayNumber: { dietPlanId, dayNumber } },
    create: { dietPlanId, dayNumber, meals: normalized },
    update: { meals: normalized },
  });
}

export function deletePlanDay(dietPlanId, dayNumber) {
  return prisma.dietPlanDay.delete({
    where: { dietPlanId_dayNumber: { dietPlanId, dayNumber } },
  });
}

// ─── Resolver for the app: "what should this user eat on day N?" ───────────

// Mirrors the matching the Flutter app used client-side: match the plan's
// type against the user's dietStyle, most specific style first.
function planMatchesStyle(planType, dietStyle) {
  if (!planType || !dietStyle) return false;
  const p = planType.toLowerCase();
  const s = dietStyle.toLowerCase();
  if (s.includes('vegan')) return p.includes('vegan');
  if (s.includes('non')) return p.includes('non');
  if (s.includes('vegetarian')) return p.includes('veg') && !p.includes('non');
  if (s.includes('balanced')) return p.includes('balanced');
  return false;
}

export async function resolveToday(userId, day) {
  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: { dietStyle: true, goal: true },
  });

  const plans = await prisma.dietPlan.findMany({
    orderBy: { createdAt: 'desc' },
  });
  if (plans.length === 0) return null;

  const plan =
    plans.find((p) => planMatchesStyle(p.type, user?.dietStyle)) ?? plans[0];

  const days = await prisma.dietPlanDay.findMany({
    where: { dietPlanId: plan.id },
    orderBy: { dayNumber: 'asc' },
  });

  let resolvedDay = day;
  let meals = null;
  let source = 'plan';

  if (days.length > 0) {
    let match = days.find((d) => d.dayNumber === day);
    if (!match) {
      // Cycle through the configured days so a 7-day meal rotation
      // keeps working across a 30-day program.
      const maxDay = days[days.length - 1].dayNumber;
      const cycled = ((day - 1) % maxDay) + 1;
      match = days.find((d) => d.dayNumber === cycled) ?? days[0];
    }
    resolvedDay = match.dayNumber;
    meals = match.meals;
    source = 'day';
  } else {
    meals = plan.meals;
  }

  return {
    plan: {
      id: plan.id,
      type: plan.type,
      goal: plan.goal,
      calories: plan.calories,
      imageUrl: plan.imageUrl,
    },
    requestedDay: day,
    resolvedDay,
    source,
    meals,
  };
}
