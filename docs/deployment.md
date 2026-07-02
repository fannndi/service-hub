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
  --dart-define=SUPABASE_URL=https://eboplbemgtvmviwhdlfa.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=sb_publishable_sLbPJCOjGT9GRGZBosGlsQ_4cpeOMRV

# Build AAB untuk Play Store
flutter build appbundle --release \
  --dart-define=SUPABASE_URL=https://eboplbemgtvmviwhdlfa.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=sb_publishable_sLbPJCOjGT9GRGZBosGlsQ_4cpeOMRV
```

---

## 5. Play Store Release

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
