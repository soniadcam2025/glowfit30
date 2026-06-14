import { sendError, sendSuccess } from '../../utils/response.js';
import { logAdminAction } from '../../utils/adminLog.js';
import * as svc from './workouts.service.js';

// ── Workouts ──────────────────────────────────────────────────────────────────

export async function list(_req, res, next) {
  try {
    const items = await svc.listWorkouts();
    return sendSuccess(res, { items }, 'OK');
  } catch (e) {
    next(e);
  }
}

export async function getOne(req, res, next) {
  try {
    const row = await svc.getWorkout(req.params.id);
    if (!row) return sendError(res, 'Not found', 404);
    return sendSuccess(res, row, 'OK');
  } catch (e) {
    next(e);
  }
}

export async function create(req, res, next) {
  try {
    const row = await svc.createWorkout(req.body);
    await logAdminAction(req.user.id, 'workout.create', { id: row.id, title: row.title });
    return sendSuccess(res, row, 'Created', 201);
  } catch (e) {
    next(e);
  }
}

export async function update(req, res, next) {
  try {
    const row = await svc.updateWorkout(req.params.id, req.body);
    await logAdminAction(req.user.id, 'workout.update', { id: row.id });
    return sendSuccess(res, row, 'Updated');
  } catch (e) {
    if (e.code === 'P2025') return sendError(res, 'Not found', 404);
    next(e);
  }
}

export async function remove(req, res, next) {
  try {
    await svc.deleteWorkout(req.params.id);
    await logAdminAction(req.user.id, 'workout.delete', { id: req.params.id });
    return sendSuccess(res, null, 'Deleted');
  } catch (e) {
    if (e.code === 'P2025') return sendError(res, 'Not found', 404);
    next(e);
  }
}

// ── Workout Days ──────────────────────────────────────────────────────────────

export async function listDays(req, res, next) {
  try {
    const workout = await svc.getWorkout(req.params.id);
    if (!workout) return sendError(res, 'Workout not found', 404);
    const days = await svc.getDays(req.params.id);
    return sendSuccess(res, { workout, days }, 'OK');
  } catch (e) {
    next(e);
  }
}

export async function createDay(req, res, next) {
  try {
    const workout = await svc.getWorkout(req.params.id);
    if (!workout) return sendError(res, 'Workout not found', 404);
    const day = await svc.createDay(req.params.id, req.body);
    await logAdminAction(req.user.id, 'workout.day.create', { workoutId: req.params.id, dayId: day.id });
    return sendSuccess(res, day, 'Created', 201);
  } catch (e) {
    next(e);
  }
}

export async function removeDay(req, res, next) {
  try {
    await svc.deleteDay(req.params.dayId);
    await logAdminAction(req.user.id, 'workout.day.delete', { dayId: req.params.dayId });
    return sendSuccess(res, null, 'Deleted');
  } catch (e) {
    if (e.code === 'P2025') return sendError(res, 'Not found', 404);
    next(e);
  }
}

// ── Exercises ─────────────────────────────────────────────────────────────────

export async function listExercises(req, res, next) {
  try {
    const day = await svc.getDay(req.params.dayId);
    if (!day) return sendError(res, 'Workout day not found', 404);
    const exercises = await svc.getExercises(req.params.dayId);
    return sendSuccess(res, { day, exercises }, 'OK');
  } catch (e) {
    next(e);
  }
}

export async function createExercise(req, res, next) {
  try {
    const day = await svc.getDay(req.params.dayId);
    if (!day) return sendError(res, 'Workout day not found', 404);
    const exercise = await svc.createExercise(req.params.dayId, req.body);
    await logAdminAction(req.user.id, 'exercise.create', { dayId: req.params.dayId, exerciseId: exercise.id });
    return sendSuccess(res, exercise, 'Created', 201);
  } catch (e) {
    next(e);
  }
}

export async function updateExercise(req, res, next) {
  try {
    const exercise = await svc.updateExercise(req.params.id, req.body);
    await logAdminAction(req.user.id, 'exercise.update', { exerciseId: req.params.id });
    return sendSuccess(res, exercise, 'Updated');
  } catch (e) {
    if (e.code === 'P2025') return sendError(res, 'Not found', 404);
    next(e);
  }
}

export async function removeExercise(req, res, next) {
  try {
    await svc.deleteExercise(req.params.id);
    await logAdminAction(req.user.id, 'exercise.delete', { exerciseId: req.params.id });
    return sendSuccess(res, null, 'Deleted');
  } catch (e) {
    if (e.code === 'P2025') return sendError(res, 'Not found', 404);
    next(e);
  }
}
