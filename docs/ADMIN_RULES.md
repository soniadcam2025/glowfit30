# GlowFit 30 — Admin Panel Rules

# Admin Stack

Frontend:
- Next.js
- Tailwind CSS
- Zustand
- React Query
- Axios

UI Goals:
- ultra responsive
- mobile friendly
- modern dashboard UX
- scalable admin architecture

---

# Admin Architecture Rules

Use:
- modular structure
- reusable components
- centralized API services
- reusable hooks

Do NOT:
- place business logic inside UI pages
- create giant pages
- duplicate dashboard components

---

# Folder Structure

```text
/backend/src
   ├── app
   ├── components
   ├── hooks
   ├── services
   ├── store
   ├── utils
   └── styles
```

---

# Component Rules

Create reusable components for:
- tables
- cards
- modals
- buttons
- filters
- forms
- loaders
- pagination
- search bars

Avoid duplicate UI code.

---

# Dashboard UI Rules

Design:
- clean
- premium
- modern
- soft shadows
- rounded cards
- responsive layouts

Support:
- desktop
- tablet
- mobile browser

---

# Responsive Rules

Admin panel must work properly on:
- laptop
- tablet
- mobile

Rules:
- responsive grids
- collapsible sidebar
- adaptive tables
- avoid fixed widths

---

# Sidebar Rules

Sidebar should:
- collapse on mobile
- support icons + labels
- remain reusable

Sections:
- Dashboard
- Users
- Workouts
- Diet
- Beauty
- Notifications
- Subscriptions
- Analytics
- Settings

---

# State Management Rules

Use:
- Zustand

Use React Query for:
- API caching
- server state
- mutations

Avoid:
- unnecessary global states

---

# API Rules

Use:
- centralized axios instance

Features:
- auth token handling
- refresh token support
- interceptor support

Never:
- call APIs directly inside UI components

---

# Page Rules

Pages should:
- remain lightweight
- use reusable components
- use hooks/services

Avoid:
- large page files
- duplicated tables/forms

---

# Table Rules

All tables should support:
- pagination
- search
- filters
- loading state
- empty state

Use reusable table components.

---

# Form Rules

Use:
- reusable form components
- validation
- loading states

Always:
- validate inputs
- show error messages
- disable submit during request

---

# Authentication Rules

Admin authentication:
- JWT based
- protected routes
- role-based access

Never:
- expose sensitive admin routes publicly

---

# Loading Rules

Use:
- skeleton loaders
- Lottie loaders
- button loading states

Avoid:
- blank white screens

---

# Notification Rules

Support:
- push notifications
- in-app notifications
- notification history

---

# Analytics Rules

Dashboard should support:
- charts
- user stats
- revenue stats
- workout analytics
- retention analytics

Optimize:
- API calls
- chart rendering

---

# Security Rules

Must Have:
- protected routes
- auth middleware
- secure token storage
- role permissions

Never:
- expose secrets
- trust frontend validation

---

# Performance Rules

Optimize:
- lazy loading
- pagination
- code splitting
- API caching

Avoid:
- unnecessary rerenders
- oversized components

---

# Styling Rules

Use:
- Tailwind CSS only

Design System:
- rounded corners
- soft shadows
- premium dashboard feel
- consistent spacing

Avoid:
- inconsistent colors
- random padding/margins

---

# Dark Mode Rules

Prepare architecture for:
- dark mode
- theme switching

Keep:
- centralized colors
- reusable classes

---

# Naming Rules

Use:
- camelCase for variables
- PascalCase for components
- clear file names

Examples:
```text
UserTable.jsx
WorkoutCard.jsx
NotificationModal.jsx
```

---

# Error Handling Rules

Always:
- handle API failures
- show user-friendly errors
- handle session expiry

Never:
- expose raw backend errors

---

# Deployment Rules

Development:
- localhost using Cursor + Claude AI

Deployment:
- GitHub push
- VPS pull
- build
- PM2 restart

Never:
- edit production files directly unless urgent

---

# Coding Philosophy

Goals:
- maintainable
- scalable
- responsive
- reusable
- production-grade admin system

Focus:
- clean UX
- fast workflows
- admin productivity
- mobile responsiveness