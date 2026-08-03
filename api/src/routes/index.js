import { Router } from 'express';
import authRoutes from '../modules/auth/auth.routes.js';
import profileRoutes from '../modules/profile/profile.routes.js';
import progressRoutes from '../modules/progress/progress.routes.js';
import usersRoutes from '../modules/users/users.routes.js';
import adminRoutes from '../modules/admin/admin.routes.js';
import workoutsRoutes from '../modules/workouts/workouts.routes.js';
import workoutLibraryRoutes from '../modules/workout-library/workout-library.routes.js';
import dietRoutes from '../modules/diet/diet.routes.js';
import beautyRoutes from '../modules/beauty/beauty.routes.js';
import glowRoutes from '../modules/glow/glow.routes.js';
import notificationsRoutes from '../modules/notifications/notifications.routes.js';
import uploadsRoutes from '../modules/uploads/uploads.routes.js';
import legalRoutes from '../modules/legal/legal.routes.js';
import waterRoutes from '../modules/water/water.routes.js';

const router = Router();

router.use('/auth', authRoutes);
router.use('/profile', profileRoutes);
router.use('/progress', progressRoutes);
router.use('/users', usersRoutes);
router.use('/admin', adminRoutes);
router.use('/workouts', workoutsRoutes);
router.use('/workout-library', workoutLibraryRoutes);
router.use('/diet', dietRoutes);
router.use('/beauty', beautyRoutes);
router.use('/glow', glowRoutes);
router.use('/notifications', notificationsRoutes);
router.use('/uploads', uploadsRoutes);
router.use('/legal', legalRoutes);
router.use('/water', waterRoutes);

export default router;
