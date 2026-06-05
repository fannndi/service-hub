# Changelog








## 2026-06-02 — Final safe scaffold pass before stop

### Added
- Added shared change-password shell.
- Added Store Admin inventory form shell.
- Added Store Admin dispute detail/respond shell.
- Connected Customer profile to coupons and change password.
- Connected Store inventory add action to inventory form.
- Connected Store dispute list to dispute detail.
- Added final handoff doc at `docs/final-partial-handoff-phase-02-03.md`.

### Stop Decision
- This is the maximum safe helper scope for Phase 02/03.
- Further work should be done by Phase 02/03 owners because it requires final provider architecture, backend/Supabase wiring, persistence, validation, and PRD acceptance testing.
## 2026-06-02 — Thin stop-boundary and filter scaffolds

### Added
- Added `docs/stop-boundary-phase-02-03.md` to define safe stopping point for helper work.
- Added reusable `SearchFilterBar` widget.
- Added filter/search UI to Customer order list.
- Added filter/search UI to Store Admin order list.
- Added Customer dispute/warranty claim shell.
- Connected Customer warranty claim actions to dispute shell.

### Stop Reminder
- Stop before backend/Supabase integration, real persistence, business state transitions, upload implementation, and final provider architecture.
- Phase 02/03 owners should finalize repositories, state management, UX validation, and API wiring.
## 2026-06-02 — Role bottom navigation scaffolds

### Added
- Added shared loading, error, and app info card widgets.
- Added Customer bottom navigation shell: Home, Order, Kupon, Profil.
- Added Store Admin bottom navigation shell: Home, Order, Stok, Setting.
- Updated app entrypoint to route logged-in dummy users into role-specific shells.

### Scope Note
- Navigation remains local Flutter-only.
- Older home screens are kept as reference but no longer used by `main.dart`.
## 2026-06-02 — Thin UX helpers for Phase 02/03 review

### Added
- Shared `StatusBadge`, `SectionHeader`, and `KeyValueRow` widgets.
- Customer notifications screen.
- Customer coupons screen.
- Store notifications screen.
- Store SLA countdown badge widget.
- Store credential panel card matching Phase 03 credential handoff concept.
- Connected notification/coupon shortcuts on Customer home.
- Connected store notification shortcut and credential panel on Store order detail.

### Scope Note
- Components are visual scaffolds only.
- Copy, mark-sent, SLA countdown, and notification delivery are not persisted yet.
## 2026-06-02 — Extra thin Phase 02/03 scaffolds

### Added
- Customer payment upload shell.
- Customer review and coupon shell.
- Customer profile shell.
- Store diagnosis form shell with replaced sparepart field hint.
- Store payment confirmation shell with warranty reminder.
- Store settings shell for warranty days and stock threshold.
- Connected order-detail actions to diagnosis/payment screens.

### Scope Note
- All new actions remain UI-only references for Phase 02/03 implementers.
- Backend, Supabase, validation persistence, and business state transitions are not wired yet.
## 2026-06-02 — Partial Phase 02/03 navigation layer

### Added
- Added dummy service order and sparepart data.
- Added Customer create order shell.
- Added Customer order list and order detail shell.
- Added Store Admin order list and order detail shell.
- Added Store Admin inventory shell.
- Added Store Admin dispute shell.
- Connected Customer and Store Admin home menu cards to dummy screens.

### Scope Note
- Screens are local UI scaffolds only.
- Buttons are visual actions until backend/Supabase contracts are wired.
## 2026-06-02 — Fix Flutter widget test

### Fixed
- Updated `frontend/test/widget_test.dart` from old `MyApp` counter template to `ServisGadgetApp` dummy login smoke test.
## 2026-06-02 — Partial Phase 02/03 dummy login

### Added
- Added local dummy Customer and Store Admin accounts.
- Added login screen with role switcher and quick dummy login.
- Added Customer home shell with Phase 02 placeholder menus.
- Added Store Admin home shell with Phase 03 placeholder menus and simple metrics.
- Added local logout.
- Added handoff doc at `docs/partial-phase-02-03-dummy.md`.

### Dummy Credentials
- Customer: `081234567890` / `customer123`.
- Admin Toko: `081298765432` / `admin123`.

### Scope Note
- This is intentionally partial UI/auth simulation only.
- No backend auth, Supabase, database, or business flow integration yet.
## 2026-06-02 — Audit setelah Flutter launch

### Status
- Flutter Android launch berhasil di mesin user setelah wrapper Android dibuat.
- Repo saat ini valid sebagai bootstrap runnable, bukan implementasi lengkap Phase 1 Foundation.
- Audit detail tersedia di `docs/foundation-status-audit.md`.

### Audit Ringkas
- Ada: NestJS shell, health endpoint, Swagger setup, Prisma schema PRD, Docker Compose, Flutter shared starter.
- Belum ada: auth customer/store, migrations, seed, Prisma module, Redis/BullMQ module, domain CRUD/services, business rules Foundation, jobs, upload, notification, tests scaffold lengkap.
- AC-01 sampai AC-30 belum bisa dianggap hijau.

### Next Work Priority
1. Backend infrastructure: config, database module, Prisma service, Redis module.
2. Prisma migration + seed.
3. CustomerAuthModule dan StoreAuthModule terpisah.
4. Store + Sparepart CRUD.
5. Order/payment/review/dispute services dengan transaction safety.
6. Jobs, upload, notifications.
7. Flutter shared models/repositories sesuai API final.

## 2026-06-02 — Phase 1 Foundation bootstrap

### Added
- Created monorepo layout for Phase 1 Foundation only.
- Added backend NestJS runnable shell under `backend`.
- Added strict TypeScript config, Nest CLI config, Jest config, and package scripts.
- Added `/v1/health` endpoint and Swagger setup at `/docs`.
- Added official Prisma schema extracted from `00_MASTER_PRD.md` into `backend/prisma/schema.prisma`.
- Added Flutter shared foundation under `frontend/lib`:
  - app shell in `main.dart`
  - app config provider
  - Dio client provider
  - token storage abstraction
  - network error mapper
  - base repository
  - shared API response model
  - generic empty state widget
- Added Docker Compose with PostgreSQL 16, Redis 7, and backend service.
- Added backend Dockerfile.
- Added `.env.example` and local `.env` copy.
- Added architecture docs and run guide.

### Scope Guard
- No Customer screens added.
- No Store Admin screens added.
- No dashboard or feature flows added.
- No feature-specific shortcuts added.

### Known Environment Note
- PowerShell blocks `npm.ps1`; use `cmd /c npm ...` or update local execution policy.
- Run Flutter Android generation from `frontend`, not repo root.

### Next Foundation Work
- Install backend dependencies and run Prisma validation.
- Implement typed config module.
- Implement database module with Prisma lifecycle.
- Implement Redis module and BullMQ module.
- Split customer/store auth modules with independent JWT strategies and guards.
- Implement repository/service/controller layers per domain.
- Generate Prisma migration from schema.
- Fill `docs/integration-guide.md` with final contracts after endpoints are implemented.








