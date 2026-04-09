import { z } from 'zod';

export const idParamSchema = z.object({ id: z.string().uuid() });

export const createBeautySchema = z.object({
  title: z.string().min(1).max(300),
  content: z.string().min(1),
  imageUrl: z.union([z.string().url(), z.literal('')]).optional(),
});

export const updateBeautySchema = createBeautySchema.partial();
