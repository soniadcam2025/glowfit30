import { sendError } from '../utils/response.js';
import { env } from '../config/env.js';

export function notFoundHandler(_req, res) {
  return sendError(res, 'Not found', 404);
}

export function errorHandler(err, req, res, _next) {
  const status = err.statusCode || err.status || 500;
  const message = status >= 500 ? 'Internal server error' : err.message || 'Request failed';
  if (status >= 500) {
    console.error('[api:error]', {
      method: req.method,
      path: req.originalUrl,
      message: err?.message,
      code: err?.code,
      stack: env.isProd ? undefined : err?.stack,
    });
  }
  return sendError(res, message, status);
}
