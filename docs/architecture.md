# Phase A Architecture

## Boundary
Phase 1 owns shared backend contracts, database, auth separation, domain services, repositories, jobs, and Flutter shared infrastructure. Phase 1 does not own Customer screens, Store Admin screens, dashboards, or feature flows.

## Backend Architecture
- Modular monolith under `backend/src`.
- Controllers stay thin and delegate to services.
- Services enforce business rules and transaction boundaries.
- Repositories isolate Prisma access.
- DTOs define validated API input/output contracts.
- Auth split is physical and logical: customer auth and store auth use separate modules, strategies, guards, payloads, token secrets, and repositories.

## Modules
- `common`: shared decorators, filters, guards, interceptors, pipes, Prisma transaction helpers.
- `config`: typed environment configuration.
- `database`: Prisma client lifecycle and transaction provider.
- `redis`: Redis connection provider.
- `auth/customer`: customer login, token issue, guards, strategies.
- `auth/store`: store admin login, token issue, guards, strategies.
- `stores`: store and admin domain access.
- `spareparts`: sparepart inventory and stock reservation logic.
- `orders`: order lifecycle, state machine, service tracking, diagnosis items.
- `payments`: payment records, confirmation, warranty assignment.
- `reviews`: review creation and store rating recalculation.
- `disputes`: warranty claims and dispute lifecycle.
- `notifications`: notification persistence and delivery queue entrypoints.
- `upload`: object upload contract and storage adapter boundary.
- `jobs`: BullMQ queues and processors.

## Flutter Shared Layer
- `core`: constants, result types, errors, utilities.
- `network`: Dio client, interceptors, error mapper.
- `storage`: secure token storage abstraction.
- `models`: shared API models only.
- `repositories`: base repository and shared repository contracts.
- `shared_widgets`: generic reusable widgets only.

## Merge Safety
- Customer branch consumes `/v1/auth/*`, customer-safe order/payment/review/dispute contracts, and shared Flutter models.
- Store branch consumes `/v1/store/*`, store auth, order management, payment confirmation, inventory, and dispute contracts.
- DTO names remain feature-neutral where shared and role-prefixed where auth-specific.
- Business rules stay backend-side to avoid duplicate logic in Phase 2/3.
