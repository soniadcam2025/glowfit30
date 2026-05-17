# GlowFit 30 — Flutter Rules

# Flutter Stack

- Flutter
- GetX
- Dio
- SharedPreferences
- Firebase Messaging

---

# Architecture Rules

Use:
- modular architecture
- reusable widgets
- centralized theme
- service layer pattern

Do NOT:
- place business logic inside UI
- create giant screens
- duplicate widgets

---

# Folder Structure

```text
/lib
   ├── core
   ├── modules
   ├── services
   ├── routes
   ├── widgets
   └── main.dart
```

---

# Module Structure

Each module should contain:

```text
module/
   ├── bindings
   ├── controllers
   ├── models
   ├── services
   ├── views
   └── widgets
```

---

# State Management Rules

Use:
- GetX only

Rules:
- keep controllers lightweight
- separate business logic
- avoid unnecessary rebuilds

---

# API Rules

HTTP Client:
- Dio

Rules:
- centralized API service
- interceptors for auth
- standardized error handling

---

# UI Rules

Design Style:
- feminine
- soft premium UI
- smooth animations

Use:
- rounded corners
- gradients
- glassmorphism
- micro animations

---

# Responsive Rules

Support:
- Android
- iOS
- tablets

Rules:
- responsive sizing
- avoid fixed widths
- scalable layouts

---

# Theme Rules

Use:
- centralized theme system

Support:
- light mode
- dark mode

Colors:
- soft pink
- white
- black
- gradient pink

---

# Widget Rules

Create reusable widgets for:
- buttons
- cards
- loaders
- headers
- bottom sheets
- dialogs

Avoid duplicate UI code.

---

# Navigation Rules

Use:
- GetX routing

Centralize:
- route names
- middleware
- auth guards

---

# Performance Rules

Optimize:
- image caching
- pagination
- lazy loading
- rebuilds

Use:
- cached_network_image

Avoid:
- unnecessary setState
- heavy widget trees

---

# Storage Rules

Use:
- SharedPreferences for lightweight storage

Examples:
- auth token
- onboarding state
- theme mode

---

# Notification Rules

Use:
- Firebase Messaging

Support:
- push notifications
- foreground notifications
- background notifications

---

# Animation Rules

Use:
- smooth transitions
- lightweight animations
- Lottie where necessary

Avoid:
- excessive animations
- laggy UI effects

---

# Security Rules

Never:
- store secrets in app
- hardcode API keys

Use:
- environment configs

---

# Coding Style Rules

Use:
- clean naming
- reusable widgets
- service-based architecture

Keep:
- screens lightweight
- widgets modular

---

# API Integration Rules

Always:
- handle loading states
- handle errors
- handle empty states

Never:
- trust API blindly

---

# Offline Rules

Support:
- cached workouts
- cached diet plans
- offline progress tracking

Future:
- sync when online

---

# Development Workflow

Development:
- localhost using Cursor + Claude AI

Deployment:
- GitHub repository
- CI/CD later

Server:
- Vultr VPS backend APIs