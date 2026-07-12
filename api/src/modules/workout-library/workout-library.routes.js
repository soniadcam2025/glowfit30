import { Router } from 'express';
import { verifyToken, requireRole } from '../../middleware/auth.js';
import { validateBody, validateParams } from '../../middleware/validate.js';
import * as ctrl from './workout-library.controller.js';
import {
  categoryIdParamSchema,
  createCategorySchema,
  createExerciseSchema,
  createItemSchema,
  exerciseIdParamSchema,
  idParamSchema,
  updateCategorySchema,
  updateExerciseSchema,
  updateItemSchema,
} from './workout-library.validation.js';

const router = Router();
const adminOnly = [verifyToken, requireRole('admin', 'super_admin')];

// ── Categories (public read / admin write) ──────────────────────────────────
// NOTE: must be registered before '/:id' (that param is validated as a uuid).
router.get('/categories', verifyToken, ctrl.listCategories);
router.post('/categories', ...adminOnly, validateBody(createCategorySchema), ctrl.createCategory);
router.patch(
  '/categories/:categoryId',
  ...adminOnly,
  validateParams(categoryIdParamSchema),
  validateBody(updateCategorySchema),
  ctrl.updateCategory,
);
router.delete(
  '/categories/:categoryId',
  ...adminOnly,
  validateParams(categoryIdParamSchema),
  ctrl.removeCategory,
);

// ── Items (public read / admin write) ───────────────────────────────────────
router.get('/', verifyToken, ctrl.list);
router.get('/:id', verifyToken, validateParams(idParamSchema), ctrl.getOne);
router.post('/', ...adminOnly, validateBody(createItemSchema), ctrl.create);
router.patch(
  '/:id',
  ...adminOnly,
  validateParams(idParamSchema),
  validateBody(updateItemSchema),
  ctrl.update,
);
router.delete('/:id', ...adminOnly, validateParams(idParamSchema), ctrl.remove);

// ── Exercises ────────────────────────────────────────────────────────────────
router.get(
  '/:id/exercises',
  verifyToken,
  validateParams(idParamSchema),
  ctrl.listExercises,
);
router.post(
  '/:id/exercises',
  ...adminOnly,
  validateParams(idParamSchema),
  validateBody(createExerciseSchema),
  ctrl.createExercise,
);
router.patch(
  '/exercises/:exerciseId',
  ...adminOnly,
  validateParams(exerciseIdParamSchema),
  validateBody(updateExerciseSchema),
  ctrl.updateExercise,
);
router.delete(
  '/exercises/:exerciseId',
  ...adminOnly,
  validateParams(exerciseIdParamSchema),
  ctrl.removeExercise,
);

export default router;
