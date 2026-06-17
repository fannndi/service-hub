# ServisGadget — Panduan Setup Lengkap (Dari Nol)

> Panduan ini untuk setup **ServisGadget** di laptop Windows dari awal sampai bisa running.

---

## Daftar Isi

1. [Prasyarat](#1-prasyarat)
2. [Install WSL](#2-install-wsl)
3. [Install Docker di WSL](#3-install-docker-di-wsl)
4. [Clone Project](#4-clone-project)
5. [Setup Environment](#5-setup-environment)
6. [Build & Run Docker](#6-build--run-docker)
7. [Setup Database](#7-setup-database)
8. [Jalankan Flutter](#8-jalankan-flutter)
9. [Testing](#9-testing)
10. [Command Penting](#10-command-penting)

---

## 1. Prasyarat

| Software | Minimal | Download |
|----------|---------|----------|
| Windows 10/11 | 22H2 / 23H2 | - |
| WSL 2 | Built-in | PowerShell admin |
| Node.js | 20+ | [nodejs.org](https://nodejs.org) |
| Flutter SDK | 3.4+ | [flutter.dev](https://docs.flutter.dev/get-started/install/windows) |
| VS Code | Latest | [code.visualstudio.com](https://code.visualstudio.com) |
| Git | Latest | `winget install git.git` |

Cek versi masing-masing:

```powershell
node --version
flutter --version
git --version
```

---

## 2. Install WSL

Buka **PowerShell sebagai Administrator** lalu jalankan:

```powershell
wsl --install -d Ubuntu
```

> Ini akan install WSL 2 + Ubuntu. **Restart PC** setelah selesai.

Setelah restart, buka **Command Prompt** dan cek:

```powershell
wsl -l -v
```

Output harus menunjukkan `Ubuntu` dengan `STATE: Running` dan `VERSION: 2`.

---

## 3. Install Docker di WSL

Buka **Command Prompt** lalu masuk ke WSL:

```powershell
wsl -d Ubuntu
```

Sekarang kamu di terminal Ubuntu (Linux). Jalankan satu per satu:

```bash
# Update package list
sudo apt update

# Install prerequisites
sudo apt install -y ca-certificates curl gnupg

# Add Docker GPG key
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Add Docker repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list

# Install Docker Engine
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Start Docker service
sudo service docker start

# (Opsional) Biar ga perlu sudo tiap command
sudo usermod -aG docker $USER
```

Verifikasi:

```bash
docker --version
docker compose version
```

> **Catatan:** Jika `usermod` dijalankan, keluar WSL (`exit`) lalu masuk lagi (`wsl -d Ubuntu`) agar berlaku.

---

## 4. Clone Project

Buka **Command Prompt** (jangan di WSL), lalu clone:

```powershell
cd C:\Users\%USERNAME%\Documents
git clone https://github.com/[username]/[repo-name].git
cd service-hub
```

Atau copy folder project langsung dari flashdisk/USB.

Masuk ke WSL:

```powershell
wsl -d Ubuntu
cd /mnt/c/Users/%USERNAME%/Documents/service-hub
```

> **PENTING:** Gunakan `ls` untuk navigasi di WSL. Path Windows `C:\Users\...` jadi `/mnt/c/Users/...` di WSL.

---

## 5. Setup Environment

Project ini punya **2 mode environment**: Local dan Production.

**Pilih LOCAL untuk development:**

```bash
# Switch ke local (copy .env.local → .env)
bash switch-env.sh local
```

Atau manual:

```bash
cp .env.local .env
```

**Cek file .env berhasil dibuat:**

```bash
cat .env | grep DATABASE_URL
# Output harus: postgresql://servisgadget:servisgadget@postgres:5432/servisgadget
```

---

## 6. Build & Run Docker

Masih di dalam WSL, di direktori `service-hub`:

```bash
# Build image + start containers
docker compose up -d --build
```

Proses build memakan waktu **3-5 menit** (download image + install dependencies).

Cek status:

```bash
docker compose ps
```

Output yang benar:

```
NAME                    IMAGE                 COMMAND                  SERVICE    STATUS
servisgadget_backend    service-hub-backend   "docker-entrypoint.s…"   backend    Up X seconds (healthy)
servisgadget_postgres   postgres:16-alpine    "docker-entrypoint.s…"   postgres   Up X seconds (healthy)
servisgadget_redis      redis:7-alpine        "docker-entrypoint.s…"   redis      Up X seconds (healthy)
```

Semua harus `(healthy)`.

---

## 7. Setup Database

Setelah container running, buat tabel + seed data:

```bash
# Buat table dari Prisma schema
docker compose exec backend npx prisma db push

# Seed data awal
docker compose exec backend npx prisma db seed
```

Seed akan membuat data test:

| Data | Nilai |
|------|-------|
| **Store** | ServisGadget Pusat |
| **Store Admin** | 081234567890 / admin123 |
| **Customer** | 081212345678 / customer123 |
| **Platform Admin** | admin / admin |
| **Spareparts** | 5 item |

Verifikasi backend:

```bash
curl http://localhost:3000/v1/health
curl http://localhost:3000/v1/config
```

Output `/v1/config` harus menunjukkan `"maintenanceMode": false`.

---

## 8. Jalankan Flutter

Buka **Command Prompt** Windows (bukan WSL):

```powershell
cd C:\Users\%USERNAME%\Documents\service-hub\frontend

# Install dependencies
flutter pub get

# Tambah shared_preferences jika belum
flutter pub add shared_preferences

# Jalankan app
flutter run
```

Pilih emulator/device yang muncul.

> **Untuk Android Emulator:** API URL otomatis `http://10.0.2.2:3000/v1` (localhost dari emulator).
> **Untuk Chrome/Web:** API URL harus `http://localhost:3000/v1`. Bisa diset di Settings nanti.

---

## 9. Testing

### Test 1 — Normal Flow

Buka app → Splash Screen → "Terhubung ✓" → Welcome page.

**Coba login:**
- **Pelanggan:** 081212345678 / customer123
- **Admin Toko:** 081234567890 / admin123
- **Admin Platform:** admin / admin

### Test 2 — Maintenance Mode

Di WSL, aktifkan maintenance:

```bash
# Set maintenance mode (env var)
export MAINTENANCE_MODE=true
# Atau lewat .env:
sed -i 's/MAINTENANCE_MODE=false/MAINTENANCE_MODE=true/' .env
docker compose restart backend

# Test
curl http://localhost:3000/v1/config
curl http://localhost:3000/v1/health  # tetap jalan
curl http://localhost:3000/v1/stores  # harus 503
```

App akan menunjukkan "Sedang dalam perbaikan" → Maintenance Screen.

Matikan maintenance:

```bash
sed -i 's/MAINTENANCE_MODE=true/MAINTENANCE_MODE=false/' .env
docker compose restart backend
```

### Test 3 — No Connection

Stop Docker:

```bash
docker compose down
```

App akan menunjukkan "Koneksi tidak ditemukan" → Maintenance Screen (auto-retry tiap 30 detik).

Start lagi:

```bash
docker compose up -d
```

### Test 4 — Switch Environment

Buka Settings di app → pilih "Local" atau "Production".

---

## 10. Command Penting

### Docker

```bash
# Start semua service
docker compose up -d

# Stop semua service
docker compose down

# Restart backend saja
docker compose restart backend

# Lihat log backend
docker compose logs backend --tail 50

# Follow log (real-time)
docker compose logs -f backend

# Rebuild image (setelah ubah kode)
docker compose up -d --build

# Masuk ke container backend
docker compose exec backend sh
```

### Environment

```bash
# Switch ke local
bash switch-env.sh local

# Switch ke production (future)
bash switch-env.sh production

# Lihat environment saat ini
bash switch-env.sh status
```

### Database

```bash
# Push schema (buat/update tabel)
docker compose exec backend npx prisma db push

# Seed data
docker compose exec backend npx prisma db seed

# Buka Prisma Studio (GUI database)
docker compose exec backend npx prisma studio
```

### Flutter

```powershell
cd frontend

# Install dependencies
flutter pub get

# Run app
flutter run

# Clean build
flutter clean
flutter pub get
flutter run
```

---

## Troubleshooting

### "Docker Engine permission denied"

```bash
# Fix permission
sudo usermod -aG docker $USER
exit
# Buka WSL lagi
```

### "Container is restarting" / backend crash

```bash
# Cek log
docker compose logs backend --tail 50
```

### "Database not in sync with schema"

```bash
# Jalankan ulang
docker compose exec backend npx prisma db push
```

### Flutter error "cannot find shared_preferences"

```powershell
flutter pub add shared_preferences
```

---

## Arsitektur

```
┌──────────────┐     ┌──────────────────┐     ┌──────────────┐
│  Flutter App │────▶│  Backend (NestJS)│────▶│  PostgreSQL  │
│  (Mobile)    │     │  :3000           │     │  :5432       │
└──────────────┘     │                  │     └──────────────┘
                     │  Redis :6379     │
                     └──────────────────┘
```

### Endpoint Baru

| Endpoint | Method | Auth | Deskripsi |
|----------|--------|------|-----------|
| `/v1/config` | GET | No | Environment info, maintenance status |
| `/v1/health` | GET | No | Health check (existing) |

### File Environment

| File | Untuk |
|------|-------|
| `.env.local` | Local development (Docker) |
| `.env.production` | Production (Supabase + SumoPod) |
| `.env` | Aktif saat ini (copy dari .env.local/production) |
| `switch-env.sh` | Script switch environment |

---

**Selesai!** Kalau ada error, kabari aku.
