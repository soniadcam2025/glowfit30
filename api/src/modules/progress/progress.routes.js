import { Router } from 'express';
import { verifyToken } from '../../middleware/auth.js';
import { validateBody } from '../../middleware/validate.js';
import * as ctrl from './progress.controller.js';
import { createProgressSchema } from './progress.validation.js';

const router = Router();

router.use(verifyToken);

router.post('/', validateBody(createProgressSchema), ctrl.logProgress);
router.get('/',  ctrl.getProgress);

export default router;
