# GlowFit 30 — Backend Rules

# Backend Stack

- Node.js
- Express.js
- PostgreSQL
- Prisma ORM
- Redis

---

# Architecture Rules

Use:
- modular architecture
- service layer pattern
- reusable middleware
- centralized error handling

Do NOT:
- place business logic inside routes
- create giant controllers
- duplicate logic

---

# Folder Rules

Every module should contain:

```text
module/
   ├── controller.js
   ├── service.js
   ├── routes.js
   ├── validation.js
   └── index.js
```

---

# Route Rules

Routes should:
- remain lightweight
- only call controller functions

No business logic inside routes.

---

# Controller Rules

Controllers should:
- handle request/response only
- call services
- return standardized responses

Keep controllers clean.

---

# Service Rules

Services should:
- contain business logic
- contain database queries
- remain reusable

---

# Prisma Rules

Use:
- Prisma ORM only

Rules:
- use relations properly
- avoid unnecessary queries
- use pagination
- optimize includes/selects

Do NOT:
- use raw SQL unless required

---

# Database Rules

Use:
- PostgreSQL

Rules:
- use indexes where necessary
- avoid N+1 queries
- normalize data properly

---

# Redis Rules

Use Redis for:
- caching
- OTP storage
- sessions
- rate limiting
- queues

Do NOT:
- store permanent business data

---

# Validation Rules

Validation:
- required for every endpoint

Libraries:
- Zod or Joi

Never trust frontend validation.

---

# Authentication Rules

Use:
- JWT access token
- refresh token
- bcrypt password hashing

Never:
- store plain passwords
- expose sensitive data

---

# Environment Rules

Use:
- .env files

Never:
- hardcode secrets
- commit secrets to GitHub

---

# Logging Rules

Use:
- structured logging

Log:
- errors
- auth attempts
- admin actions

Never:
- log passwords
- log sensitive tokens

---

# API Rules

Use:
- standardized API responses
- pagination everywhere
- proper HTTP status codes

---

# Security Rules

Must Have:
- Helmet
- CORS
- Rate Limiting
- Input Validation
- SQL Injection Protection

---

# Performance Rules

Optimize:
- queries
- payload size
- pagination
- image loading

Avoid:
- unnecessary database calls
- huge API responses

---

# Coding Style Rules

Use:
- async/await
- camelCase naming
- reusable helpers

Keep:
- files small
- code readable
- modules isolated

---

# Deployment Rules

Deployment Flow:
- localhost development
- git push
- VPS git pull
- PM2 restart

Never:
- edit production manually unless urgent

---

# PM2 Rules

Use PM2 for:
- API runtime
- process monitoring
- auto restart

---

# Git Rules

Commit Messages:
- clear and short

Example:
```text
add notifications module
fix auth refresh token
```

Avoid:
```text
final fix
updated files
```