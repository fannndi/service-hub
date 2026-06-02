# Final Partial Handoff — Phase 02/03 Flutter Helpers

Tanggal: 2026-06-02

## Status
Batas maksimal bantuan ringan sudah tercapai. App memiliki dummy login, role shells, screen scaffolds, local dummy data, dan reusable visual widgets. Semua masih Flutter-only.

## Customer Shells
- Login dummy customer.
- Dashboard customer.
- Create service form shell.
- Order list + filter/search.
- Order detail.
- Payment upload shell.
- Review/coupon shell.
- Coupon list shell.
- Notification list shell.
- Warranty/dispute claim shell.
- Profile shell.
- Change password shell.

## Store Admin Shells
- Login dummy admin toko.
- Dashboard admin.
- Order list + filter/search + SLA badge.
- Order detail + credential panel.
- Diagnosis form shell.
- Payment confirmation shell.
- Inventory list shell.
- Inventory form shell.
- Dispute list shell.
- Dispute detail/respond shell.
- Store notifications shell.
- Store settings shell.

## Shared Widgets
- App info card.
- Empty state.
- Error state.
- Loading state.
- Status badge.
- SLA countdown badge.
- Credential panel card.
- Search/filter bar.
- Section header.
- Key-value row.

## Hard Stop
Do not continue in this helper scope beyond this point. Next work belongs to Phase 02/03 owners:
- Supabase/API integration.
- Final Riverpod providers.
- Real repositories.
- Auth persistence.
- Upload implementation.
- Business validation.
- State transitions.
- Backend contract alignment.
- UI polish and acceptance testing.

## Suggested Next Prompt For Teammates' Codex
Read `00_MASTER_PRD.md`, `02_PHASE_CUSTOMER.md`, `03_PHASE_STORE_ADMIN.md`, `docs/stop-boundary-phase-02-03.md`, and this handoff. Treat existing Flutter files as non-final scaffolds. Validate correctness against PRD, then replace or wire them to final API/Supabase architecture without preserving dummy logic unnecessarily.
