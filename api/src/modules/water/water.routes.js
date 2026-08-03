import { Router } from 'express';
import { verifyToken } from '../../middleware/auth.js';
import { validateBody, validateParams, validateQuery } from '../../middleware/validate.js';
import * as ctrl from './water.controller.js';
import {
  createIntakeSchema,
  idParamSchema,
  listQuerySchema,
  updateSettingsSchema,
} from './water.validation.js';

const router = Router();

// Every route is the signed-in user's own data; there is no admin surface here.
router.use(verifyToken);

router.get('/today', validateQuery(listQuerySchema), ctrl.today);
router.post('/', validateBody(createIntakeSchema), ctrl.create);
router.delete('/:id', validateParams(idParamSchema), ctrl.remove);

router.get('/settings', ctrl.settings);
router.patch('/settings', validateBody(updateSettingsSchema), ctrl.updateSettings);

export default router;
