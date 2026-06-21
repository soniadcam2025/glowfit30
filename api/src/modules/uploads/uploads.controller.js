import { sendError, sendSuccess } from '../../utils/response.js';
import { uploadFile } from '../../config/storage.js';

export async function upload(req, res, next) {
  try {
    if (!req.file) {
      return sendError(res, 'No file uploaded', 400);
    }

    const folder = req.body.folder === 'diet' ? 'diet' : 'exercises';
    const url = await uploadFile(req.file.buffer, req.file.mimetype, folder);

    return sendSuccess(res, { url }, 'Uploaded');
  } catch (e) {
    if (e.message?.includes('not configured')) {
      return sendError(res, e.message, 503);
    }
    next(e);
  }
}

export async function uploadVideo(req, res, next) {
  try {
    if (!req.file) {
      return sendError(res, 'No file uploaded', 400);
    }

    const url = await uploadFile(req.file.buffer, req.file.mimetype, 'exercises');

    return sendSuccess(res, { url }, 'Uploaded');
  } catch (e) {
    if (e.message?.includes('not configured')) {
      return sendError(res, e.message, 503);
    }
    next(e);
  }
}
