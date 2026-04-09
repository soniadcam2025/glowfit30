import { Router } from 'express';
import rateLimit from 'express-rate-limit';
import { env } from '../../config/env.js';
import { verifyToken } from '../../middleware/auth.js';
import { validateBody } from '../../middleware/validate.js';
import { sendError } from '../../utils/response.js';
import * as ctrl from './auth.controller.js';
import { loginSchema, registerSchema } from './auth.validation.js';

const router = Router();

const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 30,
  standardHeaders: true,
  legacyHeaders: false,
});

function registerGate(_req, res, next) {
  if (!env.REGISTER_ENABLED) {
    return sendError(res, 'Registration is disabled', 403);
  }
  next();
}

router.post('/register', authLimiter, registerGate, validateBody(registerSchema), ctrl.register);

router.post('/login', authLimiter, validateBody(loginSchema), ctrl.login);
router.post('/logout', ctrl.logout);
router.get('/me', verifyToken, ctrl.me);

export default router;
