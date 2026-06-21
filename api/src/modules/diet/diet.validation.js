import { z } from 'zod';

export const idParamSchema = z.object({ id: z.string().uuid() });

export const createDietSchema = z.object({
  type: z.string().min(1),
  calories: z.coerce.number().int().nonnegative(),
  meals: z.any(),
  imageUrl: z.string().url().optional(),
});

export const updateDietSchema = createDietSchema.partial();
