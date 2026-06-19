# Task List — ServisGadget v2.1

> **Tim:** 3 orang — Fandi (Backend), Andriyan (Customer App), Nissa (Store Admin + Platform Admin)
> **Status:** v2.0 selesai. Sisa: production deployment, branding, docs final.
> **Last updated:** 2026-06-19

---

## 1. Fandi — Backend

### Yang Sudah Dikerjakan
- Monorepo NestJS, TypeScript strict, ESLint, Jest
- 15 modul bisnis: auth, orders, spareparts, payments, reviews, disputes, notifications, uploads, redis, jobs, store-auth, platform-admin, store-register, stores, users
- 3 sistem JWT terpisah (Customer, Store Admin, Platform Admin)
- 30/30 AC dari PRD tertutup tests
- Race condition fix: stock atomic via `$queryRawUnsafe`
- Session invalidation store admin (model + endpoint)
- Cloudflare tunnel auto-fetch dari GitHub
- 152 backend tests, semua passing

### Yang Masih Terbuka
- [ ] **Production Docker Compose** — Nginx reverse proxy, health checks, resource limits production-grade
- [ ] **Verifikasi Render deployment** — `render.yaml` belum di-test end-to-end
- [ ] **App icon** — butuh PNG 1024x1024 dari user untuk `frontend/assets/images/logo.png`
- [ ] **Branded splash screen** — `dart run flutter_native_splash:create` (setelah icon ready)

---

## 2. Andriyan — Customer App

### Yang Sudah Dikerjakan
- 27 customer screens: login, service flow, orders, payments, reviews, disputes, warranty, sessions
- 5-step booking wizard dengan sparepart selection
- Auto-fetch tunnel URL dari GitHub (3x retry + cache + maintenance mode)
- Token refresh mutex, Dio error handling
- 8 frontend model tests, semua passing

### Yang Masih Terbuka
- [ ] **UI redesign** — temen AI agent yang handle (perintah user)
- [ ] **Splash locale init** — `initializeDateFormatting('id_ID')` sudah ditambah, perlu build APK baru
- [ ] **Booking form cleanup** — brand/model pakai dropdown dari API (bukan free text)

---

## 3. Nissa — Store Admin + Platform Admin

### Yang Sudah Dikerjakan
- 15 screen files (split dari monolitik 961 lines)
- POS-style inventory: brand/model dropdown, +/- stock adjustment
- Dashboard KPI, analytics, order management
- Platform admin: login, store list, buat toko
- Responsive layout (NavigationRail / NavigationBar / Drawer)
- Admin session storage + auto-refresh

### Yang Masih Terbuka
- [ ] **UI redesign** — temen AI agent yang handle (perintah user)
- [ ] **Store admin logout fix** — perlu validasi refresh_token di backend sebelum push

---

## 4. Shared — DevOps & Dokumentasi

### Yang Sudah Dikerjakan
- GitHub Actions CI (backend + frontend)
- Docker Compose (Postgres 16 + Redis 7 + Backend)
- Multi-stage Dockerfile (Alpine, non-root)
- `render.yaml` untuk Render deployment
- `switch-env.sh` untuk local/production
- Cloudflare tunnel auto-fetch system

### Yang Masih Terbuka
- [ ] **Dokumentasi PRD** — update 3 phase PRD supaya match kode terkini
- [ ] **Dokumentasi deployment** — update env vars di `docs/deployment.md`
- [ ] **Dokumentasi run guide** — update env vars di `docs/run-guide.md`
- [ ] **CHANGELOG update** — tambah entry refactoring + sparepart POS + tunnel auto-fetch

---

## Ringkasan Progress

| Bagian | Selesai | Sisa |
|--------|---------|------|
| Fandi (Backend) | ~55 task | 4 task |
| Andriyan (Customer) | ~40 task | 3 task |
| Nissa (Store Admin) | ~35 task | 2 task |
| Shared (DevOps) | ~25 task | 4 task |
| **Total** | **~155 task** | **13 task** |

| Metrik | Nilai |
|--------|-------|
| Backend tests | 152 (12 suites) ✅ |
| Frontend tests | 23 (5 suites) ✅ |
| AC covered | 30/30 (100%) ✅ |
| Backend modules | 15 ✅ |
| Flutter screens | 45+ ✅ |
