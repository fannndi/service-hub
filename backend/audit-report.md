# ServisGadget Backend — Deep Code Audit Report

**Date:** 2026-06-19
**Scope:** 82 TypeScript files
**Auditor:** farewel-assistant

---

## HIGH Severity

### H1. Stock reservation race condition — non-atomic check-then-increment
- **File:** `src/modules/orders/orders.service.ts:88-96`
- **Issue:** Inside `createOrder` transaction, code reads `sp.qty - sp.qtyReserved` then separately increments `qtyReserved`. With READ COMMITTED isolation (Prisma default), two concurrent transactions can both pass the stock check and oversell.
- **Fix:** Use `UPDATE ... WHERE qty - qtyReserved > 0` via Prisma raw query, or switch transaction to `serializable` isolation level (`$transaction(..., { isolationLevel: 'Serializable' })`).

### H2. Same race condition in `approveOrder`
- **File:** `src/modules/orders/orders.service.ts:170-180`
- **Issue:** Same non-atomic check-then-decrement pattern for stock consumption after approval.
- **Fix:** Same as H1 — atomic decrement with conditional.

### H3. Same race condition in `submitDiagnosis` (sparepart replacement)
- **File:** `src/modules/orders/orders.service.ts:342-358`
- **Issue:** Replacement logic reads `newSp.qty - newSp.qtyReserved <= 0`, then increments `qtyReserved` non-atomically for the replacement part.
- **Fix:** Same as H1.

### H4. Plaintext credential exposed via API
- **File:** `src/modules/orders/orders.service.ts:558-561`
- **Issue:** `buildCredentialPanel` decrypts user password and returns it in API response for `GET /store/orders/:id`. Any store admin with order access sees the plaintext password.
- **Fix:** Remove `credentialPanel` from store order detail response. Never expose decrypted credentials via API. Show only `isNewCustomer` boolean.

### H5. Store admin `changePassword` doesn't invalidate sessions
- **File:** `src/modules/store-auth/store-auth.service.ts:63-73`
- **Issue:** Customer password change (`AuthService.changePassword:84-93`) invalidates all active sessions. Store admin change does not. Stolen refresh token survives password change.
- **Fix:** Add `storeAdminSession` table or extend `userSession` for store admins; invalidate sessions after password change.

### H6. Store auth `logout` is a no-op
- **File:** `src/modules/store-auth/store-auth.controller.ts:30-36`
- **Issue:** Unlike customer auth (`AuthController.logout`), store auth logout does not invalidate any token/session. Returns static success message.
- **Fix:** Implement session tracking for store admins and invalidate on logout.

### H7. Store auth missing brute-force protection
- **File:** `src/modules/store-auth/store-auth.service.ts:19-61`
- **Issue:** Customer auth (`AuthService.login:41-49`) tracks `loginAttemptCount` and locks accounts after 5 failures. Store admin login has no such protection.
- **Fix:** Add `loginAttemptCount` and `lockedUntil` to `StoreAdmin` model; implement lockout logic.

---

## MEDIUM Severity

### M1. Duplicate confirm-payment route — inconsistent guard coverage
- **Files:** `src/modules/orders/store-orders.controller.ts:78-85` vs `src/modules/payments/payments.controller.ts:34-41`
- **Issue:** Both `POST /store/orders/:id/payments/:paymentId/confirm` and `POST /store/payments/:orderId/:paymentId/confirm` exist. First has `FirstLoginGuard`, second doesn't. Route conflict — only one will match.
- **Fix:** Remove duplicate from one controller. Apply `FirstLoginGuard` consistently.

### M2. `completed` status in `UpdateOrderStatusDto` is dead code
- **File:** `src/modules/orders/orders.service.ts:244-245`
- **Issue:** `UpdateOrderStatusDto` allows `completed` in its enum, but service always throws when `dto.status === 'completed'`. The only way to reach `completed` is via payment confirmation.
- **Fix:** Remove `completed` from `UpdateOrderStatusDto` enum.

### M3. Presigned URL validation gap — service returns empty strings instead of throwing
- **File:** `src/modules/uploads/uploads.service.ts:37-39`
- **Issue:** When MIME type is not allowed, `generatePresignedUrl` returns `{ uploadUrl: '', fileUrl: '', key: '' }`. Controller validates first and throws, but service should also throw.
- **Fix:** Throw `FileValidationException` in the service instead of returning empty strings.

### M4. N+1 sparepart queries outside transaction
- **File:** `src/modules/orders/orders.service.ts:47-50`
- **Issue:** Initial loop over `dto.items` queries each sparepart individually (`this.prisma.sparePart.findUnique`). Same queries repeated inside transaction. Double the database hits.
- **Fix:** Batch-fetch all spareparts upfront with `findMany({ where: { id: { in: ids } } })`.

### M5. Two queries where one suffices in tracking endpoints
- **File:** `src/modules/orders/orders.service.ts:472-483`
- **Issue:** `getOrderProgress` and `getStoreOrderTracking` (495-506) first fetch order to verify existence, then fetch tracking. Could use `findUnique` with `include: { tracking: true }`.
- **Fix:** Single query with `include`.

### M6. SLA monitor can auto-cancel disputed orders
- **File:** `src/modules/jobs/sla-monitor.job.ts:75`
- **Issue:** Auto-cancel query uses `status: { notIn: ['completed', 'cancelled', 'waiting_approval', 'disputed'] }` — wait, `disputed` IS excluded. Let me recheck... `status: { notIn: ['completed', 'cancelled', 'waiting_approval', 'disputed'] }` — yes disputed is excluded. False alarm.

But the SLA breach query (line 23) uses `status: { notIn: ['completed', 'cancelled'] }` which includes `disputed` orders. Disputed orders CAN get SLA-warned. This might be intentional.

### M6b. SLA monitor stock restoration may over-restore
- **File:** `src/modules/jobs/sla-monitor.job.ts:86-98`
- **Issue:** Auto-cancel for `repairing`/`quality_check`/`waiting_payment` orders does `qty: { increment: 1 }` (adds back stock). But if the sparepart was physically used (repair done), this overshoots available stock.
- **Fix:** Track whether stock was physically consumed vs reserved; only restore what was consumed.

### M7. `respondToReview` is a stub
- **File:** `src/modules/stores/stores.controller.ts:86-92`
- **Issue:** `POST store/reviews/:reviewId/response` returns `{ message, reviewId, response }` without any database write. Response is not persisted.
- **Fix:** Implement actual storage (add `response` field to `Review` model and persist).

### M8. Global exception filter — hardcoded `VALIDATION_ERROR` code for all HttpExceptions
- **File:** `src/common/filters/global-exception.filter.ts:27-28`
- **Issue:** Every non-AppException HttpException gets `code: 'VALIDATION_ERROR'` and `user_message: 'Data tidak valid.'`, even for 404 or 500 errors.
- **Fix:** Map status codes to appropriate error codes/user messages.

### M9. Inconsistent response format for `respondToReview`
- **File:** `src/modules/stores/stores.controller.ts:91`
- **Issue:** Returns `{ message, reviewId, response }` directly without standard `{ success, data }` wrapper.
- **Fix:** Wrap in standard response or let interceptor handle it.

### M10. `config as any` type erasure
- **Files:** `src/modules/stores/stores.service.ts:229`, `src/modules/platform-admin/platform-admin.service.ts:103`
- **Issue:** Store config is cast to `any` before Prisma write, bypassing type safety.
- **Fix:** Define proper JSON type for Prisma schema or use `Prisma.InputJsonValue`.

### M11. `updateConfig` / `updateStoreProfile` accept unvalidated objects
- **Files:** `src/modules/stores/stores.controller.ts:64`, `src/modules/stores/stores.controller.ts:105`
- **Issue:** Both endpoints accept `Record<string, unknown>` with no DTO validation.
- **Fix:** Use specific DTOs with class-validator decorators.

### M12. `UpdateOrderStatusDto.status` type cast in multiple places
- **File:** `src/modules/orders/orders.service.ts:270,277`
- **Issue:** Repeated `dto.status as 'device_received' | ...` casts that duplicate the enum. Fragile — adding a status requires updating all casts.
- **Fix:** Use the Prisma-generated enum type.

### M13. `StoreAdmin` model likely missing `isApproved` or `isSuspended` field
- **File:** `src/modules/store-auth/store-auth.service.ts:22`
- **Issue:** Query includes `isActive: true` but there's no `accountStatus` field (unlike `User` model which has `accountStatus`). Store accounts can't be individually suspended.
- **Fix:** Add `accountStatus` or `suspendedAt` to `StoreAdmin` model.

---

## LOW Severity

### L1. `any` return type in guard `handleRequest`
- **Files:** `src/common/guards/jwt-auth.guard.ts:8`, `src/common/guards/store-jwt-auth.guard.ts:8`, `src/modules/platform-admin/platform-admin.guard.ts:8`
- **Issue:** Return type `any` instead of `AuthenticatedUser`.
- **Fix:** `handleRequest(err: unknown, user: AuthenticatedUser | false): AuthenticatedUser`.

### L2. Unused import `OrderStatus` in users service
- **File:** `src/modules/users/users.service.ts:3`
- **Issue:** `OrderStatus` from `@prisma/client` imported but never referenced directly (inline string literals used instead).
- **Fix:** Remove import or use the type.

### L3. Empty catch blocks in Redis service
- **File:** `src/modules/redis/redis.service.ts:39,48,55`
- **Issue:** `get`, `set`, `del` all have empty `catch {}` blocks that silently swallow errors.
- **Fix:** Log at debug level at minimum.

### L4. Cron runs overlap risk — SLA monitor every 30s, credential cleaner every 30min
- **Files:** `src/modules/jobs/sla-monitor.job.ts:15`, `src/modules/jobs/credential-cleaner.job.ts:11`
- **Issue:** 30-second cron may overlap with itself if processing takes >30s. No concurrency guard.
- **Fix:** Add `@Cron({ name: 'sla-monitor', waitForCompletion: true })` or a mutex flag.

### L5. Deterministic password generation — not cryptographically random
- **File:** `src/common/utils/password.util.ts:1-11`
- **Issue:** `generatePassword` uses name+phone to create password. Formula is deterministic and guessable.
- **Fix:** Use `crypto.randomBytes()` to generate a truly random alphanumeric password.

### L6. SMTP connection initialized eagerly at module start
- **File:** `src/modules/notifications/email.service.ts:17`
- **Issue:** Nodemailer transporter creates connection in constructor, even if email is never used.
- **Fix:** Lazy initialization — create transporter only on first `send()` call.

### L7. `GET store/spareparts` is public
- **File:** `src/modules/spareparts/spareparts.controller.ts:15-23`
- **Issue:** Public endpoint lists spareparts by `storeId` with no auth. Acceptable for public browsing but could leak internal data.
- **Fix:** Add optional auth or rate limiting if needed.

### L8. Hardcoded values: SLA deadlines, warranty days, coupon amount
- **Files:** `src/modules/orders/orders.service.ts:111,248,250,384`, `src/modules/orders/dto/order.dto.ts`
- **Issue:** `24 * 60 * 60 * 1000` (1 day SLA) hardcoded in multiple places instead of using `SLA_MINUTES` constant.
- **Fix:** Reference `SLA_MINUTES` from `sla.constant.ts` consistently.

### L9. Store admin refresh token not used
- **File:** `src/modules/store-auth/store-auth.service.ts`
- **Issue:** Refresh token is generated in login response, but there's no refresh endpoint for store admins. Token is generated but never refreshable.
- **Fix:** Add `POST store/auth/refresh` endpoint or remove refresh token generation.

### L10. Login attempt counter in `AuthService` has race condition
- **File:** `src/modules/auth/auth.service.ts:41-49`
- **Issue:** Two concurrent failed logins could both read `loginAttemptCount = 4`, both increment to 5, neither locks the account.
- **Fix:** Use atomic increment in Prisma: `update({ ... data: { loginAttemptCount: { increment: 1 } } })` then check after update.

---

## Summary

| Severity | Count | Key Issues |
|----------|-------|------------|
| **HIGH** | 7 | Race conditions in stock ops (×3), credential leak, missing session invalidation (×2), brute-force missing |
| **MEDIUM** | 14 | Duplicate routes, dead code, validation gaps, N+1 queries, stub endpoints, filter inconsistencies, type erasure |
| **LOW** | 10 | Any types, unused imports, empty catches, eager connections, hardcoded values, deterministic passwords |

**Most critical:** Race conditions in stock operations (H1-H3) can cause overselling. Credential leak (H4) is a data exposure vulnerability. Missing session invalidation (H5-H6) weakens auth security for store admins.
