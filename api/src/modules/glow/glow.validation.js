import { z } from 'zod';

export const idParamSchema = z.object({ id: z.string().uuid() });

export const createCategorySchema = z.object({
  emoji: z.string().min(1).max(10),
  title: z.string().min(1).max(100),
  subtitle: z.string().min(1).max(100),
  background: z.string().min(1).max(20).default('#FCE4EC'),
  order: z.coerce.number().int().min(0).default(0),
});

export const updateCategorySchema = createCategorySchema.partial();

export const createShortSchema = z.object({
  imageUrl: z.union([z.string().url(), z.literal('')]).optional(),
  duration: z.string().min(1).max(10),
  title: z.string().min(1).max(200),
  views: z.string().min(1).max(50).default('0 views'),
  order: z.coerce.number().int().min(0).default(0),
});

export const updateShortSchema = createShortSchema.partial();
