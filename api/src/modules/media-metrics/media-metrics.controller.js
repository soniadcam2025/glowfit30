import { sendSuccess } from '../../utils/response.js';
import * as svc from './media-metrics.service.js';

export async function ingest(req, res, next) {
  try {
    const count = await svc.record({
      events: req.body.events,
      platform: req.body.platform,
      appVersion: req.body.appVersion,
      userId: req.user?.id,
    });
    // 202: the app is not waiting on this and must never be blocked by it.
    return sendSuccess(res, { accepted: count }, 'Recorded', 202);
  } catch (e) {
    next(e);
  }
}

export async function summary(req, res, next) {
  try {
    return sendSuccess(res, await svc.summary(req.query.days), 'OK');
  } catch (e) {
    next(e);
  }
}
