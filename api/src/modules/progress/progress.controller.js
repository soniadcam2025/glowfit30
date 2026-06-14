import { sendSuccess } from '../../utils/response.js';
import * as svc from './progress.service.js';

export async function logProgress(req, res, next) {
  try {
    const entry = await svc.logProgress(req.user.id, req.body);
    return sendSuccess(res, { entry }, 'Progress saved', 201);
  } catch (e) {
    next(e);
  }
}

export async function getProgress(req, res, next) {
  try {
    const data = await svc.getUserProgress(req.user.id);
    return sendSuccess(res, data, 'OK');
  } catch (e) {
    next(e);
  }
}
