# Deployment Guide — ServisGadget (Serverless)

## Prerequisites

- Supabase CLI (`npm install -g supabase`)
- Flutter SDK 3.4+
- Supabase project (free tier)
- Midtrans account (sandbox for development)

---

## 1. Initial Setup

```bash
# Login ke Supabase
supabase login

# Link project
supabase link --project-ref eboplbemgtvmviwhdlfa

# Push migrations
supabase db push
```

---

## 2. Deploy Edge Functions

```bash
# Deploy semua fungsi
supabase functions deploy guest
supabase functions deploy orders
supabase functions deploy payments
supabase functions deploy midtrans
supabase functions deploy disputes
supabase functions deploy reviews
supabase functions deploy notifications
supabase functions deploy admin
supabase functions deploy store-applications
supabase functions deploy cron-sla
supabase functions deploy seed-admin
```

---

## 3. Set Environment Secrets

```bash
# Midtrans
supabase secrets set MIDTRANS_SERVER_KEY=Mid-server-xxx

# WhatsApp Gateway
supabase secrets set WA_GATEWAY_URL=https://your-wa-gateway.com
supabase secrets set WA_GATEWAY_TOKEN=your-token
```

---

## 4. Build & Deploy Flutter App

```bash
cd frontend

# Build APK release
flutter build apk --release \
  --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY

# Build AAB untuk Play Store
flutter build appbundle --release \
  --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY
```

---

## 5. Apply RPC Fix (SQL Editor)

Karena Management API tidak mendukung SQL query di free tier, jalankan via Supabase Dashboard:

1. Buka https://supabase.com/dashboard/project/eboplbemgtvmviwhdlfa/sql/new
2. Copy paste isi file `supabase/migrations/016_fix_rpc_and_seed.sql`
3. Run — ini akan fix `reserve_stock`, `consume_stock`, `release_stock`, `swap_sparepart`

## 6. Deploy Guest Function (tanpa JWT)

```bash
supabase functions deploy guest --no-verify-jwt
```

## 7. Play Store Release

1. Buka [Google Play Console](https://play.google.com/console)
2. Upload AAB dari `frontend/build/app/outputs/bundle/release/app-release.aab`
3. Isi "What's new" notes
4. Submit untuk review

---

## Rollback

```bash
# Rollback Edge Function
supabase functions deploy <function-name> --legacy-bundle

# Rollback migration
supabase db diff --use-migra
```
