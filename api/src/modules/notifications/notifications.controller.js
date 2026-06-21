import { sendError, sendSuccess } from '../../utils/response.js';
import * as svc from './notifications.service.js';

export async function send(req, res, next) {
  try {
    const { title, body, userId } = req.body;

    if (!title || !body) {
      return sendError(res, 'title and body are required', 400);
    }

    const result = userId
      ? await svc.sendToUser({ userId, title, body })
      : await svc.sendToAll({ title, body });

    return sendSuccess(res, result, 'Notification sent');
  } catch (e) {
    if (e.message?.includes('no FCM token')) {
      return sendError(res, e.message, 404);
    }
    next(e);
  }
}
