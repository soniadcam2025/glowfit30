import { sendError, sendSuccess } from '../../utils/response.js';
import { logAdminAction } from '../../utils/adminLog.js';
import * as svc from './workout-library.service.js';

// ── Categories ────────────────────────────────────────────────────────────────

export async function listCategories(_req, res, next) {
  try {
    const categories = await svc.listCategories();
    return sendSuccess(res, { categories }, 'OK');
  } catch (e) {
    next(e);
  }
}

export async function createCategory(req, res, next) {
  try {
    const row = await svc.createCategory(req.body);
    await logAdminAction(req.user.id, 'workoutLibrary.category.create', { id: row.id });
    return sendSuccess(res, row, 'Created', 201);
  } catch (e) {
    if (e.code === 'P2002') return sendError(res, 'Category name already exists', 409);
    next(e);
  }
}

export async function updateCategory(req, res, next) {
  try {
    const row = await svc.updateCategory(req.params.categoryId, req.body);
    await logAdminAction(req.user.id, 'workoutLibrary.category.update', { id: row.id });
    return sendSuccess(res, row, 'Updated');
  } catch (e) {
    if (e.code === 'P2025') return sendError(res, 'Not found', 404);
    if (e.code === 'P2002') return sendError(res, 'Category name already exists', 409);
    next(e);
  }
}

export async function removeCategory(req, res, next) {
  try {
    await svc.deleteCategory(req.params.categoryId);
    await logAdminAction(req.user.id, 'workoutLibrary.category.delete', {
      id: req.params.categoryId,
    });
    return sendSuccess(res, null, 'Deleted');
  } catch (e) {
    if (e.code === 'P2025') return sendError(res, 'Not found', 404);
    next(e);
  }
}

// ── Items ─────────────────────────────────────────────────────────────────────

export async function list(req, res, next) {
  try {
    const featured =
      req.query.featured === 'true' ? true : req.query.featured === 'false' ? false : undefined;
    const items = await svc.listItems({ category: req.query.category, featured });
    return sendSuccess(res, { items }, 'OK');
  } catch (e) {
    next(e);
  }
}

export async function getOne(req, res, next) {
  try {
    const row = await svc.getItem(req.params.id);
    if (!row) return sendError(res, 'Not found', 404);
    return sendSuccess(res, row, 'OK');
  } catch (e) {
    next(e);
  }
}

export async function create(req, res, next) {
  try {
    const row = await svc.createItem(req.body);
    await logAdminAction(req.user.id, 'workoutLibrary.create', { id: row.id });
    return sendSuccess(res, row, 'Created', 201);
  } catch (e) {
    next(e);
  }
}

export async function update(req, res, next) {
  try {
    const row = await svc.updateItem(req.params.id, req.body);
    await logAdminAction(req.user.id, 'workoutLibrary.update', { id: row.id });
    return sendSuccess(res, row, 'Updated');
  } catch (e) {
    if (e.code === 'P2025') return sendError(res, 'Not found', 404);
    next(e);
  }
}

export async function remove(req, res, next) {
  try {
    await svc.deleteItem(req.params.id);
    await logAdminAction(req.user.id, 'workoutLibrary.delete', { id: req.params.id });
    return sendSuccess(res, null, 'Deleted');
  } catch (e) {
    if (e.code === 'P2025') return sendError(res, 'Not found', 404);
    next(e);
  }
}

// ── Exercises ─────────────────────────────────────────────────────────────────

export async function listExercises(req, res, next) {
  try {
    const item = await svc.getItem(req.params.id);
    if (!item) return sendError(res, 'Workout not found', 404);
    const exercises = await svc.getExercises(req.params.id);
    return sendSuccess(res, { exercises }, 'OK');
  } catch (e) {
    next(e);
  }
}

export async function createExercise(req, res, next) {
  try {
    const item = await svc.getItem(req.params.id);
    if (!item) return sendError(res, 'Workout not found', 404);
    const exercise = await svc.createExercise(req.params.id, req.body);
    await logAdminAction(req.user.id, 'workoutLibrary.exercise.create', {
      itemId: req.params.id,
      exerciseId: exercise.id,
    });
    return sendSuccess(res, exercise, 'Created', 201);
  } catch (e) {
    next(e);
  }
}

export async function updateExercise(req, res, next) {
  try {
    const exercise = await svc.updateExercise(req.params.exerciseId, req.body);
    await logAdminAction(req.user.id, 'workoutLibrary.exercise.update', {
      exerciseId: req.params.exerciseId,
    });
    return sendSuccess(res, exercise, 'Updated');
  } catch (e) {
    if (e.code === 'P2025') return sendError(res, 'Not found', 404);
    next(e);
  }
}

export async function removeExercise(req, res, next) {
  try {
    await svc.deleteExercise(req.params.exerciseId);
    await logAdminAction(req.user.id, 'workoutLibrary.exercise.delete', {
      exerciseId: req.params.exerciseId,
    });
    return sendSuccess(res, null, 'Deleted');
  } catch (e) {
    if (e.code === 'P2025') return sendError(res, 'Not found', 404);
    next(e);
  }
}
