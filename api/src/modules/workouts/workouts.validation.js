import { z } from 'zod';

export const idParamSchema = z.object({ id: z.string().uuid() });

export const createWorkoutSchema = z.object({
  title: z.string().min(1).max(300),
  level: z.string().min(1).max(100),
  duration: z.coerce.number().int().positive(),
});

export const updateWorkoutSchema = createWorkoutSchema.partial();
