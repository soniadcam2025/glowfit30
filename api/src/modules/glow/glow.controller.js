import { sendError, sendSuccess } from '../../utils/response.js';
import { logAdminAction } from '../../utils/adminLog.js';
import * as svc from './glow.service.js';

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
    await logAdminAction(req.user.id, 'glow.category.create', { id: row.id });
    return sendSuccess(res, row, 'Created', 201);
  } catch (e) {
    next(e);
  }
}

export async function updateCategory(req, res, next) {
  try {
    const row = await svc.updateCategory(req.params.id, req.body);
    await logAdminAction(req.user.id, 'glow.category.update', { id: row.id });
    return sendSuccess(res, row, 'Updated');
  } catch (e) {
    if (e.code === 'P2025') return sendError(res, 'Not found', 404);
    next(e);
  }
}

export async function removeCategory(req, res, next) {
  try {
    await svc.deleteCategory(req.params.id);
    await logAdminAction(req.user.id, 'glow.category.delete', { id: req.params.id });
    return sendSuccess(res, null, 'Deleted');
  } catch (e) {
    if (e.code === 'P2025') return sendError(res, 'Not found', 404);
    next(e);
  }
}

// ── Shorts ───────────────────────────────────────────────────────────────────

export async function listShorts(_req, res, next) {
  try {
    const shorts = await svc.listShorts();
    return sendSuccess(res, { shorts }, 'OK');
  } catch (e) {
    next(e);
  }
}

export async function createShort(req, res, next) {
  try {
    const row = await svc.createShort(req.body);
    await logAdminAction(req.user.id, 'glow.short.create', { id: row.id });
    return sendSuccess(res, row, 'Created', 201);
  } catch (e) {
    next(e);
  }
}

export async function updateShort(req, res, next) {
  try {
    const row = await svc.updateShort(req.params.id, req.body);
    await logAdminAction(req.user.id, 'glow.short.update', { id: row.id });
    return sendSuccess(res, row, 'Updated');
  } catch (e) {
    if (e.code === 'P2025') return sendError(res, 'Not found', 404);
    next(e);
  }
}

export async function removeShort(req, res, next) {
  try {
    await svc.deleteShort(req.params.id);
    await logAdminAction(req.user.id, 'glow.short.delete', { id: req.params.id });
    return sendSuccess(res, null, 'Deleted');
  } catch (e) {
    if (e.code === 'P2025') return sendError(res, 'Not found', 404);
    next(e);
  }
}
