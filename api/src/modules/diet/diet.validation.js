import { z } from 'zod';

export const idParamSchema = z.object({ id: z.string().uuid() });

export const createDietSchema = z.object({
  type: z.enum(['veg', 'non-veg']),
  calories: z.coerce.number().int().nonnegative(),
  meals: z.any(),
});

export const updateDietSchema = createDietSchema.partial();
