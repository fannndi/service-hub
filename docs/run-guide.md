# Run Guide — ServisGadget

## 0. Local Docker (WSL) — Recommended

### Prasyarat
- WSL 2 + Ubuntu/Debian distro
- Docker Desktop → Settings → Resources → WSL Integration: **enable distro kamu**
- Cek: `docker compose version`

### 1. Setup `.env` (root project)

```bash
# Kalau folder secrets/ sudah ada dari tim:
./switch-env.sh local

# Kalau belum ada, buat manual dari template:
cp .env.example .env
```

Edit `.env`, isi minimal:

```env
DATABASE_URL=postgresql://servisgadget:servisgadget@localhost:5432/servisgadget
REDIS_HOST=localhost
REDIS_PORT=6379
JWT_ACCESS_SECRET=<generate>
JWT_REFRESH_SECRET=<generate>
JWT_STORE_ACCESS_SECRET=<generate>
JWT_STORE_REFRESH_SECRET=<generate>
JWT_PLATFORM_ADMIN_SECRET=<generate>
CREDENTIAL_ENCRYPTION_KEY=<generate>
NODE_ENV=development
PORT=3000
```

Generate secrets:
```bash
# JWT secret (64-byte hex = 128 char)
node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"

# Credential key (32-byte hex = 64 char)
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
```

### 2. Build & Start

```bash
docker compose up -d --build
```

Ini start 3 container: **PostgreSQL 16** (5432), **Redis 7** (6379), **Backend** (3000).

### 3. Migrasi + Seed

```bash
docker compose exec backend npx prisma db push
docker compose exec backend npx prisma db seed
```

### 4. Cek

- Health: `curl http://localhost:3000/v1/health`
- Swagger: `http://localhost:3000/docs`
- Logs: `docker compose logs -f backend`

### Rebuild (setelah edit kode backend)

```bash
docker compose up -d --build backend
```

### Stop

```bash
docker compose down
```

Hapus volume database (fresh start):
```bash
docker compose down -v
```

### Troubleshooting

| Masalah | Solusi |
|---------|--------|
| Port 5432 sudah dipakai | `docker compose down`, stop PostgreSQL manual, lalu `docker compose up -d` |
| `prisma db push` gagal | Pastikan backend container running: `docker compose ps` |
| Seed error | Hapus dulu: `docker compose down -v`, lalu `docker compose up -d --build`, push + seed ulang |
| Docker lambat di Windows | Pastikan WSL2 backend di `C:\` bukan network drive. Cek Settings → Resources → WSL Integration |
| Cloudflare tunnel DNS error | Fix DNS di WSL: `sudo sed -i 's|\#DNSStubListener=yes|DNSStubListener=no|' /etc/systemd/resolved.conf && echo "DNS=8.8.8.8 8.8.4.4" sudo tee -a /etc/systemd/resolved.conf && sudo systemctl restart systemd-resolved && sudo rm /etc/resolv.conf && echo "nameserver 8.8.8.8" sudo tee /etc/resolv.conf` |
| Cloudflare tunnel stuck | Mungkin rate limit. Tunggu 30 detik, lalu jalankan ulang. Pastikan `systemd-resolved` DNS fix sudah diterapkan. |

---

## 1. Backend (NestJS — Non-Docker / Supabase)

> **Alternatif** kalau tidak pakai Docker. Butuh Supabase atau PostgreSQL external.

### Prasyarat
- Node.js 20+
- Database Supabase (sudah aktif)

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
