import { prisma } from '../../database/prisma.js';
import { deleteFiles } from '../../config/storage.js';

function exerciseFileUrls(exercise) {
  return [exercise.imageUrl, exercise.gifUrl, exercise.videoUrl];
}

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

export async function deleteWorkout(id) {
  const workout = await prisma.workout.findUnique({
    where: { id },
    include: { days: { include: { exercises: true } } },
  });

  const row = await prisma.workout.delete({ where: { id } });

  if (workout) {
    const urls = [
      workout.imageUrl,
      ...workout.days.flatMap((day) => [day.imageUrl, ...day.exercises.flatMap(exerciseFileUrls)]),
    ];
    await deleteFiles(urls);
  }

  return row;
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

export async function deleteDay(dayId) {
  const day = await prisma.workoutDay.findUnique({
    where: { id: dayId },
    include: { exercises: true },
  });

  const row = await prisma.workoutDay.delete({ where: { id: dayId } });

  if (day) {
    await deleteFiles([day.imageUrl, ...day.exercises.flatMap(exerciseFileUrls)]);
  }

  return row;
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

export async function deleteExercise(id) {
  const exercise = await prisma.exercise.findUnique({ where: { id } });

  const row = await prisma.exercise.delete({ where: { id } });

  if (exercise) {
    await deleteFiles(exerciseFileUrls(exercise));
  }

  return row;
}
