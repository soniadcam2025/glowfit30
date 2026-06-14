import { z } from 'zod';

export const createProgressSchema = z.object({
  workoutDayId:   z.string().uuid(),
  caloriesBurned: z.number().int().positive().optional(),
  durationMin:    z.number().int().positive().optional(),
});
