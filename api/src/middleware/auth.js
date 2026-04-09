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
