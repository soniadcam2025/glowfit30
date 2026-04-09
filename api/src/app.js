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
  const allowedOrigins = new Set(env.CORS_ORIGINS);

  const addLocalDevOrigins = () => {
    allowedOrigins.add('http://localhost:3000');
    allowedOrigins.add('http://127.0.0.1:3000');
    allowedOrigins.add('http://localhost:3001');
    allowedOrigins.add('http://127.0.0.1:3001');
  };

  if (!env.isProd) {
    addLocalDevOrigins();
  } else if (env.CORS_ALLOW_LOCAL_DEV) {
    addLocalDevOrigins();
  }

  const corsOptions = {
    origin(origin, cb) {
      if (!origin) return cb(null, true);
      if (allowedOrigins.has(origin)) return cb(null, true);
      return cb(null, false);
    },
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
  };

  app.use(
    helmet({
      crossOriginResourcePolicy: { policy: 'cross-origin' },
    }),
  );

  app.use(express.json({ limit: '1mb' }));
  app.use(cookieParser());

  app.use(cors(corsOptions));
  app.options('*', cors(corsOptions));

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
