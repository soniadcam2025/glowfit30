import { sendError, sendSuccess } from '../../utils/response.js';
import { logAdminAction } from '../../utils/adminLog.js';
import { cacheDel } from '../../database/redis.js';
import * as svc from './users.service.js';

const STATS_KEY = 'admin:stats';

export async function list(req, res, next) {
  try {
    const { page, limit, q } = req.query;
    const data = await svc.listUsers({ page, limit, q });
    return sendSuccess(res, data, 'OK');
  } catch (e) {
    next(e);
  }
}

export async function getOne(req, res, next) {
  try {
    const { id } = req.params;
    const user = await svc.getUserById(id);
    if (!user) return sendError(res, 'User not found', 404);
    return sendSuccess(res, user, 'OK');
  } catch (e) {
    next(e);
  }
}

export async function block(req, res, next) {
  try {
    const { id } = req.params;
    const { isBlocked } = req.body;
    const target = await svc.getUserById(id);
    if (!target) return sendError(res, 'User not found', 404);

    const updated = await svc.setBlocked(id, isBlocked);
    await logAdminAction(req.user.id, 'user.block', {
      targetUserId: id,
      isBlocked,
    });
    await cacheDel(STATS_KEY);
    return sendSuccess(res, updated, 'Updated');
  } catch (e) {
    next(e);
  }
}
