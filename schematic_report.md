# 🤖 AI Agent Test Report

**Generated:** 2026-07-02 20:42:24.297414

---

## 📊 Summary

Test Suite Summary
============================================================
Total:     3
Passed:    0 ✅
Failed:    3 ❌
Errored:   0 ⚠️
Duration:  21s

  ❌ guest-booking: 0/1 passed
  ❌ platform-admin: 2/3 passed
  ❌ db-inspection: 0/1 passed


---
## 📋 Scenario Details

### ❌ Guest booking sparepart — verifikasi order via track

| Step | Status | Detail |
|------|--------|--------|
| create-guest-order | ❌ | success: expected "true", got "false"; data.order_id is null ✗; data.order_number is null ✗ |

**Debug:**
```
🔍 DEBUG REPORT
============================================================
Scenario: Guest booking sparepart — verifikasi order via track
Failed at: Step "create-guest-order": assertion failed

Root Causes:

```

### ❌ Platform admin login → applications → DB query

| Step | Status | Detail |
|------|--------|--------|
| login-admin | ✅ | data.email is present ✓ |
| list-applications | ✅ | success = true ✓; data is present ✓ |
| query-stores | ❌ | success: expected "true", got "null"; data is present ✓ |

**Debug:**
```
🔍 DEBUG REPORT
============================================================
Scenario: Platform admin login → applications → DB query
Failed at: Step "query-stores": assertion failed

Root Causes:

```

### ❌ Database inspection via admin API — stores, spareparts, orders

| Step | Status | Detail |
|------|--------|--------|
| query-spareparts | ❌ | success: expected "true", got "null"; data is present ✓ |

**Debug:**
```
🔍 DEBUG REPORT
============================================================
Scenario: Database inspection via admin API — stores, spareparts, orders
Failed at: Step "query-spareparts": assertion failed

Root Causes:

```

---
## 📖 Panduan Pengguna

# 📱 Panduan Penggunaan Service Me

> Panduan ini dibuat oleh AI Agent setelah testing otomatis.
> Setiap langkah sudah diverifikasi berhasil.

## ⚠️ Booking Servis (Tanpa Login) — Belum Terverifikasi
Scenario ini gagal di testing agent. Lihat debug report.

## ⚠️ Platform Admin: Kelola Aplikasi — Belum Terverifikasi
Scenario ini gagal di testing agent. Lihat debug report.

## ⚠️ db-inspection — Belum Terverifikasi
Scenario ini gagal di testing agent. Lihat debug report.

---
## Tabel Login

| Role | Credentials |
|------|-------------|
| Pelanggan | No. HP + password (daftar otomatis) |
| Store Admin | Dibuat oleh Platform Admin |
| Platform Admin | `admin` / `admin123` |

