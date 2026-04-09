# Glowfit Server Setup Summary

Last updated: 2026-04-09

## Overview

This document summarizes all server setup and deployment work completed so far for Glowfit.

Server details:

- Hostname: `api-glowfit`
- OS: `Ubuntu 22.04.5 LTS`
- Public IP: `139.84.149.147`

## Completed Work

### 1. Base System Setup

Updated the server and installed core tools:

- `curl`
- `git`
- `unzip`
- `build-essential`
- `ca-certificates`
- `gnupg`

### 2. User and Access Setup

Created a non-root sudo user:

- Username: `sprsadmin`

Confirmed:

- `sprsadmin` can log in over SSH
- `sprsadmin` has `sudo` access

### 3. Firewall and Security

Configured server security:

- `ufw` enabled
- Allowed inbound:
- `22/tcp`
- `80/tcp`
- `443/tcp`
- Installed and enabled `fail2ban`
- Configured `fail2ban` SSH jail
- Confirmed `fail2ban` is actively banning SSH attack attempts

Current SSH state:

- Root SSH login is still enabled
- Password authentication is still enabled
- Root SSH hardening is still pending explicit approval

### 4. Node.js Runtime and Process Manager

Installed:

- Node.js `v24.14.1`
- npm `11.11.0`
- PM2 `6.0.14`

Configured:

- PM2 startup integration for user `sprsadmin`
- Boot service: `pm2-sprsadmin`

### 5. NGINX Setup

Installed and enabled:

- `nginx`

Configured:

- Reverse proxy from public port `80` to `127.0.0.1:3000`
- Default site removed
- Glowfit site enabled

### 6. Application Directory

Created:

- `/var/www/glowfit`

Ownership:

- User: `sprsadmin`
- Group: `sprsadmin`

### 7. Redis Setup

Installed and enabled:

- `redis-server`

Current binding:

- `127.0.0.1:6379`
- `::1:6379`

### 8. PostgreSQL Setup

Installed and enabled:

- `postgresql`
- `postgresql-contrib`

Created:

- Database: `glowfit_db`
- User: `glowfit_user`

Granted:

- Full privileges on database `glowfit_db`
- Schema privileges on schema `public`

Security state:

- PostgreSQL is configured to listen only on localhost
- Current listeners:
- `127.0.0.1:5432`
- `::1:5432`
- PostgreSQL is not exposed to the public internet

### 9. Local App-to-DB Verification

Verified from the server:

- `pg_isready` succeeds on `127.0.0.1:5432`
- `psql` login succeeds as `glowfit_user`
- Prisma-compatible DB connection works locally

### 10. Temporary Remote PostgreSQL Access Test

Attempted:

- temporarily allowing PostgreSQL access only from the current client public IP
- adding a matching `pg_hba.conf` allow rule
- opening `5432/tcp` in `ufw` only for that IP

Outcome:

- server-side PostgreSQL configuration worked
- remote TCP access still failed
- likely blocked by changing client IP and/or provider-level firewall/network controls

Final result:

- remote PostgreSQL access was closed again
- server returned to secure localhost-only PostgreSQL access

### 11. App Deployment

Local app source used:

- `F:\app\glowfit\backend`

Detected app type:

- Next.js `16.2.2`
- Prisma included
- production start command: `npm start`

Deployment steps completed:

- Packaged app locally without `.git`, `node_modules`, `.next`, or local `.env`
- Uploaded package to server
- Extracted app into `/var/www/glowfit`
- Created production `.env` on the server
- Installed dependencies with `npm ci`
- Ran `npx prisma generate`
- Built the app with `npm run build`
- Started the app with PM2 as `glowfit-backend`
- Saved PM2 process list for restart persistence

### 12. Live App Verification

Verified:

- App is running under PM2
- Port `3000` is serving the app
- DB health route works:
- `http://127.0.0.1:3000/api/health/db`
- Response: `{"ok":true,"database":"connected"}`
- NGINX is proxying correctly
- Public `/` currently redirects to `/login`

## Current Service State

Enabled on boot:

- `ssh`
- `fail2ban`
- `nginx`
- `redis-server`
- `postgresql`
- `pm2-sprsadmin`

Running:

- `ssh`
- `fail2ban`
- `nginx`
- `redis-server`
- `postgresql`
- PM2 process `glowfit-backend`

## Current App Runtime State

App process:

- PM2 name: `glowfit-backend`
- Runs as: `sprsadmin`
- Proxied through: NGINX
- Backend port: `3000`

Observed live behavior:

- `/` returns a redirect to `/login`
- `/api/health/db` reports database connected

Important app note:

- This codebase contains an internal health route, but most frontend service calls rely on `NEXT_PUBLIC_API_URL`
- The app may still need the real external API backend URL if login or data APIs are hosted separately

## Credentials and Accounts Created

### Linux User

- Username: `sprsadmin`
- Current temporary password: `J7mQ2vN8rT4yK6pL9sX3cH5z`

Notes:

- `sprs1234` was rejected by server password policy
- `Sprs@1234` was also rejected by server password policy
- A stronger temporary password was set and verified

### PostgreSQL User

- Username: `glowfit_user`
- Password: `GfDb!9rK2mQ7xV4sLp8NcT6h`
- Database: `glowfit_db`

### Root Access Used

- Root SSH login is still available
- Root password remains in use for setup tasks

## Production Environment Values Created on Server

Server app environment file was created with:

```text
NODE_ENV=production
PORT=3000
DATABASE_URL=postgresql://glowfit_user:GfDb!9rK2mQ7xV4sLp8NcT6h@127.0.0.1:5432/glowfit_db
NEXT_PUBLIC_API_URL=http://139.84.149.147/api
```

Notes:

- `DATABASE_URL` now uses local PostgreSQL on the server
- `NEXT_PUBLIC_API_URL` is currently a placeholder pointing to `/api` on this host
- If your real API is elsewhere, this value should be updated

## Important Paths

- App directory: `/var/www/glowfit`
- NGINX site config: `/etc/nginx/sites-available/glowfit`
- fail2ban config: `/etc/fail2ban/jail.local`
- PostgreSQL config: `/etc/postgresql/14/main/postgresql.conf`
- PostgreSQL host rules: `/etc/postgresql/14/main/pg_hba.conf`

## Remaining Work / Optional Next Steps

Not yet completed:

- Disable root SSH login safely
- Replace temporary `sprsadmin` password
- Update `NEXT_PUBLIC_API_URL` if the real API is not `http://139.84.149.147/api`
- Add TLS/HTTPS with a real domain and certificate
- Add backups for PostgreSQL and app data
- Add PM2 log rotation and monitoring if desired

