/**
 * PM2 — run from the backend/ directory:
 *   pm2 start ecosystem.config.cjs --env production
 *
 * IMPORTANT (fixed 2026-08-02): this file previously declared the app as
 * `glowfit-backend` with no PORT. Next then defaulted to 3000, which the API
 * already occupies, so the process crash-looped on EADDRINUSE and never served
 * anything — while the real production admin ran under a different PM2 entry
 * named `glowfit-admin` on 3001. Deploys restarted the dead process, so the
 * live admin kept serving a stale build even though every deploy reported
 * success. Name and PORT are now explicit and must match production.
 */
module.exports = {
  apps: [
    {
      name: 'glowfit-admin',
      cwd: __dirname,
      script: 'node_modules/next/dist/bin/next',
      args: 'start',
      instances: 1,
      exec_mode: 'fork',
      autorestart: true,
      watch: false,
      max_memory_restart: '400M',
      env: {
        NODE_ENV: 'production',
        PORT: 3001,
      },
      env_production: {
        NODE_ENV: 'production',
        PORT: 3001,
      },
    },
  ],
};
