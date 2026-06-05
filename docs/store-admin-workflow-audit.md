# Store Admin Workflow Audit

Tanggal: 2026-06-05

## Order Lifecycle

Status Foundation yang dipakai UI:

`waiting_device -> device_received -> diagnosing -> waiting_approval -> waiting_sparepart -> repairing -> quality_check -> waiting_payment -> completed`

Status terminal/exception:

`cancelled`, `disputed`

UI tidak membuat daftar transisi sendiri. Tombol aksi order dibaca dari `allowedActions` response backend, lalu dikirim ke `POST /v1/store/orders/:id/actions/:action`.

## Diagnosis Lifecycle

Screen diagnosis mengumpulkan:

- Device Condition
- Damage Notes
- Repair Notes
- Technician Notes
- Estimated Cost
- Estimated Duration
- `diagnosisItems`
- `serviceFee`

Payload dikirim ke `POST /v1/store/orders/:id/diagnosis`. Validasi final tetap mengikuti backend Foundation.

## Service Tracking Lifecycle

Timeline dibaca dari `GET /v1/store/orders/:id/tracking`.

Event baru dikirim ke `POST /v1/store/orders/:id/tracking` dengan `title`, `note`, dan `status`.

## Sparepart Lifecycle

Inventory dibaca dari `GET /v1/store/spareparts`.

Create dan edit memakai:

- `POST /v1/store/spareparts`
- `PATCH /v1/store/spareparts/:id`

UI menghitung available stock sebagai `qty - qtyReserved` dan menampilkan low-stock alert saat available stock <= 2. Threshold final tetap sebaiknya berasal dari store config API ketika backend menyediakannya.

## Payment Lifecycle

Payment monitoring membaca `GET /v1/store/payments`.

Konfirmasi pembayaran disiapkan melalui `POST /v1/store/orders/:orderId/payments/:paymentId/confirm`. Backend Foundation tetap pemilik aturan warranty assignment, payment status, dan order completion.

## Dispute Lifecycle

Queue dispute membaca `GET /v1/store/disputes`.

Resolusi dispute memakai `POST /v1/store/disputes/:id/respond` dengan `accept` dan `reason`. UI menyediakan aksi terima/tolak, sedangkan validasi reason dan status update tetap di backend.

## Review, Notification, Store Profile, Analytics

- Review monitoring: `GET /v1/store/reviews`
- Review response: `POST /v1/store/reviews/:id/response`
- Notification center: `GET /v1/store/notifications`
- Store profile/settings: `GET/PATCH /v1/store/profile`
- Analytics: `GET /v1/store/analytics`

## Audit Result

Phase 03 frontend sudah memiliki struktur, routing, provider, repository, dan layar operasional untuk workflow Store Admin. Kesesuaian end-to-end masih menunggu controller Foundation lengkap untuk endpoint store admin selain auth/upload.
