import { sendError, sendSuccess } from '../../utils/response.js';
import * as svc from './water.service.js';

/**
 * Everything the tracker screen needs in one call — entries, the goal, the
 * derived total and the streak — so opening it is a single round trip rather
 * than four.
 */
export async function today(req, res, next) {
  try {
    const [entries, settings, streak] = await Promise.all([
      svc.listForDay(req.user.id, req.query.date ? new Date(req.query.date) : undefined),
      svc.getSettings(req.user.id),
      svc.getStreak(req.user.id),
    ]);

    const consumedMl = entries.reduce((sum, e) => sum + e.amountMl, 0);
    const goalMl = Math.round((settings?.waterGoalLiters ?? 3) * 1000);

    return sendSuccess(
      res,
      { entries, consumedMl, goalMl, remainingMl: Math.max(0, goalMl - consumedMl), streak },
      'OK',
    );
  } catch (e) {
    next(e);
  }
}

export async function create(req, res, next) {
  try {
    const row = await svc.createIntake(req.user.id, req.body);
    return sendSuccess(res, row, 'Logged', 201);
  } catch (e) {
    next(e);
  }
}

export async function remove(req, res, next) {
  try {
    const deleted = await svc.deleteIntake(req.user.id, req.params.id);
    if (!deleted) return sendError(res, 'Not found', 404);
    return sendSuccess(res, null, 'Deleted');
  } catch (e) {
    next(e);
  }
}

export async function settings(req, res, next) {
  try {
    return sendSuccess(res, await svc.getSettings(req.user.id), 'OK');
  } catch (e) {
    next(e);
  }
}

export async function updateSettings(req, res, next) {
  try {
    return sendSuccess(res, await svc.updateSettings(req.user.id, req.body), 'Updated');
  } catch (e) {
    next(e);
  }
}
