import { Router } from 'express';
import { verifyToken, requireRole } from '../../middleware/auth.js';
import { validateBody, validateParams } from '../../middleware/validate.js';
import * as ctrl from './diet.controller.js';
import { createDietSchema, idParamSchema, updateDietSchema } from './diet.validation.js';

const router = Router();

router.get('/', verifyToken, ctrl.list);
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

export default router;
