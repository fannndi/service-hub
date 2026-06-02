# Partial Phase 02/03 Dummy Layer

Tanggal: 2026-06-02

## Tujuan
Memberi akses dummy supaya app bisa masuk sebagai Customer atau Admin Toko sebelum database/API Supabase tersedia.

## Kredensial Dummy

### Customer
- Nomor HP: `081234567890`
- Password: `customer123`
- Nama: `Budi Santoso`

### Admin Toko
- Nomor HP: `081298765432`
- Password: `admin123`
- Nama: `Admin GadgetCare`
- Toko: `GadgetCare Bandung`
- Store ID: `store_demo_gadgetcare`

## Scope Yang Dibuat
- Login lokal berbasis role.
- Tombol masuk cepat sebagai dummy.
- Customer home shell dengan menu Phase 02 placeholder.
- Store Admin home shell dengan menu Phase 03 placeholder.
- Logout lokal.

## Batasan
- Belum memakai backend auth.
- Belum memakai Supabase/database.
- Belum ada flow bisnis nyata.
- Data angka dashboard masih statis untuk navigasi awal.

## File Utama
- `frontend/lib/auth/demo_account.dart`
- `frontend/lib/auth/demo_auth_controller.dart`
- `frontend/lib/screens/demo_login_screen.dart`
- `frontend/lib/screens/customer_home_screen.dart`
- `frontend/lib/screens/store_admin_home_screen.dart`
- `frontend/lib/main.dart`
