import { z } from 'zod';

export const updateLegalSchema = z.object({
  title: z.string().min(1).max(200).optional(),
  content: z.string().min(1),
});
