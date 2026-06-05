# Store Admin Integration Notes

Tanggal: 2026-06-05

## Scope

Phase 03 Store Admin diimplementasikan di `frontend/lib/features/store_admin/`.

Shared Foundation tidak diubah:

- `frontend/lib/core`
- `frontend/lib/network`
- `frontend/lib/storage`
- `backend`
- `backend/prisma`

Perubahan kecil di `frontend/lib/screens/customer_dispute_screen.dart` dan `frontend/lib/screens/customer_payment_screen.dart` hanya menambahkan `const` untuk meloloskan analyzer pada scaffold dummy Phase 01. Tidak ada perubahan alur customer, kontrak API, atau routing customer.

## Endpoint yang Dikonsumsi

- `POST /v1/store/auth/login`
- `POST /v1/store/auth/change-password`
- `POST /v1/store/auth/logout`
- `GET /v1/store/dashboard/summary`
- `GET /v1/store/orders`
- `GET /v1/store/orders/:id`
- `POST /v1/store/orders/:id/actions/:action`
- `POST /v1/store/orders/:id/diagnosis`
- `GET /v1/store/orders/:id/tracking`
- `POST /v1/store/orders/:id/tracking`
- `GET /v1/store/spareparts`
- `POST /v1/store/spareparts`
- `PATCH /v1/store/spareparts/:id`
- `GET /v1/store/customers`
- `GET /v1/store/payments`
- `POST /v1/store/orders/:orderId/payments/:paymentId/confirm`
- `GET /v1/store/reviews`
- `POST /v1/store/reviews/:id/response`
- `GET /v1/store/disputes`
- `POST /v1/store/disputes/:id/respond`
- `GET /v1/store/notifications`
- `GET /v1/store/profile`
- `PATCH /v1/store/profile`
- `GET /v1/store/analytics`
- `POST /v1/uploads/presign`

## Verifikasi

- `flutter pub get`: sukses
- `flutter analyze`: sukses, no issues
- `flutter test`: sukses, 3 tests passed

## Gap Verifikasi End-to-End

Staging backend belum mengekspos semua controller Store Admin yang dibutuhkan PRD. Repository sudah siap konsumsi kontrak, tetapi uji end-to-end API perlu dilakukan setelah Foundation route/controller lengkap.
