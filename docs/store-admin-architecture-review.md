# Store Admin Architecture Review

Tanggal: 2026-06-05

## Basis Implementasi

Workspace ini dibuat dari `service-hub-main` / Phase 01 Foundation. Dokumen PRD yang dibaca:

- `00_MASTER_PRD.md`
- `01_PHASE_FOUNDATION.md`
- `02_PHASE_CUSTOMER.md` sebagai referensi saja
- `03_PHASE_STORE_ADMIN.md` sebagai scope utama

Dokumen staging yang dibaca:

- `CHANGELOG.md`
- `docs/architecture.md`
- `docs/customer-integration-notes.md`
- `docs/audit-phase-02.md`

## Boundary

Implementasi Phase 03 ditempatkan di `frontend/lib/features/store_admin/`.

Tidak ada perubahan backend, Prisma schema, migration, Redis, BullMQ, atau kontrak Foundation. Folder `frontend/lib/core`, `frontend/lib/network`, dan `frontend/lib/storage` tidak diubah.

## Struktur Feature

- `application/store_admin_providers.dart`: Riverpod `AsyncNotifier`, stream dashboard, query state order/inventory.
- `data/store_admin_repositories.dart`: Dio API client khusus store admin dan secure storage key `store_access_token`.
- `domain/store_admin_models.dart`: enum/status Foundation, DTO parser, paging, order, sparepart, payment, dispute, review, notification, analytics.
- `presentation/routing/store_admin_router.dart`: GoRouter dengan store auth guard dan first-login guard.
- `presentation/screens/store_admin_screens.dart`: auth, dashboard, orders, diagnosis, tracking, inventory, payments, reviews, disputes, customers, notifications, settings, analytics.
- `presentation/widgets/store_admin_widgets.dart`: scaffold adaptif, data table, search/filter/export toolbar, metric cards, status pill, chart, action panel.

## Keputusan Arsitektur

- Store Admin memakai token dan storage key terpisah dari customer: `store_access_token`, `store_refresh_token`, `store_id`.
- State machine order tidak di-hardcode di UI. Action panel hanya menampilkan `allowedActions` dari response backend.
- Repository feature-layer dibuat mandiri agar tidak mengubah shared `dioClientProvider` yang membaca token customer/default.
- Dashboard memakai `StreamProvider` polling 60 detik sesuai PRD.
- Tabel admin reusable mendukung struktur pagination, sorting/search/filter hook, bulk checkbox, dan export-ready action.

## Catatan Staging

Staging merge menunjukkan service backend untuk order/payment/dispute/sparepart sudah ada, tetapi controller nyata yang terdeteksi baru `auth` dan `uploads`. Karena itu Phase 03 mengikat endpoint sesuai PRD dan siap diverifikasi saat Foundation controller lengkap.
