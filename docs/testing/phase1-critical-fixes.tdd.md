# TDD Evidence Report — Phase 1 Critical Fixes

> **Project:** ServisGadget (service-hub)
> **Date:** 2026-06-17
> **Workflow:** tdd-workflow (Skill)
> **Source:** Precision audit findings → fix → test verification

---

## 1. Source Plan

Phase 1 derives from the Precision Audit Report. Key bugs targeted:

| Bug | Severity | Module | Description |
|-----|----------|--------|-------------|
| B1 | HIGH | orders | IDOR in `submitDiagnosis` — orderItem ownership not validated |
| B2 | HIGH | spareparts | `update()` allows `qty` below `qtyReserved` |
| B3 | HIGH | store-auth | Store admin can login when store is deactivated |
| B4 | HIGH | orders | `submitDiagnosis` does not require all items covered |
| B6 | MEDIUM | store-auth | No rate limiting on store admin login |

---

## 2. User Journeys (Acceptance Criteria)

| # | Journey | AC Ref |
|---|---------|--------|
| UJ-1 | As a store admin, I can only submit diagnosis for items that belong to the order | AC-15 |
| UJ-2 | As a store admin, I must cover ALL order items in my diagnosis | AC-16 |
| UJ-3 | As a platform, I prevent stock over-commitment by rejecting qty < qtyReserved | AC-12 |
| UJ-4 | As a deactivated store admin, I cannot login to the system | BR-25 |
| UJ-5 | As a system, I limit store admin login attempts to prevent brute force | Security |

---

## 3. Test Specification

| # | Guarantee | Test File | Test Type | Result |
|---|-----------|-----------|-----------|--------|
| 1 | IDOR: orderItemIds validated against order items | `test/orders/diagnosis-security.spec.ts` | unit | ✅ PASS |
| 2 | IDOR: malicious orderItemId rejected | `test/orders/diagnosis-security.spec.ts` | unit | ✅ PASS |
| 3 | All items must be covered in diagnosis | `test/orders/diagnosis-security.spec.ts` | unit | ✅ PASS |
| 4 | Replaced items require replacedSparepartId | `test/orders/diagnosis-security.spec.ts` | unit | ✅ PASS |
| 5 | Stock management: qtyReserved decremented on replacement | `test/orders/diagnosis-security.spec.ts` | unit | ✅ PASS |
| 6 | Stock management: new sparepart availability checked | `test/orders/diagnosis-security.spec.ts` | unit | ✅ PASS |
| 7 | Guard: qty must be >= qtyReserved | `test/spareparts/stock-guard.spec.ts` | unit | ✅ PASS |
| 8 | Available stock = qty - qtyReserved | `test/spareparts/stock-guard.spec.ts` | unit | ✅ PASS |
| 9 | Matching engine filters by available stock | `test/spareparts/stock-guard.spec.ts` | unit | ✅ PASS |
| 10 | isActive guard: deactivated store rejected | `test/store-auth/login-security.spec.ts` | unit | ✅ PASS |
| 11 | Phone normalization consistency | `test/store-auth/login-security.spec.ts` | unit | ✅ PASS |
| 12 | Rate limit: 5 attempts per 60s window | `test/store-auth/login-security.spec.ts` | unit | ✅ PASS |

---

## 4. Execution Evidence

```
> npm test

PASS test/utils/password.spec.ts
PASS test/utils/phone.spec.ts
PASS test/utils/encryption.spec.ts
PASS test/spareparts/stock-guard.spec.ts
PASS test/orders/state-machine.spec.ts
PASS test/store-auth/login-security.spec.ts
PASS test/orders/diagnosis-security.spec.ts

Test Suites: 7 passed, 7 total
Tests:       89 passed, 89 total
Time:        20.618 s
```

---

## 5. Code Changes (Phase 1)

| File | Change | Fix Reference |
|------|--------|---------------|
| `backend/src/modules/orders/orders.service.ts` | Added orderItemIds ownership check + all-items coverage validation | B1, B4 |
| `backend/src/modules/spareparts/spareparts.service.ts` | Added `qty < qtyReserved` guard in `update()` | B2 |
| `backend/src/modules/store-auth/store-auth.service.ts` | Added `store.isActive` check in `login()` | B3 |
| `backend/src/modules/store-auth/store-auth.controller.ts` | Added `@Throttle({ default: { limit: 5, ttl: 60000 } })` | B6 |
| `frontend/lib/features/store_admin/data/store_admin_repositories.dart` | Switched from `createApiClient` to `createAuthDio` | G1 |
| `frontend/lib/features/platform_admin/data/platform_admin_repositories.dart` | Switched from `createApiClient` to `createAuthDio` | G2 |
| `frontend/lib/main.dart` | Added admin auth check in splash init `_checkAuth()` | B4 |
| `frontend/test/customer_repository_test.dart` | Fixed `OrderStatus.parse()` → `OrderStatus.fromJson()` | Pre-existing |

---

## 6. Known Gaps (Deferred)

| Item | Reason Deferred |
|------|----------------|
| Store admin session invalidation | No `store_admin_sessions` table; requires DB migration |
| Warranty order stock reservation | Current design correct; warranty order uses normal state machine |
| Store refresh token endpoint (`/store/auth/refresh`) | Requires backend implementation |

---

**Phase 1 Status: ✅ COMPLETE — All critical fixes verified with 89 passing tests**
