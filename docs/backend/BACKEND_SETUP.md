# Backend Setup & Configuration

> Panduan lengkap setup backend ServisGadget untuk development dan production.

---

## Table of Contents

1. [Prerequisites](#1-prerequisites)
2. [Local Development](#2-local-development)
3. [Docker Setup](#3-docker-setup)
4. [Environment Variables](#4-environment-variables)
5. [Database](#5-database)
6. [Deployment (Render)](#6-deployment-render)
7. [Project Structure](#7-project-structure)

---

## 1. Prerequisites

- Node.js >= 18.x
- npm >= 9.x
- PostgreSQL 16 (via Docker atau lokal)
- Redis 7 (via Docker atau lokal)

---

## 2. Local Development

```bash
# 1. Clone & install
cd backend
npm install

# 2. Setup environment
cp .env.example .env
# Edit .env sesuai kebutuhan

# 3. Setup database
npx prisma generate
npx prisma db push
# atau
npx prisma migrate dev

# 4. Seed database (opsional)
npx ts-node prisma/seed.ts

# 5. Start development
npm run start:dev
```

**Available Scripts:**
| Script | Fungsi |
|--------|--------|
| `npm run start:dev` | Development mode (watch) |
| `npm run build` | Production build |
| `npm run start:prod` | Start production |
| `npm run lint` | ESLint check |
| `npm run test` | Jest tests |

---

## 3. Docker Setup

### docker-compose.yml

```yaml
version: '3.8'
services:
  postgres:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: servisgadget
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
    ports:
      - "5432:5432"
    volumes:
      - pgdata:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"

  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
    ports:
      - "3000:3000"
    environment:
      - DATABASE_URL=postgresql://postgres:postgres@postgres:5432/servisgadget
      - REDIS_HOST=redis
    depends_on:
      - postgres
      - redis

volumes:
  pgdata:
```

```bash
# Start all services
docker-compose up -d

# Logs
docker-compose logs -f backend

# Stop
docker-compose down
```

---

## 4. Environment Variables

### Core

| Variable | Default | Description |
|----------|---------|-------------|
| `PORT` | `3000` | Server port |
| `NODE_ENV` | `development` | Environment |
| `APP_URL` | `http://localhost:3000` | CORS origin |

### Database

| Variable | Description |
|----------|-------------|
| `DATABASE_URL` | PostgreSQL connection string |

### Redis

| Variable | Default | Description |
|----------|---------|-------------|
| `REDIS_HOST` | `localhost` | Redis host |
| `REDIS_PORT` | `6379` | Redis port |

### JWT - Customer

| Variable | Description |
|----------|-------------|
| `JWT_ACCESS_SECRET` | Secret for access token |
| `JWT_REFRESH_SECRET` | Secret for refresh token |
| `JWT_ACCESS_EXPIRES_IN` | Default: `1h` |
| `JWT_REFRESH_EXPIRES_IN` | Default: `30d` |

### JWT - Store Admin

| Variable | Description |
|----------|-------------|
| `JWT_STORE_ACCESS_SECRET` | Secret for store access token |
| `JWT_STORE_REFRESH_SECRET` | Secret for store refresh token |

### JWT - Platform Admin

| Variable | Description |
|----------|-------------|
| `JWT_PLATFORM_ADMIN_SECRET` | Secret for admin token (fallback: `JWT_STORE_ACCESS_SECRET`) |

### Credential Encryption

| Variable | Description |
|----------|-------------|
| `CREDENTIAL_ENCRYPTION_KEY` | 64 hex characters (32 bytes) for AES-256-GCM |

### WhatsApp Gateway (Fonnte)

| Variable | Description |
|----------|-------------|
| `WA_GATEWAY_URL` | Fonnte API URL |
| `WA_GATEWAY_TOKEN` | Fonnte API token |
| `WA_SENDER_NUMBER` | Sender WhatsApp number |

### Storage (S3-compatible)

| Variable | Description |
|----------|-------------|
| `STORAGE_ENDPOINT` | S3 endpoint (Cloudflare R2, AWS S3, etc.) |
| `STORAGE_ACCESS_KEY` | Access key |
| `STORAGE_SECRET_KEY` | Secret key |
| `STORAGE_BUCKET` | Bucket name |
| `STORAGE_PUBLIC_URL` | Public URL for files |

### SLA Timeouts (minutes)

| Variable | Default | Description |
|----------|---------|-------------|
| `SLA_RECEIVE_DEVICE_MINUTES` | `1440` (24h) | Device reception deadline |
| `SLA_DIAGNOSIS_MINUTES` | `1440` (24h) | Diagnosis deadline |
| `SLA_APPROVAL_MINUTES` | `1440` (24h) | Approval deadline |
| `SLA_PAYMENT_MINUTES` | `2880` (48h) | Payment deadline |
| `SLA_CREDENTIAL_CLEAR_MINUTES` | `1440` (24h) | Credential cleanup |
| `SLA_DISPUTE_RESPOND_MINUTES` | `1440` (24h) | Dispute response deadline |

### Rate Throttling

| Variable | Default | Description |
|----------|---------|-------------|
| `THROTTLE_TTL_SECONDS` | `60` | Time window |
| `THROTTLE_LIMIT` | `100` | Max requests per window |

---

## 5. Database

### Prisma Commands

```bash
# Generate Prisma Client
npx prisma generate

# Push schema to database (no migrations)
npx prisma db push

# Create migration
npx prisma migrate dev --name init

# Apply migrations
npx prisma migrate deploy

# Reset database
npx prisma migrate reset

# Open Prisma Studio
npx prisma studio
```

### Seed Data

```bash
npx ts-node prisma/seed.ts
```

Seed script membuat:
- 1 Platform Admin (username: `admin`, password: `admin123`)
- 1 Store dengan 2 Store Admin
- Sample spareparts
- Sample orders

---

## 6. Deployment (Render)

### render.yaml

```yaml
services:
  - type: web
    name: servisgadget-api
    runtime: node
    plan: starter
    buildCommand: cd backend && npm install && npx prisma generate
    startCommand: cd backend && npx prisma migrate deploy && node dist/main.js
    envVars:
      - key: DATABASE_URL
        sync: false
      - key: JWT_ACCESS_SECRET
        generateValue: true
      - key: JWT_REFRESH_SECRET
        generateValue: true
      - key: CREDENTIAL_ENCRYPTION_KEY
        generateValue: true
        type: secret
```

### One-Click Deploy
1. Push ke GitHub
2. Buka Render Dashboard
3. New > Blueprint
4. Select repo
5. Render akan otomatis detect `render.yaml`
6. Set environment variables
7. Deploy

---

## 7. Project Structure

```
backend/
├── Dockerfile                  # Multi-stage production build
├── package.json                # Dependencies & scripts
├── tsconfig.json               # TypeScript config (strict mode)
├── nest-cli.json               # NestJS CLI config
│
├── prisma/
│   ├── schema.prisma           # Database schema (21 models, 20+ enums)
│   ├── seed.ts                 # Database seed script
│   └── migrations/             # Prisma migrations
│
└── src/
    ├── main.ts                 # Entry point (bootstrap)
    ├── app.module.ts           # Root module
    │
    ├── config/
    │   └── configuration.ts    # Env config loader
    │
    ├── common/                 # Shared utilities
    │   ├── prisma/             # PrismaService (global)
    │   ├── guards/             # JwtAuthGuard, StoreJwtAuthGuard, RolesGuard, FirstLoginGuard
    │   ├── decorators/         # @GetUser(), @Roles()
    │   ├── filters/            # GlobalExceptionFilter
    │   ├── interceptors/       # ResponseInterceptor
    │   ├── exceptions/         # 20+ custom exceptions
    │   ├── constants/          # SLA_MINUTES
    │   ├── types/              # JwtPayload
    │   └── health.controller.ts
    │
    └── modules/                # Business modules
        ├── auth/               # Customer auth (login, refresh, change-password)
        ├── store-auth/         # Store admin auth
        ├── platform-admin/     # Platform admin (create store)
        ├── users/              # /me endpoints (profile, coupons, orders, notifications)
        ├── stores/             # Store listing, matching, dashboard
        ├── store-register/     # Store self-registration
        ├── orders/             # Order CRUD + state machine + diagnosis
        ├── payments/           # Payment processing + confirmation
        ├── reviews/            # Reviews + coupon rewards
        ├── disputes/           # Dispute/warranty claims
        ├── spareparts/         # Sparepart inventory
        ├── notifications/      # WhatsApp notifications (Fonnte)
        ├── uploads/            # S3 presigned URL uploads
        └── jobs/               # Background jobs (SLA monitor, credential cleaner)
```
