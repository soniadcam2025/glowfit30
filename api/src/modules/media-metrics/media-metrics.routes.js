import { Router } from 'express';
import rateLimit from 'express-rate-limit';
import { optionalAuth, requireRole, verifyToken } from '../../middleware/auth.js';
import { validateBody, validateQuery } from '../../middleware/validate.js';
import * as ctrl from './media-metrics.controller.js';
import { ingestSchema, summaryQuerySchema } from './media-metrics.validation.js';

const router = Router();

/**
 * Generous, because a real device flushing a workout's worth of measurements is
 * a handful of requests a minute — but bounded, because this is the one write
 * endpoint that does not need an account.
 */
const ingestLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 30,
  standardHeaders: true,
  legacyHeaders: false,
});

router.post(
  '/',
  ingestLimiter,
  optionalAuth,
  validateBody(ingestSchema),
  ctrl.ingest,
);

router.get(
  '/summary',
  verifyToken,
  requireRole('admin'),
  validateQuery(summaryQuerySchema),
  ctrl.summary,
);

export default router;
