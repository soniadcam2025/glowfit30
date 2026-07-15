import { z } from 'zod';

export const idParamSchema = z.object({ id: z.string().uuid() });
export const exerciseIdParamSchema = z.object({ exerciseId: z.string().uuid() });
export const categoryIdParamSchema = z.object({ categoryId: z.string().uuid() });

const tagSchema = z.object({
  emoji: z.string().min(1),
  label: z.string().min(1),
  background: z.string().min(1),
  foreground: z.string().min(1),
});

export const createCategorySchema = z.object({
  name: z.string().min(1).max(100),
  headingLine1: z.string().min(1).max(100),
  headingLine2: z.string().min(1).max(100),
  description: z.string().min(1),
  heroImageUrl: z.string().url().optional(),
  tags: z.array(tagSchema).default([]),
  section: z.string().min(1).max(100).default('Body Goals'),
  cardTagline: z.string().max(200).default(''),
  cardImageUrl: z.string().url().optional(),
  cardBackground: z.string().min(1).max(20).default('#EAE3FA'),
  cardTitleColor: z.string().min(1).max(20).default('#3D2E7C'),
  order: z.coerce.number().int().min(0).default(0),
});

export const updateCategorySchema = createCategorySchema.partial();

export const createItemSchema = z.object({
  isFeatured: z.boolean().default(false),
  category: z.string().min(1).max(100),
  difficulty: z.enum(['Beginner', 'Intermediate', 'Advanced']).default('Beginner'),
  titleLine1: z.string().min(1).max(200),
  titleScript: z.string().min(1).max(200),
  description: z.string().min(1),
  heroImageUrl: z.string().url().optional(),
  durationMinutes: z.coerce.number().int().positive(),
  kcalLabel: z.string().min(1).max(50),
  focusLabel: z.string().min(1).max(100),
  tags: z.array(tagSchema).default([]),
  order: z.coerce.number().int().min(0).default(0),
});

export const updateItemSchema = createItemSchema.partial();

export const createExerciseSchema = z.object({
  name: z.string().min(1).max(300),
  durationSeconds: z.coerce.number().int().positive(),
  imageUrl: z.string().url().optional(),
  videoUrl: z.string().url().optional(),
  order: z.coerce.number().int().min(0).default(0),
});

export const updateExerciseSchema = createExerciseSchema.partial();
