# Deployment Guide

## Prerequisites

- Docker & Docker Compose (local)
- Render.com account (production)
- PostgreSQL 16 (Supabase or self-hosted)
- Redis 7 (Upstash or self-hosted)

## Local Development

```bash
# Start all services
docker compose up -d

# Run migrations
cd backend && npx prisma migrate deploy

# Seed database
cd backend && npm run prisma:seed

# View logs
docker compose logs -f backend
```

## Production (Render)

Health check endpoint: `GET /v1/health`
Metrics endpoint: `GET /v1/metrics`

1. Fork this repo
2. Create a Render Web Service from the repo root
3. Set runtime to `Docker`
4. Set health check path to `/v1/health`
5. Set required env vars via Render Dashboard:
   - `DATABASE_URL` — PostgreSQL connection string
   - `JWT_ACCESS_SECRET` — 32+ char random string
   - `JWT_REFRESH_SECRET` — 32+ char random string
   - `JWT_STORE_ACCESS_SECRET` — 32+ char random string
   - `JWT_STORE_REFRESH_SECRET` — 32+ char random string
   - `JWT_PLATFORM_ADMIN_SECRET` — 32+ char random string
   - `CREDENTIAL_ENCRYPTION_KEY` — 32-byte hex key
   - `REDIS_URL` — Redis connection string (optional)
   - `PORT` — `3000`

## Rollback

If a deployment fails:

```bash
# Revert to previous version
git revert HEAD
git push

# Render auto-deploys the revert
```

To rollback via Render Dashboard:
1. Go to Dashboard → servisgadget-api
2. Click "Manual Deploy" → "Deploy existing commit"
3. Select the previous working commit
4. Deploy
