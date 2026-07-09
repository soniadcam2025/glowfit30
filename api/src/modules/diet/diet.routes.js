import { Router } from 'express';
import { verifyToken, requireRole } from '../../middleware/auth.js';
import { validateBody, validateParams, validateQuery } from '../../middleware/validate.js';
import * as ctrl from './diet.controller.js';
import {
  createDietSchema,
  dayParamSchema,
  idParamSchema,
  todayQuerySchema,
  updateDietSchema,
  upsertDaySchema,
} from './diet.validation.js';

const router = Router();

router.get('/', verifyToken, ctrl.list);

// Must be registered before /:id so "today" isn't parsed as a plan id.
router.get('/today', verifyToken, validateQuery(todayQuerySchema), ctrl.today);

router.get('/:id', verifyToken, validateParams(idParamSchema), ctrl.getOne);

router.post(
  '/',
  verifyToken,
  requireRole('admin', 'super_admin'),
  validateBody(createDietSchema),
  ctrl.create,
);

router.patch(
  '/:id',
  verifyToken,
  requireRole('admin', 'super_admin'),
  validateParams(idParamSchema),
  validateBody(updateDietSchema),
  ctrl.update,
);

router.delete(
  '/:id',
  verifyToken,
  requireRole('admin', 'super_admin'),
  validateParams(idParamSchema),
  ctrl.remove,
);

// ─── Per-day meals ──────────────────────────────────────────────────────────

router.get(
  '/:id/days',
  verifyToken,
  validateParams(idParamSchema),
  ctrl.listDays,
);

router.put(
  '/:id/days/:day',
  verifyToken,
  requireRole('admin', 'super_admin'),
  validateParams(dayParamSchema),
  validateBody(upsertDaySchema),
  ctrl.upsertDay,
);

router.delete(
  '/:id/days/:day',
  verifyToken,
  requireRole('admin', 'super_admin'),
  validateParams(dayParamSchema),
  ctrl.removeDay,
);

export default router;
