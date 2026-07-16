import { z } from 'zod';

export const idParamSchema = z.object({ id: z.string().uuid() });

export const createBeautySchema = z.object({
  title: z.string().min(1).max(300),
  content: z.string().min(1),
  imageUrl: z.union([z.string().url(), z.literal('')]).optional(),
  tag: z.string().min(1).max(50).default('SKINCARE'),
  tagColor: z.string().min(1).max(20).default('#C4185A'),
  tagBackground: z.string().min(1).max(20).default('#FCE4EC'),
  minutesRead: z.coerce.number().int().positive().default(4),
  order: z.coerce.number().int().min(0).default(0),
});

export const updateBeautySchema = createBeautySchema.partial();
