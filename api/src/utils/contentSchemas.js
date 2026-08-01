import { z } from 'zod';

/** Shared by BeautyPost/GlowShort — small metadata pills, e.g. "Natural Remedy". */
export const chipSchema = z.object({
  emoji: z.string().min(1).max(10),
  label: z.string().min(1).max(40),
});

/** One expandable accordion card within a detail-screen tab.
 *  For a Short's `tips`, each card is also one step of the full-screen story
 *  player — `videoUrl` lets that step play a short clip instead of a still.
 *  Stored inside the existing `sections` JSON column, so no migration needed. */
export const sectionItemSchema = z.object({
  imageUrl: z.union([z.string().url(), z.literal('')]).optional(),
  videoUrl: z.union([z.string().url(), z.literal('')]).optional(),
  title: z.string().min(1).max(200),
  description: z.string().min(1),
});

/** Fixed 3-tab structure: Problem & Cause / Solution / Tips. All optional — an empty
 * object means the detail screen falls back to the item's plain `content` field. */
export const sectionsSchema = z.object({
  problemCause: z.array(sectionItemSchema).default([]),
  solution: z.array(sectionItemSchema).default([]),
  tips: z.array(sectionItemSchema).default([]),
});
