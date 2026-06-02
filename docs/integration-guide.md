# Integration Guide

## Shared Boundary
Phase 1 Foundation owns backend data contracts, database schema, auth separation, shared services, and Flutter shared infrastructure. Phase 2 and Phase 3 should consume these contracts instead of duplicating business logic.

## Current Shared Entities
Defined in `backend/prisma/schema.prisma`. This schema is extracted from `00_MASTER_PRD.md` and should remain the source for generated Prisma client types.

## Current Shared Flutter Areas
- `frontend/lib/core`: config, errors, common utilities.
- `frontend/lib/network`: Dio client and network error mapping.
- `frontend/lib/storage`: secure token storage abstraction.
- `frontend/lib/models`: shared API models.
- `frontend/lib/repositories`: base repository contracts.
- `frontend/lib/shared_widgets`: generic widgets only.

## API Contracts
- Health: `GET /v1/health`.
- Full Foundation endpoints are reserved for later implementation phases in this branch.

## Merge Strategy
- Keep Customer UI in the customer branch.
- Keep Store Admin UI in the store branch.
- Keep backend business rules in Foundation.
- Prefer shared DTO/model updates in Foundation, then rebase feature branches.

## Extension Points
- Add backend modules under existing `backend/src/<domain>` folders.
- Add Flutter shared models under `frontend/lib/models` only if both Phase 2 and Phase 3 can consume them.
- Add role-specific auth storage keys in feature branches without changing backend JWT separation.

## Conflict Risk Areas
- `frontend/lib/main.dart` may be replaced by feature branches; treat it as a handoff shell.
- `frontend/pubspec.yaml` will likely receive dependency additions.
- `backend/src/app.module.ts` will change as modules are registered.
- `backend/prisma/schema.prisma` must be changed carefully because all branches depend on it.

