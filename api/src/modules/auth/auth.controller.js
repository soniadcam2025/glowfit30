import { env } from '../../config/env.js';
import { sendError, sendSuccess, pickUser } from '../../utils/response.js';
import * as authService from './auth.service.js';
import { verifyFirebaseToken } from '../../config/firebase.js';
import { prisma } from '../../database/prisma.js';

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
    const {
      name, email, password,
      fitnessLevel, goal, dietStyle, targetWeight,
      focusAreas, dob, height, weight,
    } = req.body;
    const existing = await authService.findByEmail(email);
    if (existing) return sendError(res, 'Email already registered', 409);

    const user = await authService.createUser({
      name, email, password,
      fitnessLevel, goal, dietStyle, targetWeight,
      focusAreas, dob, height, weight,
    });
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

export async function firebaseAuth(req, res, next) {
  try {
    const { idToken } = req.body;
    if (!idToken) return sendError(res, 'Firebase ID token is required', 400);

    let decoded;
    try {
      decoded = await verifyFirebaseToken(idToken);
    } catch {
      return sendError(res, 'Invalid or expired Firebase token', 401);
    }

    const { uid, email, name, picture } = decoded;
    if (!email) return sendError(res, 'Google account has no email address', 400);

    const { user, isNew } = await authService.findOrCreateFirebaseUser({
      uid,
      email,
      name: name || email.split('@')[0],
      photoUrl: picture || null,
    });

    const token = authService.signToken(user);
    res.cookie(env.AUTH_COOKIE_NAME, token, cookieOpts());

    return sendSuccess(
      res,
      { user: pickUser(user), token, isNew },
      isNew ? 'Account created' : 'Logged in',
      isNew ? 201 : 200,
    );
  } catch (e) {
    next(e);
  }
}

const DEFAULT_RESET_PASSWORD = 'Admin12345';

export async function resetPassword(req, res, next) {
  try {
    const { email } = req.body;
    if (!email) return sendError(res, 'Email is required', 400);

    const user = await authService.findByEmail(email);
    if (!user || !['admin', 'super_admin'].includes(user.role)) {
      // Always return the same message to avoid email enumeration
      return sendSuccess(res, null, 'If that admin account exists, the password has been reset.');
    }

    const hashed = await authService.hashPassword(DEFAULT_RESET_PASSWORD);
    await prisma.user.update({ where: { id: user.id }, data: { password: hashed } });

    return sendSuccess(res, null, 'Password reset to default. Please sign in with "Admin12345".');
  } catch (e) {
    next(e);
  }
}

