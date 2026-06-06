# Changelog

## 2026-06-06 — Phase 3 Store Admin Merge + Full API Alignment

### Backend (15+ Endpoint Baru)
- `POST /v1/store/auth/logout` — store admin logout
- `POST /v1/store/orders/:id/actions/:action` — dynamic action endpoint (state machine mapping)
- `GET /v1/store/orders/:id/tracking` — tracking timeline
- `POST /v1/store/orders/:id/tracking` — manual tracking entry
- `GET /v1/store/customers` — customer list per store
- `GET /v1/store/payments` — payment list per store
- `GET /v1/store/reviews` — review list per store
- `POST /v1/store/reviews/:id/response` — respond to review
- `GET /v1/store/notifications` — notification feed
- `GET /v1/store/profile` — store admin profile + store info
- `PATCH /v1/store/profile` — update profile
- `GET /v1/store/analytics` — 30-day analytics (orders, revenue, rating)
- `POST /v1/store/orders/:id/payments/:paymentId/confirm` — payment confirmation
- `PATCH /v1/store/orders/:id/diagnosis` — diagnosis update
- Extended StoresService, OrdersService, StoreOrdersController

### Flutter — Store Admin App (Phase 3)
- `frontend/lib/features/store_admin/` — 14+ screens
- GoRouter with auth guard, store login/change-password, dashboard (60s polling)
- Screens: StoreLogin, StoreChangePassword, Dashboard, OrderList, OrderDetail, Diagnosis, Tracking, Inventory, SparepartForm, PaymentConfirmation, DisputeList, DisputeDetail, Settings
- Providers: StoreAuthController, DashboardSummary (Stream), StoreOrderDetail, InventoryList
- Repositories: StoreAuthRepository, StoreOrderRepository, StoreInventoryRepository, StoreDisputeRepository
- Widgets: CredentialPanelCard, DiagnosisItemRow, InventoryItemCard, SlaCountdownBadge, PaymentProofViewer
- Models: ServiceOrder, Sparepart, DisputeCase, DashboardSummary, CredentialPanel, StoreSession, ReviewItem, AnalyticsData

### Flutter — Combined Entrypoint
- Role-based splash router (`main.dart`) — auto-detect customer vs store admin auth session
- Separate Dio clients and token storage per role

---

## 2026-06-06 — Phase 1 Foundation Complete + Phase 2 Customer Merge

### Backend — Phase 1 Foundation (Complete)
- **Orders module**: createOrder (stealth account, stock reservation, coupon validation, nanoid), approveOrder, rejectOrder, updateStatus (state machine + SLA reset), submitDiagnosis
- **Payments module**: createPayment (proof validation), confirmPayment (warranty assignment, totalCompleted)
- **Reviews module**: createReview (duplicate check, ratingAvg recalculation, reward coupon in transaction)
- **Disputes module**: createDispute (warranty check, active guard), respondDispute (warranty order creation)
- **Notifications module**: WhatsApp send with 3x exponential retry + FailedNotification logging
- **Uploads module**: S3 presigned URL generation
- **Jobs module**: SlaMonitorJob (30s cron), CredentialCleanerJob (30min cron)
- **Auth**: Separate customer (`POST /v1/auth/*`) and store admin (`POST /v1/store/auth/*`) JWT strategies
- **11 Bug Fixes** from PRD: B1–B11 (itemPrice, qtyReserved, coupon ownership, warrantyDays, ratingAvg, nanoid, etc.)

### Flutter — Customer App (Phase 2)
- `frontend/lib/features/customer/` — 15+ screens
- GoRouter with auth guard, Riverpod state management
- Screens: Splash, Login, ChangePassword, Home, StoreList, StoreDetail, BookingForm, BookingSuccess, OrderList, OrderDetail, Tracking, PaymentUpload, ReviewForm, ReviewSuccess, WarrantyClaim, Profile, Sessions
- Providers: AuthNotifier, OrderTracking (30s polling Stream), CustomerOrders, OrderDetail
- Repositories: CustomerAuthRepository, StoreRepository, OrderRepository, PaymentRepository, ReviewRepository, DisputeRepository
- Error handler mapping API errors to Bahasa Indonesia messages
- Widgets: OrderStatusTimeline, StoreCard, DiagnosisApprovalCard, SparePartSelectorSheet, CouponRewardBanner

### API Path Alignment
- Payments/Reviews/Disputes nested under `/v1/orders/:id/...` (Master PRD contract)
- Upload presigned URL: `POST /v1/uploads/presign`
- Store diagnosis/status: PATCH instead of POST
- Customer endpoints: `GET /v1/me/orders`, `/v1/me/summary`, `/v1/me/orders/:id/progress`, `/v1/me/notifications`
- Spareparts GET made public for store detail screen

---

## 2026-06-02 — Phase 1 Bootstrap & Early Scaffolds

### Bootstrap
- Monorepo layout: `backend/`, `frontend/`, `docs/`, `infra/`
- NestJS 10.x runnable shell, strict TypeScript config, Swagger at `/docs`
- Prisma schema extracted from Master PRD (21 models, 20+ enums)
- Flutter shared foundation: Dio client, token storage, error mapper, base repository, API models
- Docker Compose: PostgreSQL 16, Redis 7, backend service

### Scaffold Iterations (5 commits)
- Dummy login (Customer + Admin Toko), role-based bottom navigation
- Shell screens for all customer and store admin flows
- Reusable widgets: StatusBadge, SectionHeader, KeyValueRow, SearchFilterBar, SlaCountdownBadge, CredentialPanelCard
- Flutter widget test updated from counter template to ServisGadgetApp

### Audit
- Foundation status audit: identified 37+ gaps
- Flutter Android launch verified successfully
- Stop boundary defined for Phase 2/3 work

---

**Status: All 3 phases complete — merged into `main`.**
