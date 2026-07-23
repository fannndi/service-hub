# Deployment Guide — Service Hub

## Prerequisites

- Supabase CLI (`npm install -g supabase`)
- Flutter SDK 3.4+
- Node.js 18+
- Supabase project (free tier)
- Midtrans account (sandbox for dev, production for live)


---

## Step 1: Link Supabase Project

```bash
supabase login

# Link local project to remote Supabase project
supabase link --project-ref <PROJECT_REF>
```

`<PROJECT_REF>` dapat ditemukan di Supabase Dashboard → Project Settings → General → Reference ID.

---

## Step 2: Push Migrations

```bash
supabase db push
```

Menjalankan semua file migrasi dari `supabase/migrations/` ke database Supabase. Termasuk pembuatan tabel, enum, stored procedures, dan RLS policies.

---

## Step 3: Deploy Edge Functions

```bash
# Deploy semua fungsi sekaligus
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

Catatan: Fungsi `guest`, `cron-sla`, dan `seed-admin` menggunakan `--no-verify-jwt` karena tidak memerlukan autentikasi.

---

## Step 4: Set Environment Secrets

```bash
# Midtrans
supabase secrets set MIDTRANS_SERVER_KEY=Mid-server-xxx


```

Semua secret ini diakses di Edge Functions via `Deno.env.get()`.

---

## Step 5: Build Flutter APK

```bash
cd frontend

flutter build apk --release \
  --dart-define=SUPABASE_URL=https://<PROJECT_REF>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<ANON_KEY>
```

`SUPABASE_URL` dan `SUPABASE_ANON_KEY` dapat ditemukan di Supabase Dashboard → Project Settings → API.

APK output: `frontend/build/app/outputs/flutter-apk/app-release.apk`

---

## Step 6: Build App Bundle untuk Play Store

```bash
cd frontend

flutter build appbundle --release \
  --dart-define=SUPABASE_URL=https://<PROJECT_REF>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<ANON_KEY>
```

AAB output: `frontend/build/app/outputs/bundle/release/app-release.aab`

Upload file `.aab` ini ke Google Play Console → Production → Create new release.

---

## Rollback

```bash
# Rollback Edge Function ke versi sebelumnya
supabase functions deploy <function-name> --legacy-bundle

# Rollback database migration
supabase db diff --use-migra
```
