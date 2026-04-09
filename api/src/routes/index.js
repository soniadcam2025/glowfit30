import { Router } from 'express';
import authRoutes from '../modules/auth/auth.routes.js';
import usersRoutes from '../modules/users/users.routes.js';
import adminRoutes from '../modules/admin/admin.routes.js';
import workoutsRoutes from '../modules/workouts/workouts.routes.js';
import dietRoutes from '../modules/diet/diet.routes.js';
import beautyRoutes from '../modules/beauty/beauty.routes.js';

const router = Router();

router.use('/auth', authRoutes);
router.use('/users', usersRoutes);
router.use('/admin', adminRoutes);
router.use('/workouts', workoutsRoutes);
router.use('/diet', dietRoutes);
router.use('/beauty', beautyRoutes);

export default router;
