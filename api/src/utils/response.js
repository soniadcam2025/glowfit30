export function sendSuccess(res, data, message = 'OK', status = 200) {
  return res.status(status).json({ success: true, data, message });
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
