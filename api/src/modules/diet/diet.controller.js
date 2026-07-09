import { sendError, sendSuccess } from '../../utils/response.js';
import { logAdminAction } from '../../utils/adminLog.js';
import * as svc from './diet.service.js';

export async function list(_req, res, next) {
  try {
    const items = await svc.listDietPlans();
    return sendSuccess(res, { items }, 'OK');
  } catch (e) {
    next(e);
  }
}

export async function getOne(req, res, next) {
  try {
    const row = await svc.getDietPlan(req.params.id);
    if (!row) return sendError(res, 'Not found', 404);
    return sendSuccess(res, row, 'OK');
  } catch (e) {
    next(e);
  }
}

export async function create(req, res, next) {
  try {
    const row = await svc.createDietPlan(req.body);
    await logAdminAction(req.user.id, 'diet.create', { id: row.id });
    return sendSuccess(res, row, 'Created', 201);
  } catch (e) {
    next(e);
  }
}

export async function update(req, res, next) {
  try {
    const row = await svc.updateDietPlan(req.params.id, req.body);
    await logAdminAction(req.user.id, 'diet.update', { id: row.id });
    return sendSuccess(res, row, 'Updated');
  } catch (e) {
    if (e.code === 'P2025') return sendError(res, 'Not found', 404);
    next(e);
  }
}

export async function remove(req, res, next) {
  try {
    await svc.deleteDietPlan(req.params.id);
    await logAdminAction(req.user.id, 'diet.delete', { id: req.params.id });
    return sendSuccess(res, null, 'Deleted');
  } catch (e) {
    if (e.code === 'P2025') return sendError(res, 'Not found', 404);
    next(e);
  }
}

// ─── Per-day meals ──────────────────────────────────────────────────────────

export async function listDays(req, res, next) {
  try {
    const items = await svc.listPlanDays(req.params.id);
    return sendSuccess(res, { items }, 'OK');
  } catch (e) {
    next(e);
  }
}

export async function upsertDay(req, res, next) {
  try {
    const row = await svc.upsertPlanDay(
      req.params.id,
      req.params.day,
      req.body.meals,
    );
    await logAdminAction(req.user.id, 'diet.day.upsert', {
      id: req.params.id,
      day: req.params.day,
    });
    return sendSuccess(res, row, 'Saved');
  } catch (e) {
    if (e.code === 'P2003') return sendError(res, 'Diet plan not found', 404);
    next(e);
  }
}

export async function removeDay(req, res, next) {
  try {
    await svc.deletePlanDay(req.params.id, req.params.day);
    await logAdminAction(req.user.id, 'diet.day.delete', {
      id: req.params.id,
      day: req.params.day,
    });
    return sendSuccess(res, null, 'Deleted');
  } catch (e) {
    if (e.code === 'P2025') return sendError(res, 'Not found', 404);
    next(e);
  }
}

// ─── App resolver ───────────────────────────────────────────────────────────

export async function today(req, res, next) {
  try {
    const result = await svc.resolveToday(req.user.id, req.query.day);
    if (!result) return sendError(res, 'No diet plans configured', 404);
    return sendSuccess(res, result, 'OK');
  } catch (e) {
    next(e);
  }
}
