import { z } from 'zod';

export const idParamSchema    = z.object({ id: z.string().uuid() });
export const dayIdParamSchema = z.object({ dayId: z.string().uuid() });

export const createWorkoutSchema = z.object({
  title:       z.string().min(1).max(300),
  level:       z.string().min(1).max(100),
  duration:    z.coerce.number().int().positive(),
  imageUrl:    z.string().url().optional(),
  description: z.string().optional(),
  goal:        z.string().optional(),
});

export const updateWorkoutSchema = createWorkoutSchema.partial();

export const createDaySchema = z.object({
  dayNumber: z.coerce.number().int().positive(),
  title:     z.string().min(1).max(300),
  focus:     z.string().optional(),
});

export const createExerciseSchema = z.object({
  name:     z.string().min(1).max(300),
  sets:     z.coerce.number().int().positive().optional(),
  reps:     z.coerce.number().int().positive().optional(),
  duration: z.coerce.number().int().positive().optional(),
  rest:     z.coerce.number().int().positive().optional(),
  imageUrl: z.string().url().optional(),
  gifUrl:   z.string().url().optional(),
  videoUrl: z.string().url().optional(),
  order:    z.coerce.number().int().min(0).default(0),
});
