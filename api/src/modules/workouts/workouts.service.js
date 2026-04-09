import { prisma } from '../../database/prisma.js';

export function listWorkouts() {
  return prisma.workout.findMany({ orderBy: { createdAt: 'desc' } });
}

export function getWorkout(id) {
  return prisma.workout.findUnique({ where: { id } });
}

export function createWorkout(data) {
  return prisma.workout.create({ data });
}

export function updateWorkout(id, data) {
  return prisma.workout.update({ where: { id }, data });
}

export function deleteWorkout(id) {
  return prisma.workout.delete({ where: { id } });
}
