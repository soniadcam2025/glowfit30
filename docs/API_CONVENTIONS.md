# GlowFit 30 — API Conventions

# API Style

Architecture:
- REST API only

Base URL Example:

```text
https://api.glowfit30.com/api/v1
```

---

# Standard Success Response

```json
{
  "success": true,
  "message": "Data fetched successfully",
  "data": {}
}
```

---

# Standard Error Response

```json
{
  "success": false,
  "message": "Validation failed",
  "errors": []
}
```

---

# Pagination Response

```json
{
  "success": true,
  "message": "Users fetched successfully",
  "data": [],
  "pagination": {
    "page": 1,
    "limit": 10,
    "total": 100,
    "totalPages": 10
  }
}
```

---

# Authentication

Header:

```text
Authorization: Bearer TOKEN
```

---

# Route Naming Rules

## Use plural naming

Correct:
```text
/api/v1/users
/api/v1/workouts
```

Wrong:
```text
/api/v1/user
/api/v1/workout
```

---

# HTTP Methods

GET:
- fetch data

POST:
- create data

PUT:
- full update

PATCH:
- partial update

DELETE:
- delete data

---

# Status Codes

200:
- success

201:
- created

400:
- validation error

401:
- unauthorized

403:
- forbidden

404:
- not found

500:
- server error

---

# Pagination Rules

Default:
```text
?page=1&limit=10
```

Maximum Limit:
```text
100
```

---

# Search Rules

Search Query:
```text
?search=keyword
```

---

# Sorting Rules

```text
?sortBy=createdAt&sortOrder=desc
```

---

# File Upload Rules

Storage:
- Cloudflare R2

Allowed:
- jpg
- png
- webp
- mp4

Max Size:
- configurable via env

---

# Validation Rules

Validation Library:
- Zod or Joi

Rules:
- validate all inputs
- sanitize payloads
- reject unknown fields

---

# Authentication Rules

Access Token:
- short expiry

Refresh Token:
- long expiry

Password:
- bcrypt hashed

---

# Error Handling

Rules:
- centralized error handler
- no raw database errors
- no stack traces in production

---

# Security Rules

- helmet enabled
- cors configured
- rate limiting enabled
- SQL injection prevention
- XSS prevention

---

# Response Rules

Always include:
- success
- message
- data

Never return:
- raw DB responses
- internal errors
- stack traces

---

# API Versioning

Current:
```text
/api/v1
```

Future:
```text
/api/v2
```