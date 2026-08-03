import { z } from 'zod';

/** 10ml floor rejects fat-finger zeros; 5000ml ceiling is well past any glass. */
export const createIntakeSchema = z.object({
  amountMl: z.coerce.number().int().min(10).max(5000),
  loggedAt: z.string().datetime().optional(),
});

export const idParamSchema = z.object({ id: z.string().uuid() });

export const listQuerySchema = z.object({
  /** ISO date; defaults to today on the server. */
  date: z.string().datetime().optional(),
});

export const updateSettingsSchema = z
  .object({
    waterGoalLiters: z.coerce.number().min(0.5).max(6),
    waterReminderEnabled: z.coerce.boolean(),
    waterReminderMinutes: z.coerce.number().int().min(15).max(240),
    waterQuietFromHour: z.coerce.number().int().min(0).max(23),
    waterQuietToHour: z.coerce.number().int().min(0).max(23),
    waterSoundEnabled: z.coerce.boolean(),
    waterVibrationEnabled: z.coerce.boolean(),
    waterSmartMode: z.coerce.boolean(),
  })
  .partial();
