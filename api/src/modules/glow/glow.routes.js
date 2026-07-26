import { Router } from 'express';
import { verifyToken, requireRole } from '../../middleware/auth.js';
import { validateBody, validateParams, validateQuery } from '../../middleware/validate.js';
import * as ctrl from './glow.controller.js';
import {
  createCategorySchema,
  createShortSchema,
  idParamSchema,
  listShortsQuerySchema,
  updateCategorySchema,
  updateShortSchema,
} from './glow.validation.js';

const router = Router();
const adminOnly = [verifyToken, requireRole('admin', 'super_admin')];

// ── Categories ("Explore by Goals") — public read / admin write ─────────────
router.get('/categories', verifyToken, ctrl.listCategories);
router.get('/categories/:id', verifyToken, validateParams(idParamSchema), ctrl.getCategoryDetail);
router.post('/categories', ...adminOnly, validateBody(createCategorySchema), ctrl.createCategory);
router.patch(
  '/categories/:id',
  ...adminOnly,
  validateParams(idParamSchema),
  validateBody(updateCategorySchema),
  ctrl.updateCategory,
);
router.delete(
  '/categories/:id',
  ...adminOnly,
  validateParams(idParamSchema),
  ctrl.removeCategory,
);

// ── Shorts ("Shorts & Quick Tips") — public read / admin write ──────────────
router.get('/shorts', verifyToken, validateQuery(listShortsQuerySchema), ctrl.listShorts);
router.post('/shorts', ...adminOnly, validateBody(createShortSchema), ctrl.createShort);
router.patch(
  '/shorts/:id',
  ...adminOnly,
  validateParams(idParamSchema),
  validateBody(updateShortSchema),
  ctrl.updateShort,
);
router.delete('/shorts/:id', ...adminOnly, validateParams(idParamSchema), ctrl.removeShort);

export default router;
