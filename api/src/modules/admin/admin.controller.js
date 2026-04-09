import { sendSuccess } from '../../utils/response.js';
import * as svc from './admin.service.js';

export async function stats(req, res, next) {
  try {
    const data = await svc.getStatsCached();
    return sendSuccess(res, data, 'OK');
  } catch (e) {
    next(e);
  }
}

export async function analytics(req, res, next) {
  try {
    const data = await svc.getAnalytics();
    return sendSuccess(res, data, 'OK');
  } catch (e) {
    next(e);
  }
}
