import { sendError, sendSuccess } from '../../utils/response.js';
import { logAdminAction } from '../../utils/adminLog.js';
import * as svc from './workouts.service.js';

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
