# EduControl School Management System

EduControl is a multi-tenant school management platform for managing a school's students, staff, classes, attendance, finance, communication, and daily operations from one dashboard.

**Live application:** [school-management487.vercel.app](https://school-management487.vercel.app)
**Production API health:** [Railway API health check](https://school-management-production-596f.up.railway.app/api/health)

## Contents

- [Architecture](#architecture)
- [Technology](#technology)
- [Product capabilities](#product-capabilities)
- [Authentication and registration](#authentication-and-registration)
- [Security](#security)
- [Local development](#local-development)
- [Docker environment](#docker-environment)
- [Deployment](#deployment)
- [Environment variables](#environment-variables)
- [API](#api)
- [Scaling notes](#scaling-notes)

## Architecture

```text
Browser
  |
  +-- Vercel: Next.js frontend
  |      |
  |      +-- Supabase Auth (email/password and Google OAuth)
  |
  +-- Railway: Express REST API and Socket.IO
          |
          +-- Supabase PostgreSQL via Prisma
          +-- Optional Redis cache and Socket.IO adapter
```

The frontend is a Next.js App Router application. It calls the Express API with the current Supabase bearer token. The API validates the token, resolves the current school tenant, enforces the caller's role, and accesses data through Prisma.

## Technology

| Area | Technology |
| --- | --- |
| Frontend | Next.js 16, React 19, TypeScript, React Query |
| Backend | Express 5, TypeScript, Prisma |
| Authentication | Supabase Auth, JWT, Google OAuth |
| Database | Supabase PostgreSQL |
| Real time | Socket.IO, with Redis adapter support |
| Validation | Zod |
| Local infrastructure | Docker Compose, NGINX, Redis, Jenkins |
| Production hosting | Vercel frontend and Railway backend |

## Product capabilities

The dashboard includes modules for:

- Students, admissions, parents, teachers, users, credentials, and school settings.
- Classes, subjects, academic years, timetables, schedules, homework, exams, grades, and attendance.
- Invoices, payments, fee structures, and reporting.
- Announcements, notifications, messages, transport, drivers, supervisors, behavior, leaves, and archive workflows.
- Dashboard analytics, protected school-scoped data, and live Socket.IO connections.
- English and Arabic user interfaces with light and dark themes.

## Authentication and registration

### Sign in

- Email/password authentication through Supabase.
- Optional Remember me behavior for a returning browser session.
- Google OAuth sign-in. A Google identity is accepted only when it is linked to a registered EduControl school; otherwise the user receives a clear next-step message.
- Successful Google verification gets a dedicated green verified state before dashboard navigation.
- Session reads are serialized within each browser tab to avoid Supabase Navigator Lock conflicts during React rendering and API requests.

### Register a school

1. The user enters the school details and accepts the Terms and Conditions.
2. The registration endpoint creates the school and administrator account.
3. A success animation confirms creation.
4. The dashboard preparation view resumes safely after a refresh using session storage, then runs for 30 seconds before moving to the dashboard intro flow.

The public experience also includes a branded animated 404 page, a standalone Terms and Conditions page at `/terms-and-conditions`, and a contact page at `/contact`.

## Security

Security is implemented in layers. No application can promise protection against every future vulnerability, so dependencies, Supabase policies, Railway environment variables, and logs should be reviewed regularly.

Current application protections include:

- Supabase JWT validation on protected API routes.
- Tenant scoping to keep each school's records isolated.
- Role guards for administrative and sensitive mutations.
- Exact production CORS origin allowlisting. The production frontend URL is allowed explicitly; wildcard Vercel and Netlify origins are not used.
- Helmet security headers, HSTS in production, restrictive frame embedding, and disabled API response caching for authenticated responses.
- Request body size limits and structured API errors.
- Login throttling by IP address and normalized email. Only failed attempts count; a successful login clears that account's failed-attempt count.
- Rate limits on public availability checks used during school registration.
- Protected invoice mutations and removal of the legacy unauthenticated registration webhook.
- Sanitized server logging to avoid leaking secrets or tokens.
- Current frontend production dependency audit has no reported vulnerabilities.

### Required production checks

- Keep `SUPABASE_SERVICE_ROLE_KEY`, `SUPABASE_JWT_SECRET`, database URLs, and other secrets only in Railway environment variables. Never expose them in frontend variables or commit them to Git.
- Enable and verify Supabase Row Level Security policies for every table and Storage bucket that is accessed directly from a client.
- Set `FRONTEND_URL` on Railway to the exact deployed frontend URL. Multiple explicit origins can be comma-separated when needed.
- Rotate credentials immediately if a secret is ever exposed.

## Local development

### Prerequisites

- Node.js 20 or newer
- npm
- A Supabase project

### Backend

```bash
cd backend
cp .env.example .env
npm install
npm run prisma:generate
npm run dev
```

The API starts on `http://localhost:5001` by default.

### Frontend

```bash
cd frontend
cp .env.example .env
npm install
npm run dev
```

The frontend starts on `http://localhost:3000` by default.

### Verification

```bash
cd backend
npm run build

cd ../frontend
npm run build
```

## Docker environment

The root `docker-compose.yml` starts five local services:

| Service | Purpose | Port |
| --- | --- | --- |
| `redis` | Cache and Socket.IO Pub/Sub | 6379 |
| `backend` | Express API and Socket.IO | 5001 |
| `frontend` | Next.js application | 3000 |
| `nginx` | Local reverse proxy | 80 |
| `jenkins` | Optional local CI server | 8080 |

```bash
docker compose up -d
docker compose logs -f
docker compose down
```

NGINX routes `/api/*` and `/socket.io/*` to the backend and all other paths to the frontend. It provides gzip compression, WebSocket upgrades, and keepalive connections for this local Compose environment.

## Deployment

### Frontend: Vercel

The Next.js frontend is deployed from GitHub to Vercel. Pushing a frontend change to the configured production branch triggers an automatic deployment.

Required frontend environment variables:

```env
NEXT_PUBLIC_API_URL=https://school-management-production-596f.up.railway.app/api
NEXT_PUBLIC_SUPABASE_URL=https://YOUR_PROJECT.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=YOUR_SUPABASE_PUBLISHABLE_KEY
```

`NEXT_PUBLIC_*` values are visible in the browser by design. They must never contain service-role keys, database URLs, JWT secrets, or private API keys.

### Backend: Railway

The Express backend is deployed from GitHub to Railway. A push triggers Railway's configured build and deployment process.

Required backend environment variables:

```env
NODE_ENV=production
PORT=5001
FRONTEND_URL=https://school-management487.vercel.app
DATABASE_URL=YOUR_SUPABASE_POOLED_DATABASE_URL
DIRECT_URL=YOUR_SUPABASE_DIRECT_DATABASE_URL
SUPABASE_URL=https://YOUR_PROJECT.supabase.co
SUPABASE_ANON_KEY=YOUR_SUPABASE_PUBLISHABLE_KEY
SUPABASE_SERVICE_ROLE_KEY=YOUR_PRIVATE_SERVICE_ROLE_KEY
SUPABASE_JWT_SECRET=YOUR_PRIVATE_JWT_SECRET
REDIS_URL=OPTIONAL_REDIS_CONNECTION_URL
OPENROUTER_API_KEY=OPTIONAL_PRIVATE_AI_KEY
```

The backend refuses to start in production when `SUPABASE_JWT_SECRET` is missing or uses an insecure development fallback.

## Environment variables

Use `backend/.env.example` and `frontend/.env.example` as the local setup templates. Do not copy live values into this README or commit `.env` files.

## API

API base URL in production:

```text
https://school-management-production-596f.up.railway.app/api
```

Useful public endpoints:

| Method | Endpoint | Purpose |
| --- | --- | --- |
| `GET` | `/api/health` | Backend health check |
| `POST` | `/api/auth/login` | Email/password login |
| `POST` | `/api/auth/register` | School registration |
| `GET` | `/api/auth/me` | Authenticated user and school profile |

Most business endpoints require `Authorization: Bearer <Supabase access token>`. The API applies the authenticated user's tenant and role permissions before serving school data.

## Scaling notes

Vercel distributes frontend assets through its platform CDN. The current Railway backend deployment should be treated as a single application instance unless replicas are explicitly configured in Railway.

This repository contains Kubernetes manifests and HPA definitions for a future multi-replica deployment, plus Redis support for distributed Socket.IO. Those files are not the same thing as an active Railway load-balanced deployment.

Before horizontally scaling the backend, configure a shared Redis service, enable the Redis Socket.IO adapter, and move rate limiting to a shared Redis-backed store so limits apply consistently across all replicas.

## License

ISC

Built by [Fady Emad](https://github.com/fadyemad487).
