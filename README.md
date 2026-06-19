# ServisGadget

> Platform Marketplace Servis Gadget Dua Sisi — Customer booking tanpa akun, admin toko kelola dari mobile

---

## Tech Stack

| Layer | Tech |
|-------|------|
| Backend | NestJS 10, TypeScript 5, Prisma 5, PostgreSQL 16, Redis 7 |
| Frontend | Flutter 3.4+, Dart 3, Riverpod 2.6, GoRouter 14 |
| Auth | 3 JWT systems (Customer, Store Admin, Platform Admin) |
| Infra | Docker Compose, Cloudflare Tunnel, GitHub Actions CI |

---

## Quick Start

```bash
# 1. Clone & setup
git clone https://github.com/fannndi/service-hub.git && cd service-hub
./switch-env.sh local

# 2. Fix Docker hostnames
sed -i 's|@localhost:5432/|@postgres:5432/|' .env
sed -i 's|REDIS_HOST=localhost|REDIS_HOST=redis|' .env

# 3. Start
docker compose up -d --build
docker compose exec backend npx prisma db push
docker compose exec backend npx prisma db seed

# 4. Tunnel (optional)
cloudflared tunnel --url http://localhost:3000
```

Health check: `curl http://localhost:3000/v1/health`
Swagger: `http://localhost:3000/docs`

---

## Login

| Role | Route | Credentials |
|------|-------|-------------|
| Platform Admin | `/admin` | `admin` / `admin` |
| Store Admin | `/store-login` | Dibuat dari platform admin |
| Customer | `/login` | Booking langsung (stealth account) |

---

## Project Structure

```
service-hub/
├── backend/                  NestJS API (15 modules)
│   └── src/modules/
│       ├── auth/             Customer auth + stealth accounts
│       ├── store-auth/       Store admin auth + sessions
│       ├── platform-admin/   Admin dashboard
│       ├── orders/           Order lifecycle + state machine
│       ├── spareparts/       Inventory + stock management
│       ├── payments/         Payment confirmation
│       ├── reviews/          Reviews + coupons
│       ├── disputes/         Warranty claims
│       ├── notifications/    WhatsApp + email
│       ├── uploads/          Presigned S3 URLs
│       └── jobs/             SLA monitor + credential cleaner
│
├── frontend/                 Flutter mobile app
│   └── lib/
│       ├── core/             Config, models, helpers
│       ├── network/          Dio client + auth
│       ├── ui/               ★ Theme, widgets, config (UI system)
│       │   ├── theme/        Colors, typography, spacing
│       │   └── config/       App constants
│       └── features/
│           ├── customer/     22 screens
│           ├── store_admin/  14 screens
│           └── platform_admin/ 2 screens
│
├── docs/                     Documentation
│   ├── PRD/                  Product requirements (3 phases + master)
│   ├── backend/              API reference, auth system, business logic
│   ├── frontend/             Store admin architecture
│   └── architecture.md       System overview
│
├── docker-compose.yml        PostgreSQL + Redis + Backend
├── secrets/                  Environment files (gitignored)
├── tunel.txt                 Cloudflare tunnel URL
└── start-demo.sh             One-click demo launcher
```

---

## UI Configuration

Theme files di `frontend/lib/ui/`:
- `theme/app_theme.dart` — Light/dark ThemeData
- `theme/app_spacing.dart` — Spacing constants (xs/s/md/lg/xl/xxl)
- `theme/app_typography.dart` — Text style hierarchy
- `config/` — App-wide constants

---

## API Overview

### Customer (`/v1/`)
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/orders` | Create order (stealth) |
| POST | `/orders/:id/approve` | Approve diagnosis |
| POST | `/orders/:id/reject` | Reject diagnosis |
| POST | `/orders/:id/payments` | Submit payment |
| POST | `/orders/:id/reviews` | Write review |
| POST | `/orders/:id/disputes` | File warranty claim |
| GET | `/stores/match` | Find matching stores |

### Store Admin (`/v1/store/`)
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/auth/login` | Store login |
| GET | `/orders` | List orders |
| POST | `/orders/:id/diagnosis` | Submit diagnosis |
| GET | `/spareparts` | List inventory |
| POST | `/spareparts` | Add sparepart |
| PATCH | `/spareparts/:id/stock` | Quick stock adjust |

### Platform Admin (`/v1/platform/`)
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/login` | Admin login |
| POST | `/stores` | Create store |

---

## Deployment

- **Local**: Docker Compose + Cloudflare Tunnel
- **Production**: Render (`render.yaml` included) or any VPS with Docker
- See `docs/deployment.md` for full guide

---

## Documentation

| File | Content |
|------|---------|
| `docs/PRD/00_MASTER_PRD.md` | Master product requirements |
| `docs/PRD/01_PHASE_FOUNDATION.md` | Phase 1: Foundation |
| `docs/PRD/02_PHASE_CUSTOMER.md` | Phase 2: Customer features |
| `docs/PRD/03_PHASE_STORE_ADMIN.md` | Phase 3: Store admin features |
| `docs/architecture.md` | System architecture |
| `docs/deployment.md` | Deployment guide |
| `docs/run-guide.md` | Run guide (Docker + non-Docker) |
| `CHANGELOG.md` | Version history |
| `TODO.md` | Audit tracker |
