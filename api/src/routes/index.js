import { Router } from 'express';
import authRoutes from '../modules/auth/auth.routes.js';
import profileRoutes from '../modules/profile/profile.routes.js';
import progressRoutes from '../modules/progress/progress.routes.js';
import usersRoutes from '../modules/users/users.routes.js';
import adminRoutes from '../modules/admin/admin.routes.js';
import workoutsRoutes from '../modules/workouts/workouts.routes.js';
import dietRoutes from '../modules/diet/diet.routes.js';
import beautyRoutes from '../modules/beauty/beauty.routes.js';
import notificationsRoutes from '../modules/notifications/notifications.routes.js';
import uploadsRoutes from '../modules/uploads/uploads.routes.js';

const router = Router();

router.use('/auth', authRoutes);
router.use('/profile', profileRoutes);
router.use('/progress', progressRoutes);
router.use('/users', usersRoutes);
router.use('/admin', adminRoutes);
router.use('/workouts', workoutsRoutes);
router.use('/diet', dietRoutes);
router.use('/beauty', beautyRoutes);
router.use('/notifications', notificationsRoutes);
router.use('/uploads', uploadsRoutes);

export default router;
