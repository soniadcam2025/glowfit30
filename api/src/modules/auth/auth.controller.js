import { env } from '../../config/env.js';
import { sendError, sendSuccess, pickUser } from '../../utils/response.js';
import * as authService from './auth.service.js';

function authDebug(message, meta = null) {
  if (!env.AUTH_DEBUG) return;
  if (meta) {
    console.log(`[auth] ${message}`, meta);
    return;
  }
  console.log(`[auth] ${message}`);
}

const cookieOpts = () => ({
  httpOnly: true,
  secure: env.isProd,
  sameSite: env.isProd ? 'none' : 'lax',
  path: '/',
  maxAge: 7 * 24 * 60 * 60 * 1000,
});

export async function register(req, res, next) {
  try {
    if (!env.REGISTER_ENABLED) {
      return sendError(res, 'Registration is disabled', 403);
    }
    const { name, email, password } = req.body;
    const existing = await authService.findByEmail(email);
    if (existing) return sendError(res, 'Email already registered', 409);

    const user = await authService.createUser({ name, email, password });
    const token = authService.signToken(user);
    res.cookie(env.AUTH_COOKIE_NAME, token, cookieOpts());
    return sendSuccess(res, { user: pickUser(user) }, 'Registered', 201);
  } catch (e) {
    next(e);
  }
}

export async function login(req, res, next) {
  try {
    const { email, password } = req.body;
    authDebug('login attempt', { email });

    const user = await authService.findByEmail(email);
    authDebug('db lookup result', user ? { id: user.id, email: user.email, role: user.role } : { user: null });
    if (!user) return sendError(res, 'Invalid credentials', 401);
    if (user.isBlocked) return sendError(res, 'Account blocked', 403);
    if (typeof user.password !== 'string' || user.password.length < 20) {
      authDebug('invalid stored password hash format', { userId: user.id });
      return sendError(res, 'Invalid credentials', 401);
    }

    const ok = await authService.verifyPassword(password, user.password);
    authDebug('bcrypt compare result', { userId: user.id, ok });
    if (!ok) return sendError(res, 'Invalid credentials', 401);

    const token = authService.signToken(user);
    res.cookie(env.AUTH_COOKIE_NAME, token, cookieOpts());
    return sendSuccess(res, { user: pickUser(user) }, 'Logged in');
  } catch (e) {
    console.error('[auth] login failed', {
      message: e?.message,
      code: e?.code,
      name: e?.name,
    });
    if (e?.code === 'P1001' || e?.name === 'PrismaClientInitializationError') {
      return sendError(res, 'Service temporarily unavailable', 503);
    }
    return next(e);
  }
}

export function logout(_req, res) {
  res.clearCookie(env.AUTH_COOKIE_NAME, {
    httpOnly: true,
    secure: env.isProd,
    sameSite: env.isProd ? 'none' : 'lax',
    path: '/',
  });
  return sendSuccess(res, null, 'Logged out');
}

export function me(req, res) {
  return sendSuccess(res, { user: req.user }, 'OK');
}
