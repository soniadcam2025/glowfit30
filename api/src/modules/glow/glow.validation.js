import { z } from 'zod';
import { chipSchema, sectionsSchema } from '../../utils/contentSchemas.js';

export const idParamSchema = z.object({ id: z.string().uuid() });

export const listShortsQuerySchema = z.object({
  categoryId: z.string().uuid().optional(),
});

export const createCategorySchema = z.object({
  emoji: z.string().min(1).max(10),
  title: z.string().min(1).max(100),
  subtitle: z.string().min(1).max(100),
  background: z.string().min(1).max(20).default('#FCE4EC'),
  heroImageUrl: z.union([z.string().url(), z.literal('')]).optional(),
  topics: z.array(chipSchema).default([]),
  order: z.coerce.number().int().min(0).default(0),
});

export const updateCategorySchema = createCategorySchema.partial();

export const createShortSchema = z.object({
  imageUrl: z.union([z.string().url(), z.literal('')]).optional(),
  duration: z.string().min(1).max(10),
  title: z.string().min(1).max(200),
  views: z.string().min(1).max(50).default('0 views'),
  categoryId: z.union([z.string().uuid(), z.literal('')]).optional(),
  content: z.string().optional(),
  resultBadge: z.string().max(100).optional(),
  chips: z.array(chipSchema).default([]),
  sections: sectionsSchema.default({}),
  isPremium: z.coerce.boolean().default(false),
  order: z.coerce.number().int().min(0).default(0),
});

export const updateShortSchema = createShortSchema.partial();
