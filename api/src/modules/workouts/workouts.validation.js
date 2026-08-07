import { z } from 'zod';

export const idParamSchema    = z.object({ id: z.string().uuid() });
export const dayIdParamSchema = z.object({ dayId: z.string().uuid() });

export const createWorkoutSchema = z.object({
  title:       z.string().min(1).max(300),
  level:       z.string().min(1).max(100),
  duration:    z.coerce.number().int().positive(),
  imageUrl:    z.string().url().optional(),
  description: z.string().optional(),
  goal:        z.string().optional(),
});

export const updateWorkoutSchema = createWorkoutSchema.partial();

export const createDaySchema = z.object({
  dayNumber:       z.coerce.number().int().positive(),
  title:           z.string().min(1).max(300),
  focus:           z.string().optional(),
  imageUrl:        z.string().url({ message: 'Day image is required' }),
  durationMinutes: z.coerce.number().int().positive({ message: 'Duration is required' }),
  kcal:            z.coerce.number().int().positive({ message: 'Calories is required' }),
});

/**
 * Exercises are time-driven: `duration` (seconds) is what the player counts
 * down, and reps are informational only.
 *
 * `duration` is required here but stays nullable in the database on purpose.
 * Exercises created before this change have no value for it, and making the
 * column non-null would either reject those rows or force a guessed number
 * into them. Requiring it at the edge means every new or edited exercise
 * carries a real duration, while the old ones keep working on the client
 * fallback until an admin opens them.
 */
export const createExerciseSchema = z.object({
  name:     z.string().min(1).max(300),
  // Five seconds is the floor because anything shorter cannot be performed,
  // and a zero would leave the player with nothing to count.
  //
  // `invalid_type_error` rather than `required_error`: coercion runs Number()
  // on the input first, so a missing field arrives at the type check as NaN,
  // never as undefined, and the required message would never be reached. The
  // message has to cover both "absent" and "not a number" for that reason.
  duration: z.coerce
    .number({ invalid_type_error: 'Seconds is required' })
    .int()
    .min(5, { message: 'At least 5 seconds' })
    .max(3600, { message: '3600 seconds maximum' }),
  // Zero is meaningful — it means "no rest, go straight on" — so this is
  // min(0), not positive().
  rest:     z.coerce
    .number({ invalid_type_error: 'Rest is required' })
    .int()
    .min(0, { message: 'Rest cannot be negative' })
    .max(600, { message: '600 seconds maximum' }),
  sets:     z.coerce.number().int().positive().max(50).optional().default(1),
  // Nullable as well as optional: clearing reps on an existing exercise has to
  // be expressible, and `undefined` would leave the old value in place.
  reps:     z.coerce.number().int().positive().max(500).nullish(),
  imageUrl: z.string().url({ message: 'Exercise image is required' }),
  gifUrl:   z.string().url().optional(),
  videoUrl: z.string().url({ message: 'Exercise video is required' }),
  order:    z.coerce.number().int().min(0).default(0),
});
