<div align="center">

# 🏫 WeCircle — School Management System

<p>
  <img src="https://img.shields.io/badge/Next.js-16-black?style=for-the-badge&logo=next.js" alt="Next.js" />
  <img src="https://img.shields.io/badge/Express-5-000?style=for-the-badge&logo=express" alt="Express" />
  <img src="https://img.shields.io/badge/TypeScript-5.9-3178C6?style=for-the-badge&logo=typescript" alt="TypeScript" />
  <img src="https://img.shields.io/badge/Prisma-6.17-2D3748?style=for-the-badge&logo=prisma" alt="Prisma" />
  <img src="https://img.shields.io/badge/Supabase-PostgreSQL-3FCF8E?style=for-the-badge&logo=supabase" alt="Supabase" />
</p>
<p>
  <img src="https://img.shields.io/badge/Docker-Compose-2496ED?style=for-the-badge&logo=docker" alt="Docker" />
  <img src="https://img.shields.io/badge/Kubernetes-1.36-326CE5?style=for-the-badge&logo=kubernetes" alt="Kubernetes" />
  <img src="https://img.shields.io/badge/NGINX-Reverse_Proxy-009639?style=for-the-badge&logo=nginx" alt="NGINX" />
  <img src="https://img.shields.io/badge/Redis-7-DC382D?style=for-the-badge&logo=redis" alt="Redis" />
  <img src="https://img.shields.io/badge/Jenkins-CI/CD-D24939?style=for-the-badge&logo=jenkins" alt="Jenkins" />
</p>

**A comprehensive, enterprise-grade school management platform with real-time features, multi-tenant architecture, and full DevOps infrastructure.**

[Live Demo](https://school-management487.vercel.app) · [API Health](https://school-management487.vercel.app/api/health)

</div>

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Tech Stack](#-tech-stack)
- [Features & Modules](#-features--modules)
- [Project Structure](#-project-structure)
- [Quick Start (Development)](#-quick-start-development)
- [Docker Deployment](#-docker-deployment)
- [Kubernetes Deployment](#-kubernetes-deployment)
- [NGINX Reverse Proxy](#-nginx-reverse-proxy)
- [Redis Integration](#-redis-integration)
- [Jenkins CI/CD](#-jenkins-cicd)
- [API Endpoints](#-api-endpoints)
- [Git Workflow & Safety](#-git-workflow--safety)
- [Environment Variables](#-environment-variables)
- [Useful Commands](#-useful-commands)

---

## 🌟 Overview

WeCircle is a full-featured school management system built for real-world production use. It provides a beautiful dashboard for managing students, teachers, classes, attendance, payments, exams, and much more — all in real-time with WebSocket support.

The project follows a modern microservices-inspired architecture with:
- **Frontend**: Next.js 16 (React 19) with App Router
- **Backend**: Express 5 REST API with Prisma ORM
- **Database**: Supabase PostgreSQL (cloud-hosted)
- **Real-time**: Socket.IO with Redis adapter for distributed WebSockets
- **Infrastructure**: Docker, Kubernetes, NGINX, Redis, Jenkins

---

## 🛠 Tech Stack

### Application Layer

| Technology | Version | Purpose |
|------------|---------|---------|
| **Next.js** | 16.x | Frontend framework (React 19, App Router) |
| **Express** | 5.x | Backend REST API framework |
| **TypeScript** | 5.9 | Type safety across frontend & backend |
| **Prisma** | 6.17 | Database ORM & migrations |
| **Supabase** | — | PostgreSQL database + Auth (JWT) |
| **Socket.IO** | 4.8 | Real-time WebSocket communication |
| **Zod** | 4.x | Request validation & schema definition |
| **React Query** | 5.x | Server state management & caching |
| **Google Generative AI** | — | AI-powered features |

### Infrastructure Layer

| Technology | Version | Purpose |
|------------|---------|---------|
| **Docker** | Desktop | Containerization of all services |
| **Docker Compose** | v2 | Multi-container orchestration (5 services) |
| **Kubernetes** | 1.36.1 | Container orchestration & auto-scaling |
| **NGINX** | Alpine | Reverse proxy, load balancing, gzip |
| **Redis** | 7 Alpine | In-memory cache, Pub/Sub, session store |
| **Jenkins** | LTS JDK17 | CI/CD automation pipeline |

---

## 🎯 Features & Modules

### 🔐 Authentication & Authorization
- Supabase Email/Password authentication
- Google OAuth integration
- JWT-based API protection
- Role-based access control (Admin, Teacher, Parent, Student)
- Role guard middleware

### 📊 Dashboard Modules

| Module | Description |
|--------|-------------|
| 📈 **Overview** | Dashboard analytics & statistics |
| 👨‍🎓 **Students** | Student enrollment, profiles, records |
| 👨‍🏫 **Teachers** | Teacher management & assignments |
| 👨‍👩‍👧 **Parents** | Parent profiles & communication |
| 🏫 **Classes** | Class creation & management |
| 📚 **Subjects** | Subject catalog & assignments |
| 📅 **Attendance** | Daily attendance tracking |
| 💰 **Payments** | Fee management & invoicing |
| 📝 **Exams** | Exam scheduling & management |
| 📊 **Grades & Results** | Grade recording & report cards |
| 📢 **Announcements** | School-wide announcements |
| 💬 **Messages & Chat** | Real-time messaging system |
| 📋 **Homework** | Assignment distribution & tracking |
| 🗓 **Timetable** | Class schedule management |
| 📆 **Schedules** | Event & activity scheduling |
| 🎓 **Academic Years** | Academic year & term management |
| 📝 **Admissions** | Student admission workflow |
| 🚌 **Transport** | Bus routes & driver management |
| 🚗 **Drivers** | Driver profiles & assignments |
| 👔 **Supervisors** | Supervisor management |
| 📊 **Reports** | Analytics & reporting |
| 💵 **Expenses** | School expense tracking |
| 🏅 **Behavior** | Student behavior tracking |
| 🏖 **Leaves** | Leave request management |
| 🔔 **Notifications** | Push notifications |
| 🔑 **Credentials** | Credential management |
| 📦 **Archive** | Data archival |
| ⚙️ **Settings** | System configuration |
| 👥 **Users** | User management |

### ⚡ Real-time Features
- Live WebSocket connections via Socket.IO
- Redis-backed distributed pub/sub
- School-based room isolation for multi-tenancy
- Real-time notifications and chat

---

## 📁 Project Structure

```
dashboard/
├── frontend/                    # Next.js 16 Frontend
│   ├── src/
│   │   ├── app/                 # App Router pages
│   │   │   ├── dashboard/       # All dashboard modules
│   │   │   ├── login/           # Auth pages
│   │   │   ├── register/
│   │   │   └── layout.tsx
│   │   ├── components/          # Reusable UI components
│   │   ├── lib/                 # Utilities & API clients
│   │   └── types/               # TypeScript type definitions
│   ├── Dockerfile               # Multi-stage production build
│   ├── .dockerignore
│   └── next.config.mjs          # Standalone output mode
│
├── backend/                     # Express 5 Backend API
│   ├── src/
│   │   ├── routes/modules/      # 30+ API route modules
│   │   ├── config/
│   │   │   ├── websocket.ts     # Socket.IO + Redis adapter
│   │   │   ├── redis.ts         # Redis client with fallback
│   │   │   └── env.ts           # Environment config
│   │   ├── middlewares/         # Auth, rate limit, error handling
│   │   ├── cron/                # Scheduled tasks
│   │   └── server.ts            # App entry point
│   ├── prisma/                  # Database schema & migrations
│   ├── Dockerfile               # Multi-stage production build
│   ├── .dockerignore
│   └── deploy/                  # Deployment configs (source of truth)
│       ├── docker-compose.yml
│       ├── Jenkinsfile
│       ├── nginx/nginx.conf
│       └── k8s/                 # Kubernetes manifests
│           ├── backend.yaml
│           ├── frontend.yaml
│           ├── redis.yaml
│           ├── hpa.yaml
│           └── secrets.yaml     # ⚠️ gitignored
│
├── docker-compose.yml           # Root compose file (5 services)
├── Jenkinsfile                  # CI/CD pipeline definition
├── nginx/nginx.conf             # NGINX reverse proxy config
├── k8s/                         # Kubernetes manifests (root copy)
│   ├── backend.yaml
│   ├── frontend.yaml
│   ├── redis.yaml
│   └── hpa.yaml
└── README.md
```

---

## 🚀 Quick Start (Development)

### Prerequisites
- Node.js 20+
- npm
- Supabase account & project

### 1. Clone & Setup

```bash
git clone https://github.com/fadyemad487/School-Management.git
cd School-Management
```

### 2. Backend Setup

```bash
cd backend
cp .env.example .env    # Fill in your Supabase credentials
npm install
npm run prisma:generate
npm run dev              # Starts on http://localhost:5001
```

### 3. Frontend Setup

```bash
cd frontend
cp .env.example .env    # Fill in your Supabase credentials
npm install
npm run dev              # Starts on http://localhost:3000
```

---

## 🐳 Docker Deployment

### Architecture

```
                    ┌─────────────────────────┐
                    │      NGINX (:80)        │
                    │    Reverse Proxy         │
                    └────┬──────────┬──────────┘
                         │          │
              ┌──────────┘          └──────────┐
              ▼                                ▼
    ┌──────────────────┐            ┌──────────────────┐
    │  Backend (:5001) │            │ Frontend (:3000) │
    │  Express API     │            │  Next.js SSR     │
    └────────┬─────────┘            └──────────────────┘
             │
    ┌────────▼─────────┐            ┌──────────────────┐
    │  Redis (:6379)   │            │ Jenkins (:8080)  │
    │  Cache & Pub/Sub │            │   CI/CD Server   │
    └──────────────────┘            └──────────────────┘
```

### Services

| Service | Image | Port | Description |
|---------|-------|------|-------------|
| `school_redis` | `redis:7-alpine` | 6379 | In-memory cache & pub/sub |
| `school_backend` | Custom build | 5001 | Express REST API |
| `school_frontend` | Custom build | 3000 | Next.js standalone |
| `school_nginx` | `nginx:alpine` | 80 | Reverse proxy & gateway |
| `school_jenkins` | `jenkins/jenkins:lts-jdk17` | 8080 | CI/CD automation |

### Run with Docker Compose

```bash
# Start all 5 services
docker compose up -d

# Check status
docker ps

# View logs
docker compose logs -f

# Check resource usage
docker stats --no-stream

# Stop everything
docker compose down
```

### Build Images Separately

```bash
# Build backend image
docker build -t school-backend:latest ./backend

# Build frontend image
docker build -t school-frontend:latest ./frontend
```

---

## ☸️ Kubernetes Deployment

### Prerequisites
- Docker Desktop with Kubernetes enabled
- `kubectl` configured

### Cluster Setup

The project uses Docker Desktop's built-in Kubernetes (kind cluster):
- **Node:** `desktop-control-plane`
- **Version:** v1.36.1
- **Context:** `docker-desktop`

### Deployments

| Deployment | Replicas | CPU Limit | Memory Limit | Auto-Scale |
|-----------|----------|-----------|--------------|------------|
| `backend-deployment` | 2 | 500m | 512Mi | 2→6 (70% CPU) |
| `frontend-deployment` | 2 | 500m | 512Mi | 2→6 (70% CPU) |
| `redis-deployment` | 1 | 250m | 256Mi | — |

### Deploy to Kubernetes

```bash
# Apply all manifests
kubectl apply -f k8s/

# Check pods
kubectl get pods

# Check all resources
kubectl get all

# Check auto-scaling
kubectl get hpa

# View pod logs
kubectl logs -f <pod-name>

# Scale manually
kubectl scale deployment backend-deployment --replicas=3

# Delete all
kubectl delete -f k8s/
```

### Health Checks

- **Readiness Probe:** `GET /api/health` (every 5s, start after 10s)
- **Liveness Probe:** `GET /api/health` (every 10s, start after 15s)

---

## 🌐 NGINX Reverse Proxy

NGINX acts as a unified gateway routing traffic to the correct service:

| Path | Destination | Protocol |
|------|-------------|----------|
| `/api/*` | Backend (:5001) | HTTP/1.1 |
| `/socket.io/*` | Backend (:5001) | WebSocket |
| `/*` | Frontend (:3000) | HTTP/1.1 |

### Features
- Gzip compression (level 6)
- Connection keepalive (32 per upstream)
- WebSocket upgrade support
- Client max body size: 10MB
- Upstream health-aware proxying

---

## 📦 Redis Integration

Redis serves two purposes in this architecture:

### 1. Socket.IO Adapter (Distributed WebSockets)
When running multiple backend instances (in Kubernetes), Redis ensures WebSocket messages are shared across all pods via pub/sub.

### 2. Resilient Fallback
The Redis client in [`backend/src/config/redis.ts`](backend/src/config/redis.ts) is designed with a graceful fallback — if Redis is unavailable, the backend continues working with in-memory mode.

```
Backend Pod 1 ──┐
                ├──► Redis Pub/Sub ──► All connected clients
Backend Pod 2 ──┘
```

---

## 🔧 Jenkins CI/CD

### Pipeline Stages

The [`Jenkinsfile`](Jenkinsfile) defines a 5-stage CI/CD pipeline:

```
📥 Checkout → 🔍 Build Backend → 🔍 Build Frontend → 🐳 Docker Build → ☸️ K8s Deploy
```

| Stage | What it does |
|-------|-------------|
| **1. Checkout** | Pulls source code from GitHub |
| **2. Test & Build Backend** | `npm ci` + `npm run build` (TypeScript + Prisma) |
| **3. Test & Build Frontend** | `npm ci` + `npm run build` (Next.js) |
| **4. Build Docker Images** | Builds `school-backend:latest` & `school-frontend:latest` |
| **5. Deploy to Kubernetes** | `kubectl apply` + rollout status check |

### Access Jenkins
- **URL:** `http://localhost:8080`
- **Username:** `admin`
- **Password:** Found in container: `docker exec school_jenkins cat /var/jenkins_home/secrets/initialAdminPassword`

### JVM Memory Configuration
Jenkins runs with limited JVM heap to fit within the 4GB Docker Desktop memory limit:
```
-Xmx512m -Xms256m
```

---

## 🔌 API Endpoints

Base URL: `http://localhost/api` (via NGINX) or `http://localhost:5001/api` (direct)

### Core Routes

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/health` | Health check |
| POST | `/api/auth/login` | User login |
| POST | `/api/auth/register` | User registration |

### Resource Routes (JWT Required)

| Module | Base Path | Operations |
|--------|-----------|------------|
| Students | `/api/students` | CRUD |
| Teachers | `/api/teachers` | CRUD |
| Parents | `/api/parents` | CRUD |
| Classes | `/api/classes` | CRUD |
| Subjects | `/api/subjects` | CRUD |
| Attendance | `/api/attendance` | CRUD |
| Payments | `/api/payments` | CRUD |
| Invoices | `/api/invoices` | CRUD |
| Exams | `/api/exams` | CRUD |
| Results | `/api/results` | CRUD |
| Homework | `/api/homework` | CRUD |
| Announcements | `/api/announcements` | CRUD |
| Timetable | `/api/timetable` | CRUD |
| Schedules | `/api/schedules` | CRUD |
| Transport | `/api/transport` | CRUD |
| Behavior | `/api/behavior` | CRUD |
| Leaves | `/api/leaves` | CRUD |
| Reports | `/api/reports` | CRUD |
| Settings | `/api/settings` | CRUD |
| Users | `/api/users` | CRUD |
| Chat | `/api/chat` | Real-time messaging |
| AI | `/api/ai` | AI-powered features |
| Notifications | `/api/notifications` | Push notifications |

> All resource routes require a valid JWT bearer token from Supabase session in the `Authorization` header.

---

## 🔒 Git Workflow & Safety

### Branches

| Branch | Purpose |
|--------|---------|
| `main` | Production-ready code |
| `feature/devops-docker-k8s` | DevOps infrastructure |

### Safety Tags

| Tag | Description |
|-----|-------------|
| `v1.0-stable-production` | Last known working state before DevOps changes |

### Emergency Rollback

If anything breaks, restore the working version instantly:

```bash
git checkout v1.0-stable-production
```

---

## 🔐 Environment Variables

### Backend (`backend/.env`)

| Variable | Description |
|----------|-------------|
| `PORT` | Server port (default: 5001) |
| `NODE_ENV` | Environment (development/production) |
| `FRONTEND_URL` | Frontend URL for CORS |
| `DATABASE_URL` | PostgreSQL connection (pgbouncer) |
| `DIRECT_URL` | PostgreSQL direct connection |
| `SUPABASE_URL` | Supabase project URL |
| `SUPABASE_ANON_KEY` | Supabase public key |
| `SUPABASE_SERVICE_ROLE_KEY` | Supabase admin key |
| `SUPABASE_JWT_SECRET` | JWT verification secret |
| `REDIS_URL` | Redis connection URL |
| `OPENROUTER_API_KEY` | AI API key |

### Frontend (`frontend/.env`)

| Variable | Description |
|----------|-------------|
| `NEXT_PUBLIC_API_URL` | Backend API URL |
| `NEXT_PUBLIC_SUPABASE_URL` | Supabase project URL |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | Supabase public key |

---

## 📟 Useful Commands

### Docker

```bash
docker compose up -d              # Start all services
docker compose down               # Stop all services
docker compose logs -f backend    # Follow backend logs
docker compose restart backend    # Restart single service
docker stats --no-stream          # Check memory/CPU usage
docker exec school_redis redis-cli ping   # Test Redis
```

### Kubernetes

```bash
kubectl get pods                  # List pods
kubectl get all                   # List all resources
kubectl get hpa                   # Check auto-scaler
kubectl logs -f <pod-name>        # Stream pod logs
kubectl describe pod <pod-name>   # Detailed pod info
kubectl top pods                  # Resource usage per pod
kubectl scale deployment backend-deployment --replicas=3
```

### Git

```bash
git checkout v1.0-stable-production      # Emergency rollback
git checkout feature/devops-docker-k8s   # Back to DevOps branch
git tag -l                               # List all tags
```

---

## 📄 License

ISC

---

<div align="center">
  <p>Built with ❤️ by <strong>Fady Emad</strong></p>
  <p>
    <a href="https://github.com/fadyemad487">GitHub</a> ·
    <a href="https://school-management487.vercel.app">Live Demo</a>
  </p>
</div>
