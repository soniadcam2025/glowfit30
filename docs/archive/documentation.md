# GlowFit - Project Documentation

**Status:** Active Development | **Last Updated:** May 23, 2026

---

## 📋 Project Overview

GlowFit is a full-stack web application for fitness and wellness management. It consists of three main components:
- **API** - Express.js backend with database integration
- **Backend/Admin UI** - Next.js admin dashboard
- **Server** - VPS deployment configuration

---

## 🗂️ Project Structure

```
glowfit/
├── api/                 # Express API backend
├── backend/             # Next.js admin dashboard
├── server/              # VPS & deployment setup
└── docs/               # Documentation
```

---

## 🔧 Components Built

### 1. **API Backend** (`/api`)
**Stack:** Node.js + Express | Prisma ORM | PostgreSQL | Redis

**Features:**
- User authentication & authorization (JWT)
- Admin management
- Rate limiting & security (Helmet, CORS)
- Database migrations & seeding
- Modular architecture with separate feature modules

**Modules:**
- `auth` - User login, registration, token management
- `users` - User profile management
- `workouts` - Workout tracking & management
- `diet` - Nutritional tracking
- `beauty` - Beauty-related features
- `analytics` - Data analytics & reporting
- `admin` - Admin panel operations

**Database:** PostgreSQL with Prisma ORM v6.19.3

---

### 2. **Admin Dashboard** (`/backend`)
**Stack:** Next.js 16 | React 19 | TypeScript | Tailwind CSS

**UI Features:**
- Dark/Light mode support
- Animated Lottie loaders
- Framer Motion animations
- Recharts data visualization
- Responsive design with Tailwind CSS

**Pages Implemented:**
- `/login` - Admin authentication
- `/dashboard` - Main dashboard overview
- `/users` - User management
- `/workouts` - Workout management
- `/diet` - Diet management  
- `/beauty` - Beauty features management
- `/notifications` - System notifications
- `/settings` - Admin settings

**Authentication:** Cookie-based auth via Next.js proxy with API

---

### 3. **Server Deployment** (`/server`)
**Stack:** Nginx | Let's Encrypt SSL | PM2 | Bash Scripts

**Configuration:**
- Nginx reverse proxy for subdomains (admin.glowfit30.com, api.glowfit30.com)
- Automated SSL/TLS setup with Let's Encrypt
- PM2 process management for both API and Next.js
- Database SSH tunnel for local development

**Setup Scripts:**
- `setup-subdomains.sh` - Automated domain & SSL configuration
- `deploy.sh` - Deployment automation

---

## 📦 Key Dependencies

### API
- `@prisma/client` - ORM for database
- `express` - Web framework
- `jsonwebtoken` - JWT authentication
- `bcryptjs` - Password hashing
- `ioredis` - Redis client
- `helmet` - Security middleware
- `zod` - Validation

### Backend
- `next` - React framework
- `react-query` - Server state management
- `axios` - HTTP client
- `framer-motion` - Animations
- `lottie-react` - Animations library
- `recharts` - Data visualization
- `tailwindcss` - Styling

---

## 🎯 Work Completed

✅ **Project Setup**
- Monorepo structure initialized
- API, Backend, and Server folders configured
- Git repository and version control setup

✅ **Authentication System**
- JWT-based API authentication
- Cookie-based admin auth
- Admin user seeding scripts
- CORS configuration for local dev and production

✅ **Database**
- PostgreSQL schema design
- Prisma migrations and seeding
- Database connection tunnel setup
- SSH tunnel for local development

✅ **Admin Dashboard UI**
- Login page with Lottie animations
- Dashboard with analytics
- User management interface
- Workout management interface
- Diet management interface
- Beauty features interface
- Settings page
- Notifications panel

✅ **API Endpoints**
- Core modules for auth, users, workouts, diet, beauty, analytics
- Rate limiting and security headers
- Error handling and validation
- Production CORS configuration

✅ **Deployment Setup**
- Nginx subdomain configuration
- SSL/TLS automation scripts
- PM2 process management
- VPS deployment documentation

---

## 🚀 Latest Features

- Lottie loader animations on admin UI
- DotLottie integration for optimized animations
- Cookie-based authentication proxy in Next.js
- CORS flexibility for local development vs. production
- Admin panel with complete CRUD operations

---

## 📝 Recent Commits

- `fc1ii` - (Latest)
- `fc1i`
- `fc1`
- Lottie loaders and login DotLottie strip
- Same-origin token cookie via Next auth proxy
- Optional CORS for local dev vs prod
- Cookie authentication implementation
- Backend files tracking in monorepo
- Initial project setup

---

## 🌐 Deployment Status

**Domains:**
- Admin: `https://admin.glowfit30.com`
- API: `https://api.glowfit30.com`
- VPS IP: `139.84.149.147`

**Setup Required:**
1. SSH tunnel for local DB development
2. PM2 process management on VPS
3. Certbot SSL certificate generation
4. Nginx configuration for subdomains

---

## 📖 Environment Variables

### API (`.env`)
```
DATABASE_URL=postgresql://user:pass@localhost:5433/glowfit_db
REDIS_URL=redis://localhost:6379
CORS_ORIGINS=https://admin.glowfit30.com
JWT_SECRET=your_secret_key
```

### Backend (`.env.local`)
```
NEXT_PUBLIC_API_URL=https://api.glowfit30.com
```

---

## 🛠️ Development Commands

### API
```bash
npm run dev           # Start development server
npm run db:migrate    # Run database migrations
npm run db:push       # Push schema to database
npm run seed:admin    # Seed admin user
```

### Backend
```bash
npm run dev           # Start Next.js dev server
npm run build         # Build for production
npm run start         # Start production server
```

---

## 🔐 Security Features

- ✅ CORS protection
- ✅ Rate limiting (express-rate-limit)
- ✅ Security headers (Helmet)
- ✅ Password hashing (bcryptjs)
- ✅ JWT token validation
- ✅ Environment variable protection
- ✅ HTTPS/SSL enforcement

---

## 📊 Project Statistics

- **Total Commits:** 10+
- **API Modules:** 7
- **Admin Pages:** 8
- **Stack Layers:** 3 (API, Frontend, Infrastructure)
- **Tech Stack:** MERN-like with Next.js

---

## 🎯 Next Steps

- [ ] Deploy to production VPS
- [ ] Complete SSL certificate setup
- [ ] Database production migration
- [ ] User testing and QA
- [ ] Analytics dashboard finalization
- [ ] Mobile app consideration

---

**Project Repository:** `F:\app\glowfit`  
**Primary Branch:** `main`  
**Git Status:** Clean ✓
