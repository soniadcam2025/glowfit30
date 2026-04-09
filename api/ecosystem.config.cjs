/** PM2 — run from repo root: pm2 start ecosystem.config.cjs --env production */
module.exports = {
  apps: [
    {
      name: 'glowfit-api',
      cwd: __dirname,
      script: 'src/index.js',
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
