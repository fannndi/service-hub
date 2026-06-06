# Task List — ServisGadget Foundation

---

## 1. Fandi — Phase 1 (Backend Foundation)

### Inisialisasi Project
- [x] Inisialisasi monorepo: NestJS shell, strict TypeScript, ESLint, Jest
- [x] Docker Compose: PostgreSQL 16, Redis 7, backend service
- [x] Konfigurasi Prisma schema (21 model, 20+ enum) dari Master PRD
- [x] Prisma migration + seed data (store, admin, customers, spareparts)
- [x] Config module: typed environment variables
- [x] Prisma module + PrismaService lifecycle
- [x] Redis module + BullMQ module
- [x] Swagger documentation setup (`/docs`)
- [x] Global exception filter (API error codes, Bahasa Indonesia messages)

### Autentikasi
- [x] Customer authentication: `POST /v1/auth/login`, JWT strategy, stealth account auto-create
- [x] Customer authentication: change-password, logout, session management, session list
- [x] Store admin authentication: `POST /v1/store/auth/login`, JWT strategy terpisah
- [x] Store admin authentication: change-password, logout, session management
- [x] Common guards & decorators: CustomerJwtGuard, StoreJwtGuard, GetUser

### Modul Bisnis
- [x] Stores module: CRUD toko, GET public store listing
- [x] Spareparts module: CRUD sparepart, GET public (untuk store detail customer)
- [x] Orders module: createOrder (stealth account, stock reservation, coupon validation, nanoid)
- [x] Orders module: approveOrder (decrement qty + qtyReserved)
- [x] Orders module: rejectOrder (rollback qtyReserved)
- [x] Orders module: updateStatus (state machine + SLA reset, assertValidTransition)
- [x] Orders module: submitDiagnosis (replaced sparepart validation, finalPrice calc)
- [x] Payments module: createPayment (proof validation)
- [x] Payments module: confirmPayment (warranty assignment from store.config.warranty_days, totalCompleted)
- [x] Reviews module: createReview (duplicate check, ratingAvg recalculation)
- [x] Reviews module: reward coupon creation dalam transaksi (Rp10.000, expired +30 hari)
- [x] Disputes module: createDispute (warranty check, active dispute guard)
- [x] Disputes module: respondDispute (warranty order creation saat store_accepted)
- [x] Notifications module: WhatsApp send dengan 3x exponential retry
- [x] Notifications module: FailedNotification logging
- [x] Notifications module: kirim notif ke store (newOrder, waitingPayment, diagnosisResult, orderCompleted)
- [x] Uploads module: S3 presigned URL generation
- [x] Me endpoints: `GET /v1/me/summary`, `GET /v1/me/orders`, `GET /v1/me/orders/:id/progress`, `GET /v1/me/notifications`

### Background Jobs
- [x] SlaMonitorJob (30s cron): SLA warning + breach tracking, notifikasi store + customer
- [x] CredentialCleanerJob (30min cron): hapus credentialPlainEnc setelah 24 jam

### Bug Fixes (B1–B11)
- [x] B1 — itemPrice pakai harga dari sparepart.price
- [x] B2 — qtyReserved increment saat createOrder
- [x] B3 — Decrement qty + qtyReserved saat approveOrder
- [x] B4 — POST /v1/orders PUBLIC (tanpa auth, untuk booking)
- [x] B5 — Separate store auth (tidak share JWT dengan customer)
- [x] B6 — Validasi kepemilikan kupon (coupon ownership)
- [x] B7 — warrantyDays dari store.config, bukan hardcoded
- [x] B8 — ratingAvg recalculation setelah createReview
- [x] B9 — Coupon reward dalam transaksi createReview
- [x] B10 — nanoid untuk order number, bukan UUID
- [x] B11 — Validasi replacedSparepartId tidak boleh = sparepartId asli

### API Path Alignment
- [x] Payments/Reviews/Disputes nested di bawah `/v1/orders/:id/...` sesuai kontrak Master PRD
- [x] Upload presigned URL: `POST /v1/uploads/presign`
- [x] Store diagnosis/status: PATCH (bukan POST)
- [x] Spareparts GET dibuat public untuk store detail customer

---

## 2. Andriyan — Phase 2 (Customer Flutter App)

### Shared Foundation
- [x] Flutter shared foundation: Dio client, interceptor, token refresh
- [x] Token storage abstraction (flutter_secure_storage)
- [x] Network error mapper, base repository, API response models
- [x] App config provider
- [x] Shared widgets: StatusBadge, SectionHeader, KeyValueRow, SearchFilterBar

### Autentikasi
- [x] Splash screen + auto-redirect berdasarkan auth state
- [x] Login screen (nomor HP + password)
- [x] ChangePassword screen
- [x] Profile screen: info user, daftar sesi, logout
- [x] GoRouter configuration: customer routes, auth guard redirect
- [x] AuthNotifier provider: login/logout/session management
- [x] CustomerAuthRepository
- [x] Session storage + interceptor token refresh

### Beranda & Toko
- [x] Home screen: greeting, ringkasan activeOrders, activeCoupons, activeWarranty
- [x] Home screen: daftar toko terbaru, shortcut ke notifikasi & kupon
- [x] StoreList screen: pencarian & daftar toko servis
- [x] StoreDetail screen: info toko, rating, sparepart tersedia, ulasan
- [x] StoreCard widget

### Booking & Order
- [x] BookingForm screen: pilih sparepart, isi data HP & nama, submit
- [x] SparePartSelectorSheet widget: pilih sparepart dari daftar
- [x] BookingSuccess screen: konfirmasi order + info akun stealth
- [x] OrderList screen: filtered, paginated, status badges
- [x] OrderDetail screen: detail order, status, tindakan yang tersedia
- [x] OrderStatusTimeline widget: visualisasi status order
- [x] DiagnosisApprovalCard widget: setujui/tolak diagnosis
- [x] StoreRepository
- [x] OrderRepository

### Tracking Real-time
- [x] Tracking screen: timeline tracking order
- [x] OrderTracking provider: 30 detik polling Stream
- [x] Notifications screen: daftar event tracking terbaru

### Pembayaran, Ulasan, Garansi
- [x] PaymentUpload screen: upload bukti pembayaran (image picker)
- [x] ReviewForm screen: rating bintang + komentar
- [x] ReviewSuccess screen: konfirmasi + CouponRewardBanner (kupon Rp10.000)
- [x] CouponRewardBanner widget
- [x] WarrantyClaim screen: form klaim garansi
- [x] Coupons screen: daftar kupon yang dimiliki
- [x] PaymentRepository
- [x] ReviewRepository
- [x] DisputeRepository

### Error Handling & Testing
- [x] Error handler: mapping API error code → pesan Bahasa Indonesia
- [x] Widget test: smoke test ServisGadgetApp
- [x] Provider test: customer provider
- [x] Repository test: customer repository

---

## 3. Nissa — Phase 3 (Store Admin Flutter App + Backend Extension)

### Backend Extension (Endpoint Store Admin)
- [x] POST /v1/store/auth/logout — Store admin logout
- [x] POST /v1/store/orders/:id/actions/:action — Dynamic action endpoint (state machine mapping)
- [x] GET /v1/store/orders/:id/tracking — Tracking timeline
- [x] POST /v1/store/orders/:id/tracking — Manual tracking entry
- [x] GET /v1/store/customers — Customer list per store
- [x] GET /v1/store/payments — Payment list per store
- [x] GET /v1/store/reviews — Review list per store
- [x] POST /v1/store/reviews/:id/response — Respond to review
- [x] GET /v1/store/notifications — Notification feed
- [x] GET /v1/store/profile — Store admin profile + store info
- [x] PATCH /v1/store/profile — Update store admin profile
- [x] GET /v1/store/analytics — 30-day analytics (orders, revenue, rating)
- [x] POST /v1/store/orders/:id/payments/:paymentId/confirm — Payment confirmation
- [x] PATCH /v1/store/orders/:id/diagnosis — Diagnosis update
- [x] Extend StoresService: customers, payments, reviews, notifications, profile, analytics methods
- [x] Extend OrdersService: getStoreOrderTracking + addStoreOrderTracking

### Store Admin Flutter App

#### Setup & Auth
- [x] Store admin GoRouter: auth guard, separate routing tree
- [x] Separate Dio client + token storage (tidak share dengan customer)
- [x] StoreLogin screen
- [x] StoreChangePassword screen
- [x] StoreAuthController provider
- [x] StoreAuthRepository

#### Dashboard
- [x] Dashboard screen: ringkasan order, pendapatan, rating
- [x] DashboardSummary model + Stream provider (60s polling)
- [x] Combined main.dart: role-based splash router (customer vs store admin)

#### Manajemen Order
- [x] OrderList screen: filtered list dengan StatusBadge
- [x] OrderDetail screen: detail order + allowedActions state machine
- [x] Diagnosis screen: DiagnosisItemRow, pilih replaced sparepart, hitung finalPrice
- [x] Order tracking: timeline + tambah entry manual
- [x] Tracking screen untuk store admin
- [x] SlaCountdownBadge widget: indikator SLA
- [x] StoreOrderRepository
- [x] StoreOrderDetail provider

#### Pembayaran & Inventori
- [x] PaymentConfirmation screen: konfirmasi pembayaran + warranty reminder
- [x] PaymentProofViewer widget: lihat bukti pembayaran
- [x] Inventory screen: daftar sparepart dengan status stok
- [x] SparepartForm screen: tambah/edit sparepart
- [x] InventoryItemCard widget
- [x] InventoryList provider
- [x] StoreInventoryRepository

#### Dispute, Pelanggan & Lainnya
- [x] DisputeList screen: daftar klaim garansi
- [x] DisputeDetail screen: detail dispute + respond form
- [x] StoreDisputeRepository
- [x] Customer list screen
- [x] CredentialPanelCard widget: panel kredensial pelanggan baru
- [x] Settings screen: warranty days, stock threshold
- [x] Review list + respond to review
- [x] Notification feed screen

#### Testing
- [x] Widget test: store admin login smoke test
- [x] Model test: store_admin_model_test
