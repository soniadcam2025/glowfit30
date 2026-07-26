import { Router } from 'express';
import { verifyToken, requireRole } from '../../middleware/auth.js';
import { validateBody } from '../../middleware/validate.js';
import * as ctrl from './legal.controller.js';
import { updateLegalSchema } from './legal.validation.js';

const router = Router();

router.get('/', verifyToken, ctrl.getOne);

router.patch(
  '/',
  verifyToken,
  requireRole('admin', 'super_admin'),
  validateBody(updateLegalSchema),
  ctrl.update,
);

export default router;
