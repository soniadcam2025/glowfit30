import { Router } from 'express';
import { verifyToken, requireRole } from '../../middleware/auth.js';
import { validateBody, validateParams } from '../../middleware/validate.js';
import * as ctrl from './workouts.controller.js';
import {
  idParamSchema,
  dayIdParamSchema,
  createWorkoutSchema,
  updateWorkoutSchema,
  createDaySchema,
  createExerciseSchema,
} from './workouts.validation.js';

const router = Router();
const adminOnly = [verifyToken, requireRole('admin', 'super_admin')];

// ── Workouts (public read / admin write) ──────────────────────────────────────
router.get('/',    verifyToken, ctrl.list);
router.get('/:id', verifyToken, validateParams(idParamSchema), ctrl.getOne);
router.post('/',   ...adminOnly, validateBody(createWorkoutSchema), ctrl.create);
router.patch('/:id', ...adminOnly, validateParams(idParamSchema), validateBody(updateWorkoutSchema), ctrl.update);
router.delete('/:id', ...adminOnly, validateParams(idParamSchema), ctrl.remove);

// ── Workout Days ──────────────────────────────────────────────────────────────
// GET  /workouts/:id/days              → list days for a workout
// POST /workouts/:id/days              → add a day (admin)
// DELETE /workouts/days/:dayId         → remove a day (admin)
router.get('/:id/days',        verifyToken, validateParams(idParamSchema), ctrl.listDays);
router.post('/:id/days',       ...adminOnly, validateParams(idParamSchema), validateBody(createDaySchema), ctrl.createDay);
router.delete('/days/:dayId',  ...adminOnly, validateParams(dayIdParamSchema), ctrl.removeDay);

// ── Exercises ─────────────────────────────────────────────────────────────────
// GET  /workouts/days/:dayId/exercises → list exercises for a day
// POST /workouts/days/:dayId/exercises → add exercise (admin)
// PATCH/DELETE /workouts/exercises/:id → update/remove exercise (admin)
router.get('/days/:dayId/exercises',    verifyToken, validateParams(dayIdParamSchema), ctrl.listExercises);
router.post('/days/:dayId/exercises',   ...adminOnly, validateParams(dayIdParamSchema), validateBody(createExerciseSchema), ctrl.createExercise);
router.patch('/exercises/:id',          ...adminOnly, validateParams(idParamSchema), validateBody(createExerciseSchema.partial()), ctrl.updateExercise);
router.delete('/exercises/:id',         ...adminOnly, validateParams(idParamSchema), ctrl.removeExercise);

export default router;
