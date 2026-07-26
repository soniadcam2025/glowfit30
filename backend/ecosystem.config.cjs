/** PM2 — run from the backend/ directory: pm2 start ecosystem.config.cjs --env production */
module.exports = {
  apps: [
    {
      name: 'glowfit-backend',
      cwd: __dirname,
      script: 'node_modules/next/dist/bin/next',
      args: 'start',
      instances: 1,
      exec_mode: 'fork',
      autorestart: true,
      watch: false,
      max_memory_restart: '400M',
      env_production: {
        NODE_ENV: 'production',
      },
    },
  ],
};
