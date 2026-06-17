# Run Guide — ServisGadget (No Docker)

## Prasyarat
- Node.js 20+
- Flutter 3.4+
- Database Supabase (sudah aktif)
- Android Studio + Emulator

---

## 1. Backend (NestJS)

### Setup
```bash
cd backend
npm install
```

### Konfigurasi .env
Edit `backend/.env`, isi semua variable yang diperlukan. Copy dari `.env.example`:
```bash
cp .env.example .env
```
Variable minimal yang harus diisi:
- `DATABASE_URL` — PostgreSQL connection string
- `JWT_ACCESS_SECRET`, `JWT_REFRESH_SECRET` — JWT secrets customer
- `JWT_STORE_ACCESS_SECRET`, `JWT_STORE_REFRESH_SECRET` — JWT secrets store admin
- `JWT_PLATFORM_ADMIN_SECRET` — JWT secret platform admin
- `CREDENTIAL_ENCRYPTION_KEY` — 32-byte hex (64 hex chars)

Lihat `.env.example` untuk daftar lengkap env vars.

### Generate Prisma Client + Seed
```bash
npx prisma generate
npx prisma db push        # sync schema ke Supabase
npx prisma db seed         # insert data awal (admin, store, spareparts)
```

### Run
```bash
npm run start:dev
```
Backend jalan di `http://localhost:3000`. Swagger: `http://localhost:3000/docs`.

---

## 2. Flutter (Android)

### Setup
```bash
cd frontend
flutter pub get
```

### Konfigurasi API URL
Edit `lib/core/app_config.dart`, default URL:
- **Emulator**: `http://10.0.2.2:3000/v1` (otomatis)
- **HP fisik / Production**: build dengan `--dart-define`:
  ```bash
  flutter run --dart-define=API_BASE_URL=https://api-domainmu.com/v1
  ```

### Run di Emulator
```bash
flutter run
```

### Build APK Release
```bash
flutter build apk --release \
  --dart-define=API_BASE_URL=https://api-domainmu.com/v1
```
APK ada di `build/app/outputs/flutter-apk/app-release.apk`.

### Build AAB (Play Store)
```bash
flutter build appbundle --release \
  --dart-define=API_BASE_URL=https://api-domainmu.com/v1
```

---

## 3. Login

| Halaman | Route | Kredensial Default |
|---|---|---|
| Admin Platform | `/admin/login` | `admin` / `admin` |
| Pelanggan | `/login` | HP + password (stealth account auto-create saat booking) |
| Toko | `/store-login` | Dibuat oleh Admin Platform |

---

## 4. Deploy Backend ke Production

Opsi gratis:
- **Railway** — copy-paste repo, set env vars, auto-deploy
- **Render** — web service, free PostgreSQL
- **Fly.io** — `fly launch` dari folder backend

Yang wajib di-set di production:
```
DATABASE_URL=postgresql://...
JWT_ACCESS_SECRET=<random>
JWT_REFRESH_SECRET=<random>
JWT_STORE_ACCESS_SECRET=<random>
JWT_STORE_REFRESH_SECRET=<random>
JWT_PLATFORM_ADMIN_SECRET=<random>
CREDENTIAL_ENCRYPTION_KEY=<random>
```
