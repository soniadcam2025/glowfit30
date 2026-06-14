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
}).strict();
