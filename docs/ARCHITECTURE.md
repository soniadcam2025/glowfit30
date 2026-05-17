# GlowFit 30 — Project Architecture

## Project Overview

GlowFit 30 is a scalable fitness + beauty platform consisting of:

- Flutter mobile application
- Express.js backend API
- Next.js admin dashboard
- PostgreSQL database
- Redis caching layer
- Vultr VPS infrastructure

The platform focuses on:
- workouts
- beauty routines
- diet plans
- progress tracking
- subscriptions
- gamification
- AI-driven recommendations

---

# Infrastructure

## Production Environment

Provider:
- Vultr Cloud Compute

Server Stack:
- Ubuntu 22.04
- NGINX
- PM2
- Node.js
- PostgreSQL
- Redis

---

# Application Structure

```text
/glowfit
   ├── api
   ├── backend
   ├── mobile
   ├── docs
```

---

# Backend Architecture

Technology:
- Node.js
- Express.js
- Prisma ORM
- PostgreSQL
- Redis

Pattern:
- modular architecture
- controller/service/routes pattern
- centralized error handling
- reusable validation
- standardized responses

Structure:

```text
/api/src
   ├── modules
   │    ├── auth
   │    ├── users
   │    ├── workouts
   │    ├── diet
   │    ├── beauty
   │    ├── progress
   │    ├── notifications
   │    ├── subscriptions
   │    └── analytics
   │
   ├── middleware
   ├── utils
   ├── config
   ├── prisma
   └── app.js
```

---

# Admin Panel Architecture

Technology:
- Next.js
- Tailwind CSS
- Zustand
- React Query

Goals:
- mobile responsive
- reusable components
- admin-first UX
- fast loading
- scalable pages

---

# Flutter Mobile Architecture

Technology:
- Flutter
- GetX
- Dio
- SharedPreferences
- Firebase Messaging

Architecture:
- modular structure
- reusable widgets
- service-based API layer
- repository pattern
- centralized theme management

Structure:

```text
/mobile/lib
   ├── core
   ├── modules
   ├── routes
   ├── services
   ├── widgets
   └── main.dart
```

---

# Authentication System

Authentication Type:
- JWT access token
- refresh token
- bcrypt password hashing

Future:
- social login
- OTP login
- Firebase Auth integration

---

# Database

Primary Database:
- PostgreSQL

Cache Layer:
- Redis

ORM:
- Prisma

---

# Deployment Strategy

Development:
- localhost using Cursor + Claude AI

Version Control:
- GitHub

Deployment:
- git push
- server pull
- rebuild
- PM2 restart

---

# Core Modules

## Backend Modules

- auth
- users
- workouts
- diet
- beauty
- progress
- notifications
- subscriptions
- analytics

---

# Media Storage

Storage:
- Cloudflare R2

Media Types:
- workout videos
- progress photos
- beauty content
- banners

---

# API Architecture

Style:
- REST API

Rules:
- standardized responses
- pagination mandatory
- token-based auth
- role-based permissions

---

# Coding Philosophy

- scalable architecture
- modular development
- reusable logic
- low server memory usage
- mobile-first UX
- clean production code

---

# Current Development Workflow

Local Development:
- Cursor IDE
- Claude AI extension

Remote Server:
- Remote SSH window

Deployment:
- GitHub push
- VPS pull
- PM2 restart