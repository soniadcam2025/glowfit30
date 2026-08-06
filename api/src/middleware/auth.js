import jwt from 'jsonwebtoken';
import { env } from '../config/env.js';
import { prisma } from '../database/prisma.js';
import { pickUser, sendError } from '../utils/response.js';

function getToken(req) {
  const c = req.cookies?.[env.AUTH_COOKIE_NAME];
  if (c) return c;
  const h = req.headers.authorization;
  if (h?.startsWith('Bearer ')) return h.slice(7);
  return null;
}

function clearAuthCookie(res) {
  res.clearCookie(env.AUTH_COOKIE_NAME, {
    httpOnly: true,
    secure: env.isProd,
    sameSite: env.isProd ? 'none' : 'lax',
    path: '/',
  });
}

export async function verifyToken(req, res, next) {
  try {
    const token = getToken(req);
    if (!token) return sendError(res, 'Unauthorized', 401);

    const payload = jwt.verify(token, env.JWT_SECRET);
    const userId = payload.sub;
    if (!userId) return sendError(res, 'Unauthorized', 401);

    const user = await prisma.user.findUnique({ where: { id: userId } });
    if (!user || user.isBlocked) {
      clearAuthCookie(res);
      return sendError(res, 'Unauthorized', 401);
    }

    req.user = pickUser(user);
    next();
  } catch {
    clearAuthCookie(res);
    return sendError(res, 'Unauthorized', 401);
  }
}

/**
 * Attaches `req.user` when a valid token is present and moves on otherwise.
 *
 * For endpoints where identity is useful but not required — telemetry from a
 * screen the user reaches before signing in still needs to arrive, and a
 * rejected batch would silently blind the metric rather than fail loudly.
 */
export async function optionalAuth(req, _res, next) {
  try {
    const token = getToken(req);
    if (!token) return next();
    const payload = jwt.verify(token, env.JWT_SECRET);
    if (!payload.sub) return next();
    const user = await prisma.user.findUnique({ where: { id: payload.sub } });
    if (user && !user.isBlocked) req.user = pickUser(user);
  } catch {
    // An expired or malformed token is simply an anonymous request here.
  }
  next();
}

export function requireRole(...allowed) {
  return (req, res, next) => {
    if (!req.user) return sendError(res, 'Unauthorized', 401);
    const role = req.user.role;
    const ok =
      allowed.includes(role) ||
      (allowed.includes('admin') && role === 'super_admin');
    if (!ok) return sendError(res, 'Forbidden', 403);
    next();
  };
}
