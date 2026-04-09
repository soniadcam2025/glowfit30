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
