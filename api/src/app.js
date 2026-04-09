import express from 'express';
import helmet from 'helmet';
import cors from 'cors';
import cookieParser from 'cookie-parser';
import rateLimit from 'express-rate-limit';
import { env } from './config/env.js';
import routes from './routes/index.js';
import { errorHandler, notFoundHandler } from './middleware/errorHandler.js';

export function createApp() {
  const app = express();
  app.set('trust proxy', 1);

  app.use(
    helmet({
      crossOriginResourcePolicy: { policy: 'cross-origin' },
    }),
  );

  app.use(express.json({ limit: '1mb' }));
  app.use(cookieParser());

  app.use(
    cors({
      origin(origin, cb) {
        if (!origin) return cb(null, true);
        if (env.CORS_ORIGINS.includes(origin)) return cb(null, true);
        return cb(null, false);
      },
      credentials: true,
    }),
  );

  const globalLimiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 400,
    standardHeaders: true,
    legacyHeaders: false,
  });
  app.use(globalLimiter);

  app.get('/', (_req, res) => {
    res.json({
      success: true,
      data: {
        status: 'ok',
        service: 'glowfit-api',
        uptime: process.uptime(),
      },
      message: 'OK',
    });
  });

  app.use('/api', routes);
  app.use(routes);
  app.use(notFoundHandler);
  app.use(errorHandler);

  return app;
}
