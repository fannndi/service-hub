# Secrets — ServisGadget Environment Files

> Folder ini berisi file environment untuk development dan production.
> **JANGAN di-commit ke Git.** Folder ini di-share manual antar anggota tim.

---

## Cara Pakai

### 1. Setup Awal

Copy folder `secrets/` ini ke root project:

```
service-hub/
├── secrets/          ← folder ini (di-share manual)
├── backend/
├── frontend/
├── docker-compose.yml
├── switch-env.sh
└── ...
```

### 2. Switch Environment

```bash
# Local development (Docker)
bash switch-env.sh local

# Production deployment
bash switch-env.sh production

# Cek environment saat ini
bash switch-env.sh status
```

### 3. Run

```bash
# Local development
docker compose up -d --build

# Backend di: http://localhost:3000
# Swagger di: http://localhost:3000/docs
```

---

## File di Folder Ini

| File | Untuk | Wajib? |
|------|-------|--------|
| `.env.local` | Local development (Docker) | ✅ Ya |
| `.env.production` | Production (VPS) | ✅ Ya |

## Catatan Penting

- `.env.local` bisa langsung dipakai untuk development (secrets development-safe)
- `.env.production` WAJIB diisi sendiri — ganti semua `[PLACEHOLDER]`
- Jangan commit folder ini ke Git
- Untuk anggota baru: cukup copy folder ini ke root project
