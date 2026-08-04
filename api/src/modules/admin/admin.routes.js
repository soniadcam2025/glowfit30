import { Router } from 'express';
import { verifyToken, requireRole } from '../../middleware/auth.js';
import * as ctrl from './admin.controller.js';
import * as maintenance from './maintenance.controller.js';

const router = Router();

router.use(verifyToken, requireRole('admin', 'super_admin'));

router.get('/stats', ctrl.stats);
router.get('/analytics', ctrl.analytics);
router.get('/chart-data', ctrl.chartData);

// ── Maintenance ──────────────────────────────────────────────────────────────
// super_admin only: these export every table, or delete content irreversibly.
// A plain `admin` can manage content but must not be able to wipe it wholesale.
const superAdminOnly = requireRole('super_admin');

router.get('/maintenance/counts', superAdminOnly, maintenance.counts);
router.get('/maintenance/storage', superAdminOnly, maintenance.storage);
router.get('/maintenance/backup', superAdminOnly, maintenance.backup);
router.post('/maintenance/reset/:scope', superAdminOnly, maintenance.reset);

export default router;
