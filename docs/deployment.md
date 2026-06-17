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
   - `JWT_ACCESS_SECRET` — 64-byte hex random string
   - `JWT_REFRESH_SECRET` — 64-byte hex random string
   - `JWT_STORE_ACCESS_SECRET` — 64-byte hex random string (must differ from customer)
   - `JWT_STORE_REFRESH_SECRET` — 64-byte hex random string
   - `JWT_PLATFORM_ADMIN_SECRET` — 64-byte hex random string (must differ from both above)
   - `CREDENTIAL_ENCRYPTION_KEY` — 32-byte hex key (64 hex chars)
   - `REDIS_HOST` / `REDIS_PORT` — Redis connection (optional, graceful degradation)
   - `SMTP_HOST` / `SMTP_PORT` / `SMTP_USER` / `SMTP_PASS` — Email fallback
   - `STORE_EMAIL` — Email notif recipient for WA fallback
   - `WA_GATEWAY_URL` / `WA_GATEWAY_TOKEN` / `WA_SENDER_NUMBER` — WhatsApp
   - `STORAGE_ENDPOINT` / `STORAGE_ACCESS_KEY` / `STORAGE_SECRET_KEY` / `STORAGE_BUCKET` / `STORAGE_PUBLIC_URL` — R2/S3
   - `APP_URL` — Frontend app URL
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
