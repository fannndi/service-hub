# Customer Integration Notes

Tanggal: 2026-06-03

## Scope Implementasi

- Phase 2 Customer App diimplementasikan di `frontend/lib/features/customer/`.
- Backend, Prisma, Redis, BullMQ, store admin screens, dan store admin business flow tidak diubah.
- `frontend/lib/core`, `frontend/lib/network`, dan `frontend/lib/storage` tidak dimodifikasi. Customer branch membuat session storage dan Dio client khusus di feature layer untuk menghindari konflik dengan Foundation.

## File Shared yang Disentuh

- `frontend/pubspec.yaml`: menambahkan dependency Phase 2 (`go_router`, `image_picker`, `cached_network_image`).
- `frontend/lib/main.dart`: mengganti dummy role-switch entrypoint dengan Customer GoRouter app.

## Kontrak API yang Dikonsumsi

- `POST /v1/auth/login`
- `POST /v1/auth/change-password`
- `POST /v1/auth/logout`
- `GET /v1/me`
- `PATCH /v1/me`
- `GET /v1/me/summary`
- `GET /v1/stores`
- `GET /v1/stores/:id`
- `GET /v1/store/spareparts?storeId=:id`
- `POST /v1/orders` menggunakan public Dio tanpa Authorization header.
- `GET /v1/me/orders`
- `GET /v1/orders/:id`
- `GET /v1/me/orders/:id/progress`
- `POST /v1/orders/:id/approve`
- `POST /v1/orders/:id/reject`
- `POST /v1/uploads/presign`
- `POST /v1/orders/:id/payments`
- `POST /v1/orders/:id/reviews`
- `POST /v1/orders/:id/disputes`
- `GET /v1/me/coupons`
- `GET /v1/me/notifications`

## Foundation Dependency

Repo audit masih menyatakan Foundation belum menyediakan endpoint nyata. UI, route, providers, repositories, upload flow, and request shapes are implemented against the PRD contracts and will become fully verifiable after Foundation is completed.
