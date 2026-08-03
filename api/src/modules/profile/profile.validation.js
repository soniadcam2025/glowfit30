import { z } from 'zod';

export const patchProfileSchema = z.object({
  name:         z.string().min(1).max(200).optional(),
  fitnessLevel: z.string().optional(),
  goal:         z.string().optional(),
  dietStyle:    z.string().optional(),
  targetWeight: z.number().positive().optional(),
  focusAreas:   z.array(z.string()).optional(),
  dob:          z.string().datetime({ offset: true }).optional(),
  height:       z.number().positive().optional(),
  weight:       z.number().positive().optional(),
  waterGoalLiters: z.number().positive().optional(),
  pushEnabled:     z.boolean().optional(),
  language:        z.string().optional(),
  appearance:      z.string().optional(),
  // Target for the home-screen workout day-streak.
  streakGoalDays:  z.coerce.number().int().min(3).max(365).optional(),
}).strict();
