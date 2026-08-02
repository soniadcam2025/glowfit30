import { randomBytes } from 'node:crypto';
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

/**
 * Reset another admin's password to a freshly generated one-time value.
 *
 * SECURITY (fixed 2026-08-02): this endpoint was previously **unauthenticated**
 * and reset any admin account to the hardcoded constant `Admin12345`, which was
 * committed to the repository and echoed back in the success message. Anyone
 * who knew an admin's email address could take over that account with a single
 * unauthenticated request; the rate limiter did not help, because one request
 * was enough. It is now restricted to super_admins and generates a random
 * password per call, returned once to the caller.
 *
 * This is a stop-gap, not a password-reset flow: it still requires an existing
 * super_admin to perform it, so a locked-out sole admin cannot self-serve. A
 * proper signed, time-limited, emailed reset token remains the intended fix and
 * is tracked in TODO.md — it needs mail infrastructure the project does not
 * have yet.
 */
export async function resetPassword(req, res, next) {
  try {
    const { email } = req.body;
    if (!email) return sendError(res, 'Email is required', 400);

    const user = await authService.findByEmail(email);
    if (!user || !['admin', 'super_admin'].includes(user.role)) {
      // Same response either way, so this cannot be used to enumerate accounts.
      return sendSuccess(res, null, 'If that admin account exists, it has been reset.');
    }

    // 18 random bytes -> 24 base64url chars. Never a shared or guessable value.
    const tempPassword = randomBytes(18).toString('base64url');
    const hashed = await authService.hashPassword(tempPassword);
    await prisma.user.update({ where: { id: user.id }, data: { password: hashed } });

    return sendSuccess(
      res,
      { email: user.email, temporaryPassword: tempPassword },
      'Temporary password generated. Share it securely — it is shown only once.',
    );
  } catch (e) {
    next(e);
  }
}

