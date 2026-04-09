# GlowFit API

## Local SSH Tunnel + DB Test

### 1) Run DB tunnel
- Double-click `start-db-tunnel.bat`
- Or use `start-db-tunnel-keepalive.bat` for long sessions

### 2) Configure local DB URL
Set `DATABASE_URL` in `.env` to:

`postgresql://glowfit_user:<db_password>@127.0.0.1:5433/glowfit_db`

### 3) Start backend API
`npm run dev`

### 4) Test DB connection
`npm run db:test`

## Notes
- `.env` is ignored by git.
- Do not hardcode DB credentials in code.

## CORS: local admin → production API (`https://api.glowfit30.com`)

**Live production login** (`https://admin.glowfit30.com` → `https://api.glowfit30.com`) only requires `CORS_ORIGINS` to include `https://admin.glowfit30.com` (default). You do **not** need `CORS_ALLOW_LOCAL_DEV` on the server for that.

If the browser shows **No Access-Control-Allow-Origin** when using **local** Next (`http://localhost:3001`) against the **production** API, add **one** of:

1. Comma-separated extra origins in `CORS_ORIGINS`, e.g.  
   `https://admin.glowfit30.com,http://localhost:3001,http://127.0.0.1:3001`

2. Or set `CORS_ALLOW_LOCAL_DEV=true` (only if you accept localhost calling prod API during development).

Then restart PM2 / the API process.
