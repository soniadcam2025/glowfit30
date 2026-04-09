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
