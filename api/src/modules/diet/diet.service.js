import { prisma } from '../../database/prisma.js';

function normalizeMeals(meals) {
  if (meals && typeof meals === 'object' && !Array.isArray(meals)) return meals;
  return { items: meals };
}

export function listDietPlans() {
  return prisma.dietPlan.findMany({ orderBy: { createdAt: 'desc' } });
}

export function getDietPlan(id) {
  return prisma.dietPlan.findUnique({ where: { id } });
}

export function createDietPlan(data) {
  return prisma.dietPlan.create({
    data: {
      type: data.type,
      calories: data.calories,
      meals: normalizeMeals(data.meals),
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
