import dotenv from 'dotenv';
import { z } from 'zod';

dotenv.config();

const schema = z.object({
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
  PORT: z.coerce.number().int().positive().default(4000),
  DATABASE_URL: z.string().min(1),
  JWT_SECRET: z.string().min(16),
  JWT_EXPIRES_IN: z.string().default('7d'),
  REDIS_URL: z.string().optional(),
  CORS_ORIGINS: z.string().default('https://admin.glowfit30.com'),
  AUTH_COOKIE_NAME: z.string().default('token'),
  AUTH_DEBUG: z
    .string()
    .optional()
    .transform((v) => v === 'true' || v === '1'),
  REGISTER_ENABLED: z
    .string()
    .optional()
    .transform((v) => v === 'true' || v === '1'),
  /** Allow http://localhost / 127.0.0.1 on dev ports (e.g. local Next admin → prod API) */
  CORS_ALLOW_LOCAL_DEV: z
    .string()
    .optional()
    .transform((v) => v === 'true' || v === '1'),
});

const parsed = schema.safeParse(process.env);

if (!parsed.success) {
  console.error('Invalid environment:', parsed.error.flatten().fieldErrors);
  process.exit(1);
}

const p = parsed.data;

export const env = {
  NODE_ENV: p.NODE_ENV,
  PORT: p.PORT,
  DATABASE_URL: p.DATABASE_URL,
  JWT_SECRET: p.JWT_SECRET,
  JWT_EXPIRES_IN: p.JWT_EXPIRES_IN,
  REDIS_URL: p.REDIS_URL?.trim() || null,
  CORS_ORIGINS: p.CORS_ORIGINS.split(',').map((s) => s.trim()).filter(Boolean),
  AUTH_COOKIE_NAME: p.AUTH_COOKIE_NAME,
  AUTH_DEBUG: p.AUTH_DEBUG ?? false,
  REGISTER_ENABLED: p.REGISTER_ENABLED ?? false,
  CORS_ALLOW_LOCAL_DEV: p.CORS_ALLOW_LOCAL_DEV ?? false,
  isProd: p.NODE_ENV === 'production',
};
