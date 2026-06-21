import { sendError, sendSuccess } from '../../utils/response.js';
import * as svc from './profile.service.js';

export async function getProfile(req, res, next) {
  try {
    const profile = await svc.getProfile(req.user.id);
    if (!profile) return sendError(res, 'User not found', 404);
    return sendSuccess(res, { profile }, 'OK');
  } catch (e) {
    next(e);
  }
}

export async function saveFcmToken(req, res, next) {
  try {
    const { fcmToken } = req.body;
    if (!fcmToken || typeof fcmToken !== 'string') {
      return sendError(res, 'fcmToken is required', 400);
    }
    await svc.saveFcmToken(req.user.id, fcmToken);
    return sendSuccess(res, null, 'FCM token saved');
  } catch (e) {
    next(e);
  }
}

export async function patchProfile(req, res, next) {
  try {
    if (Object.keys(req.body).length === 0) {
      return sendError(res, 'No fields provided', 400);
    }
    const profile = await svc.updateProfile(req.user.id, req.body);
    return sendSuccess(res, { profile }, 'Profile updated');
  } catch (e) {
    next(e);
  }
}
