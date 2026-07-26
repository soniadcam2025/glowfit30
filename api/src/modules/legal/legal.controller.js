import { sendSuccess } from '../../utils/response.js';
import { logAdminAction } from '../../utils/adminLog.js';
import * as svc from './legal.service.js';

export async function getOne(_req, res, next) {
  try {
    const doc = await svc.getLegalDocument();
    return sendSuccess(res, doc, 'OK');
  } catch (e) {
    next(e);
  }
}

export async function update(req, res, next) {
  try {
    const doc = await svc.updateLegalDocument(req.body);
    await logAdminAction(req.user.id, 'legal.update', { id: doc.id });
    return sendSuccess(res, doc, 'Updated');
  } catch (e) {
    next(e);
  }
}
