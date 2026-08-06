import { z } from 'zod';

export const EVENT_TYPES = [
  'image_load',
  'video_start',
  'buffer',
  'download_ok',
  'download_fail',
];

/**
 * Batched: the app accumulates events and flushes them together, because one
 * request per image would cost more to deliver than the images do.
 */
export const ingestSchema = z.object({
  platform: z.string().max(32).optional(),
  appVersion: z.string().max(32).optional(),
  events: z
    .array(
      z.object({
        type: z.enum(EVENT_TYPES),
        // 10 minutes is far past anything worth recording; a larger number is a
        // stopwatch left running, not a slow load.
        ms: z.coerce.number().int().min(0).max(600000).optional(),
        bytes: z.coerce.number().int().min(0).optional(),
        cacheHit: z.boolean().optional(),
        ok: z.boolean().optional(),
        url: z.string().max(500).optional(),
      }),
    )
    // Capped so a buggy or hostile client cannot post a million rows in one go.
    .max(200),
});

export const summaryQuerySchema = z.object({
  days: z.coerce.number().int().min(1).max(90).default(7),
});
