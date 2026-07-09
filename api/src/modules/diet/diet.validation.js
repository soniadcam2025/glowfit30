import { z } from 'zod';

export const idParamSchema = z.object({ id: z.string().uuid() });

export const dayParamSchema = z.object({
  id: z.string().uuid(),
  day: z.coerce.number().int().min(1).max(365),
});

export const todayQuerySchema = z.object({
  day: z.coerce.number().int().min(1).max(365).default(1),
});

export const createDietSchema = z.object({
  type: z.string().min(1),
  goal: z.string().min(1).optional().nullable(),
  calories: z.coerce.number().int().nonnegative(),
  meals: z.any(),
  imageUrl: z.string().url().optional().nullable(),
});

export const updateDietSchema = createDietSchema.partial();

export const upsertDaySchema = z.object({
  meals: z.any().refine((v) => v !== undefined && v !== null, {
    message: 'meals is required',
  }),
});
