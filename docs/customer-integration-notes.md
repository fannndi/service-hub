# Customer Integration Notes

Tanggal: 2026-06-06 (Updated after Phase 1 Foundation merge)

## Status

Foundation backend sekarang sudah lengkap (Phase 1 + Phase 2 merge). Semua endpoint yang dikonsumsi customer app sudah tersedia dan path sudah diselaraskan dengan kontrak Master PRD.

## Scope Implementasi

- Phase 2 Customer App diimplementasikan di `frontend/lib/features/customer/`.
- Phase 1 Foundation Backend lengkap di `backend/src/modules/` (auth, store-auth, users, stores, spareparts, orders, payments, reviews, disputes, notifications, uploads, jobs).
- `frontend/lib/core`, `frontend/lib/network`, dan `frontend/lib/storage` tidak dimodifikasi (Phase 2).

## File Shared yang Disentuh

- `frontend/pubspec.yaml`: dependency Phase 2 (`go_router`, `image_picker`, `cached_network_image`).
- `frontend/lib/main.dart`: Customer GoRouter app sebagai entry point.

## Kontrak API yang Dikonsumsi (seluruhnya tersedia di backend)

| Frontend Path | Backend Controller | Status |
|---|---|---|
| `POST /v1/auth/login` | AuthController | ✓ |
| `POST /v1/auth/change-password` | AuthController | ✓ |
| `POST /v1/auth/logout` | AuthController | ✓ |
| `GET /v1/me` | UsersController | ✓ |
| `PATCH /v1/me` | UsersController | ✓ |
| `GET /v1/me/summary` | UsersController | ✓ (new) |
| `GET /v1/me/coupons` | UsersController | ✓ |
| `GET /v1/me/orders` | UsersController → OrdersService | ✓ (new) |
| `GET /v1/me/orders/:id/progress` | UsersController → OrdersService | ✓ (new) |
| `GET /v1/me/notifications` | UsersController | ✓ (new) |
| `GET /v1/stores` | StoresController | ✓ |
| `GET /v1/stores/:id` | StoresController | ✓ |
| `GET /v1/stores/:id/spareparts` | StoresController | ✓ (new) |
| `GET /v1/store/spareparts?storeId=` | SparepartsController | ✓ (now public) |
| `POST /v1/orders` (PUBLIC) | OrdersController | ✓ |
| `GET /v1/orders/:id` | OrdersController | ✓ |
| `POST /v1/orders/:id/approve` | OrdersController | ✓ |
| `POST /v1/orders/:id/reject` | OrdersController | ✓ |
| `POST /v1/orders/:id/payments` | OrdersController → PaymentsService | ✓ (path aligned) |
| `POST /v1/orders/:id/reviews` | OrdersController → ReviewsService | ✓ (path aligned) |
| `POST /v1/orders/:id/disputes` | OrdersController → DisputesService | ✓ (path aligned) |
| `POST /v1/uploads/presign` | UploadsController | ✓ (path aligned) |

## Path Alignment Notes

Backend paths diselaraskan dengan Master PRD dan kontrak frontend:
- Payments, Reviews, Disputes sekarang nested di bawah `/v1/orders/:id/`
- Uploads presigned URL: `/v1/uploads/presign` (bukan `presigned-url`)
- Store orders admin menggunakan `PATCH` (bukan `POST`) untuk diagnosis dan status update
- Spareparts endpoint sekarang PUBLIC untuk akses customer store detail screen
