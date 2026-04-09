import { Router } from 'express';
import { verifyToken, requireRole } from '../../middleware/auth.js';
import { validateBody, validateParams, validateQuery } from '../../middleware/validate.js';
import * as ctrl from './users.controller.js';
import { blockBodySchema, idParamSchema, listQuerySchema } from './users.validation.js';

const router = Router();

router.use(verifyToken, requireRole('admin', 'super_admin'));

router.get('/', validateQuery(listQuerySchema), ctrl.list);
router.get('/:id', validateParams(idParamSchema), ctrl.getOne);
router.patch(
  '/:id/block',
  validateParams(idParamSchema),
  validateBody(blockBodySchema),
  ctrl.block,
);

export default router;
