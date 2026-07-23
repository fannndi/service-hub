# Run Guide — Service Hub (100% Serverless)

## 0. Prerequisites

- Flutter SDK 3.4+
- Supabase CLI (`npm install -g supabase`)
- Android Emulator or physical device

## 1. Setup Project

```bash
git clone https://github.com/fannndi/service-hub.git
cd service-hub/frontend
flutter pub get
```

## 2. Environment Variables

```env
SUPABASE_URL=https://eboplbemgtvmviwhdlfa.supabase.co
SUPABASE_ANON_KEY=<your-anon-key>
```

> No local Supabase stack. Project uses a **remote Supabase instance**. No Docker, no local PostgreSQL.

## 3. Run Flutter App

```bash
cd frontend
flutter run --dart-define=SUPABASE_URL=%SUPABASE_URL% ^
  --dart-define=SUPABASE_ANON_KEY=%SUPABASE_ANON_KEY%
```

For release mode on a physical device:

```bash
flutter run --release --dart-define=SUPABASE_URL=%SUPABASE_URL% ^
  --dart-define=SUPABASE_ANON_KEY=%SUPABASE_ANON_KEY%
```

### Using scripts

| Script | Function |
|--------|----------|
| `scripts/run_emulator.bat` | Run on emulator-5554 (debug) |
| `scripts/build_apk.bat` | Build release APK |
| `scripts/build_appbundle.bat` | Build Play Store AAB |
| `scripts/build.bat` | Build APK (reads `.env` automatically) |

Scripts expect `SUPABASE_URL` and `SUPABASE_ANON_KEY` in environment or `.env` at repo root.

## 4. Run Tests

```bash
cd frontend
flutter test
```

23 tests across 4 test files.

## 5. Link to Remote Supabase

```bash
supabase link --project-ref eboplbemgtvmviwhdlfa
```

## 6. Deploy Edge Functions

```bash
# Deploy all at once
supabase functions deploy admin cron-sla disputes guest midtrans ^
  notifications orders payments reviews seed-admin store-applications

# Set secrets
supabase secrets set MIDTRANS_SERVER_KEY=Mid-server-xxx

```

## 7. Test Edge Functions (curl / PowerShell)

```powershell
# Health check
curl -X POST https://eboplbemgtvmviwhdlfa.supabase.co/functions/v1/orders `
  -H "Authorization: Bearer $SUPABASE_ANON_KEY" `
  -H "Content-Type: application/json" `
  -d '{\"action\":\"ping\"}'

# With service role (admin operations)
curl -X POST https://eboplbemgtvmviwhdlfa.supabase.co/functions/v1/admin `
  -H "Authorization: Bearer $SERVICE_ROLE_KEY" `
  -H "Content-Type: application/json" `
  -d '{\"action\":\"list_stores\"}'
```

## Architecture

```
Flutter App → Supabase SDK
  ├── PostgreSQL (via RLS) — direct read/write
  ├── Edge Functions — business logic (orders, payments, midtrans, etc.)
  └── Supabase Auth — login/session
```

No backend server. 100% serverless via Supabase.
