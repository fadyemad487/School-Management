# School Management Dashboard (Frontend + Backend + Supabase)

This workspace contains two separate apps:

- `frontend/`: React + Vite + TypeScript dashboard UI.
- `backend/`: Express + TypeScript API with Prisma on Supabase Postgres.

## Features implemented

- Professional landing page.
- Auth pages (Login/Register) with Supabase Email/Password.
- Google OAuth hook via Supabase.
- Protected dashboard routes.
- Core modules endpoints and pages:
  - Overview
  - Students
  - Teachers
  - Classes
  - Attendance
  - Payments
  - Announcements
- Role guard middleware in backend.
- Validation with Zod.

## Quick start

1. Copy env examples:
   - `frontend/.env.example` -> `frontend/.env`
   - `backend/.env.example` -> `backend/.env`
2. Fill Supabase values.
3. Install and run backend:
   - `cd backend`
   - `npm install`
   - `npm run prisma:generate`
   - `npm run dev`
4. Install and run frontend:
   - `cd frontend`
   - `npm install`
   - `npm run dev`

## Notes

- Backend expects JWT bearer token from Supabase session.
- Run database migrations before production usage.
