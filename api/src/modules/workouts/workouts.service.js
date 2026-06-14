import { prisma } from '../../database/prisma.js';

// ── Workouts ──────────────────────────────────────────────────────────────────

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

// ── Workout Days ──────────────────────────────────────────────────────────────

export function getDays(workoutId) {
  return prisma.workoutDay.findMany({
    where: { workoutId },
    orderBy: { dayNumber: 'asc' },
    include: { _count: { select: { exercises: true } } },
  });
}

export function getDay(dayId) {
  return prisma.workoutDay.findUnique({
    where: { id: dayId },
    include: { workout: { select: { id: true, title: true, level: true } } },
  });
}

export function createDay(workoutId, data) {
  return prisma.workoutDay.create({ data: { ...data, workoutId } });
}

export function deleteDay(dayId) {
  return prisma.workoutDay.delete({ where: { id: dayId } });
}

// ── Exercises ─────────────────────────────────────────────────────────────────

export function getExercises(workoutDayId) {
  return prisma.exercise.findMany({
    where: { workoutDayId },
    orderBy: { order: 'asc' },
  });
}

export function createExercise(workoutDayId, data) {
  return prisma.exercise.create({ data: { ...data, workoutDayId } });
}

export function updateExercise(id, data) {
  return prisma.exercise.update({ where: { id }, data });
}

export function deleteExercise(id) {
  return prisma.exercise.delete({ where: { id } });
}
