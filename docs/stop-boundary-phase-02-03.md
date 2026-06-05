# Stop Boundary for Phase 02/03 Helpers

Tanggal: 2026-06-02

## Tujuan
File ini menjelaskan batas kontribusi ringan di branch ini agar tidak mengambil alih kerja Phase 02 Customer App dan Phase 03 Store Admin App.

## Yang Boleh Dilanjutkan Di Branch Ini
- UI shell non-final.
- Dummy local data.
- Shared visual components.
- Placeholder form fields sesuai PRD.
- Navigation proof-of-concept.
- Handoff docs dan changelog.

## Harus Berhenti Sebelum
- Implementasi backend API nyata untuk customer/store flows.
- Integrasi Supabase/database production.
- Business logic order/payment/review/dispute.
- State transition nyata.
- Upload file nyata.
- Auth persistence nyata.
- Riverpod architecture final milik Phase 02/03.
- Replacing desain/navigasi final teman satu tim.

## Titik Stop Disarankan
Berhenti setelah:
- Customer bisa login dummy, lihat dashboard, order dummy, detail order, payment/review/coupon/profile/notification scaffold.
- Store admin bisa login dummy, lihat dashboard, order dummy, detail order, diagnosis/payment/inventory/dispute/settings/notification scaffold.
- Semua aksi masih visual dan jelas ditandai dummy.

## Alasan
Phase 02 dan Phase 03 developer harus tetap menentukan:
- data flow final,
- provider naming,
- repository API final,
- validasi screen final,
- UX polishing,
- backend/Supabase wiring.
