import { Router } from 'express';
import { verifyToken, requireRole } from '../../middleware/auth.js';
import * as ctrl from './notifications.controller.js';

const router = Router();

router.use(verifyToken, requireRole('admin', 'super_admin'));

router.post('/send', ctrl.send);

export default router;
