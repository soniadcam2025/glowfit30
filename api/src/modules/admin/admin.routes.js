import { Router } from 'express';
import { verifyToken, requireRole } from '../../middleware/auth.js';
import * as ctrl from './admin.controller.js';

const router = Router();

router.use(verifyToken, requireRole('admin', 'super_admin'));

router.get('/stats', ctrl.stats);
router.get('/analytics', ctrl.analytics);

export default router;
