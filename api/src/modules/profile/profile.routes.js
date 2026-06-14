import { Router } from 'express';
import { verifyToken } from '../../middleware/auth.js';
import { validateBody } from '../../middleware/validate.js';
import * as ctrl from './profile.controller.js';
import { patchProfileSchema } from './profile.validation.js';

const router = Router();

router.use(verifyToken);

router.get('/', ctrl.getProfile);
router.patch('/', validateBody(patchProfileSchema), ctrl.patchProfile);

export default router;
