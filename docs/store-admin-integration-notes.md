# Store Admin Integration Notes

Tanggal: 2026-06-06 (Updated after Phase 1 & 3 merge)

## Status

Semua endpoint Store Admin sudah tersedia di backend Foundation. UI dan backend sudah selaras.

## Scope

Phase 03 Store Admin diimplementasikan di `frontend/lib/features/store_admin/`.

## Endpoint yang Dikonsumsi (seluruhnya tersedia)

| Frontend Path | Backend Controller | Status |
|---|---|---|
| `POST /v1/store/auth/login` | StoreAuthController | ✓ |
| `POST /v1/store/auth/change-password` | StoreAuthController | ✓ |
| `POST /v1/store/auth/logout` | StoreAuthController | ✓ (new) |
| `GET /v1/store/dashboard/summary` | StoreDashboardController | ✓ |
| `GET /v1/store/orders` | StoreOrdersController | ✓ |
| `GET /v1/store/orders/:id` | StoreOrdersController | ✓ |
| `POST /v1/store/orders/:id/actions/:action` | StoreOrdersController | ✓ (new) |
| `POST /v1/store/orders/:id/diagnosis` | StoreOrdersController | ✓ |
| `PATCH /v1/store/orders/:id/diagnosis` | StoreOrdersController | ✓ |
| `PATCH /v1/store/orders/:id/status` | StoreOrdersController | ✓ |
| `GET /v1/store/orders/:id/tracking` | StoreOrdersController | ✓ (new) |
| `POST /v1/store/orders/:id/tracking` | StoreOrdersController | ✓ (new) |
| `GET /v1/store/spareparts` | SparepartsController | ✓ |
| `POST /v1/store/spareparts` | SparepartsController | ✓ |
| `PATCH /v1/store/spareparts/:id` | SparepartsController | ✓ |
| `GET /v1/store/customers` | StoreDashboardController | ✓ (new) |
| `GET /v1/store/payments` | StoreDashboardController | ✓ (new) |
| `POST /v1/store/orders/:orderId/payments/:paymentId/confirm` | StoreOrdersController | ✓ (new path) |
| `GET /v1/store/reviews` | StoreDashboardController | ✓ (new) |
| `POST /v1/store/reviews/:id/response` | StoreDashboardController | ✓ (new) |
| `GET /v1/store/disputes` | StoreDisputesController | ✓ |
| `POST /v1/store/disputes/:id/respond` | StoreDisputesController | ✓ |
| `GET /v1/store/notifications` | StoreDashboardController | ✓ (new) |
| `GET /v1/store/profile` | StoreDashboardController | ✓ (new) |
| `PATCH /v1/store/profile` | StoreDashboardController | ✓ (new) |
| `GET /v1/store/analytics` | StoreDashboardController | ✓ (new) |
| `POST /v1/uploads/presign` | UploadsController | ✓ |

## Actions Mapping

Frontend menggunakan `POST /v1/store/orders/:id/actions/:action` dinamis. Backend menerjemahkan:

| Action | Status |
|---|---|
| `receive_device` | `device_received` |
| `start_diagnosis` | `diagnosing` |
| `sparepart_arrived` / `start_repair` | `repairing` |
| `complete_repair` / `start_qc` | `quality_check` |
| `qc_ok` / `request_payment` | `waiting_payment` |

## Verifikasi

- `tsc --noEmit`: 0 error
- `nest build`: sukses
- Seluruh 27 endpoint tersedia di backend
