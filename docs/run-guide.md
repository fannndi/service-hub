# Run Guide — ServisGadget (100% Serverless)

## 0. Prasyarat
- Flutter SDK 3.4+
- Supabase CLI (`npm install -g supabase`)
- Android Emulator atau HP fisik

## 1. Setup Project

```bash
# Clone repo
git clone https://github.com/fannndi/service-hub.git
cd service-hub

# Setup frontend
cd frontend
flutter pub get
```

## 2. Setup Env Variables

Buat `.env` dari contoh yang ada (atau minta dari tim):
```env
SUPABASE_URL=https://eboplbemgtvmviwhdlfa.supabase.co
SUPABASE_ANON_KEY=sb_publishable_xxxx
```

## 3. Run Flutter App

### Emulator
```bash
cd frontend
flutter run --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY
```

### HP Fisik
```bash
flutter run --release --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY
```

## 4. Build APK/AAB

```bash
cd frontend

# APK release (testing)
flutter build apk --release \
  --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY

# AAB (Play Store)
flutter build appbundle --release \
  --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY
```

## 5. Deploy Backend (Edge Functions)

```bash
# Login ke Supabase
supabase login

# Link project
supabase link --project-ref eboplbemgtvmviwhdlfa

# Push migrations
supabase db push

# Deploy semua Edge Functions
supabase functions deploy guest orders payments midtrans disputes reviews notifications admin store-applications cron-sla

# Set environment secrets
supabase secrets set MIDTRANS_SERVER_KEY=Mid-server-xxx
supabase secrets set WA_GATEWAY_URL=...
supabase secrets set WA_GATEWAY_TOKEN=...
```

## 6. Login

| Halaman | Route | Kredensial |
|---------|-------|------------|
| Admin Platform | `/admin/login` | `admin` / `admin123` |
| Pelanggan | `/login` | HP + password (atau guest) |
| Toko | `/store-login` | Dibuat oleh Admin Platform |

## 7. Arsitektur

```
Flutter App → Supabase SDK
  ├── PostgreSQL (via RLS) — direct read/write
  ├── Edge Functions — business logic (orders, payments, midtrans, etc.)
  └── Supabase Auth — login/session
```

Tidak ada backend server. Semua serverless via Supabase.
