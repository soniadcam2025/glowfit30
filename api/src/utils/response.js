import { expandMedia } from './media.js';

/**
 * Sends a success payload, with every media url expanded into a full object.
 *
 * Stays synchronous from the caller's point of view — it still returns `res`,
 * so the `return sendSuccess(...)` in every controller is unchanged — and the
 * expansion resolves before the body is written. If it throws, the original
 * payload is sent as-is: the urls in it are correct on their own, and a
 * placeholder lookup must never cost a response.
 */
export function sendSuccess(res, data, message = 'OK', status = 200) {
  expandMedia(data)
    .then((expanded) => res.status(status).json({ success: true, data: expanded, message }))
    .catch(() => res.status(status).json({ success: true, data, message }));
  return res;
}

export function sendError(res, message, status = 400, data = null) {
  const msg = typeof message === 'string' ? message : 'Validation failed';
  return res.status(status).json({ success: false, data, message: msg });
}

export function pickUser(user) {
  if (!user) return null;
  const { password: _p, ...rest } = user;
  return rest;
}
