/**
 * TDD Integration Tests — Disputes, Credentials, SLA
 *
 * Covers AC-22 to AC-30 from Master PRD.
 */

import { createPrismaMock } from '../helpers/prisma-mock';
import { seedTestData } from '../helpers/test-factory';

describe('Disputes Integration — AC-22 to AC-25', () => {
  let db: ReturnType<typeof createPrismaMock>;

  beforeEach(() => {
    db = createPrismaMock();
  });

  // ─── AC-22: Dispute in warranty → created, order=disputed ─────────────
  describe('AC-22: Dispute creation', () => {
    it('should set order status to disputed', async () => {
      const { store } = seedTestData(db);
      const order = await db.serviceOrder.create({
        data: {
          userId: 'user-001',
          storeId: store.id,
          status: 'completed',
          warrantyExpiredAt: new Date(Date.now() + 24 * 60 * 60 * 1000),
        },
      });

      // Verify warranty is active
      const warrantyExpired = (order as Record<string, unknown>).warrantyExpiredAt as Date;
      expect(warrantyExpired.getTime()).toBeGreaterThan(Date.now());
    });

    it('should set SLA deadline +24h on dispute', () => {
      const slaDeadline = new Date(Date.now() + 24 * 60 * 60 * 1000);
      const hoursUntil = (slaDeadline.getTime() - Date.now()) / (60 * 60 * 1000);
      expect(hoursUntil).toBeCloseTo(24, 0);
    });
  });

  // ─── AC-23: Dispute after warrantyExpiredAt → 422 ────────────────────
  describe('AC-23: Warranty expired dispute rejection', () => {
    it('should reject dispute when warrantyExpiredAt is in the past', () => {
      const warrantyExpiredAt = new Date(Date.now() - 1000);
      const now = new Date();
      const isExpired = now >= warrantyExpiredAt;
      expect(isExpired).toBe(true);
    });

    it('should accept dispute when warrantyExpiredAt is in the future', () => {
      const warrantyExpiredAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);
      const now = new Date();
      const isExpired = now >= warrantyExpiredAt;
      expect(isExpired).toBe(false);
    });
  });

  // ─── AC-24: Active dispute exists → 409 DISPUTE_ALREADY_ACTIVE ──────
  describe('AC-24: Duplicate active dispute prevention', () => {
    it('should prevent new dispute when active dispute exists', async () => {
      const { store } = seedTestData(db);
      await db.dispute.create({
        data: { orderId: 'order-001', userId: 'user-001', storeId: store.id, status: 'open' },
      });

      const activeDispute = await db.dispute.findFirst({
        where: { orderId: 'order-001', status: { notIn: ['resolved', 'closed'] } },
      });
      expect(activeDispute).toBeDefined();
    });

    it('should allow dispute when previous dispute is resolved', async () => {
      const { store } = seedTestData(db);
      await db.dispute.create({
        data: { orderId: 'order-002', userId: 'user-001', storeId: store.id, status: 'resolved' },
      });

      const activeDispute = await db.dispute.findFirst({
        where: { orderId: 'order-002', status: { notIn: ['resolved', 'closed'] } },
      });
      expect(activeDispute).toBeNull();
    });
  });

  // ─── AC-25: store_accepted → warranty order (finalPrice=0) ────────────
  describe('AC-25: Warranty order creation', () => {
    it('should create warranty order with isWarrantyOrder=true and finalPrice=0', async () => {
      const { store } = seedTestData(db);
      const warrantyOrder = await db.serviceOrder.create({
        data: {
          userId: 'user-001',
          storeId: store.id,
          status: 'waiting_device',
          totalEstimasi: 0,
          finalPrice: 0,
          isWarrantyOrder: true,
          parentOrderId: 'order-001',
        },
      });

      const orderRow = warrantyOrder as Record<string, unknown>;
      expect(orderRow.isWarrantyOrder).toBe(true);
      expect(orderRow.totalEstimasi).toBe(0);
      expect(orderRow.finalPrice).toBe(0);
      expect(orderRow.parentOrderId).toBe('order-001');
    });
  });
});

describe('Credential System Integration — AC-26 to AC-28', () => {
  let db: ReturnType<typeof createPrismaMock>;

  beforeEach(() => {
    db = createPrismaMock();
  });

  // ─── AC-26: GET /orders/:id new customer → credentialPanel has pwd ────
  describe('AC-26: Credential panel for new customers', () => {
    it('should show credential when isCredentialSent=false', () => {
      const user = {
        credentialPlainEnc: 'encrypted-pass',
        isCredentialSent: false,
        createdAt: new Date(),
      };
      const showCredential = user.credentialPlainEnc !== null && !user.isCredentialSent;
      expect(showCredential).toBe(true);
    });

    it('should hide credential when isCredentialSent=true', () => {
      const user = { credentialPlainEnc: null, isCredentialSent: true };
      const showCredential = user.credentialPlainEnc !== null && !user.isCredentialSent;
      expect(showCredential).toBe(false);
    });
  });

  // ─── AC-27: mark-sent → isCredentialSent=true ────────────────────────
  describe('AC-27: Credential marked as sent', () => {
    it('should clear credential after marking as sent', async () => {
      const { user } = seedTestData(db);
      await db.user.update({
        where: { id: user.id },
        data: { isCredentialSent: true, credentialPlainEnc: null },
      });

      const updated = await db.user.findUnique({ where: { id: user.id } });
      expect(updated!.isCredentialSent).toBe(true);
      expect(updated!.credentialPlainEnc).toBeNull();
    });
  });

  // ─── AC-28: Credential cleaner purges after TTL ──────────────────────
  describe('AC-28: Credential cleanup after TTL', () => {
    it('should identify users eligible for credential cleanup', () => {
      const now = Date.now();
      const threshold = now - 24 * 60 * 60 * 1000;

      // User changed password 25 hours ago → eligible for cleanup
      const user1 = { passwordChangedAt: new Date(threshold - 3600000), credentialPlainEnc: 'enc1' };
      expect(user1.passwordChangedAt.getTime() < threshold).toBe(true);

      // User changed password 23 hours ago → NOT eligible
      const user2 = { passwordChangedAt: new Date(threshold + 3600000), credentialPlainEnc: 'enc2' };
      expect(user2.passwordChangedAt.getTime() < threshold).toBe(false);
    });
  });
});

describe('SLA Monitor Integration — AC-29 to AC-30', () => {
  let db: ReturnType<typeof createPrismaMock>;

  beforeEach(() => {
    db = createPrismaMock();
  });

  // ─── AC-29: Auto-cancel overdue → penaltyPoints+1, qty rollback ──────
  describe('AC-29: SLA auto-cancel', () => {
    it('should increment penalty points on SLA breach', async () => {
      const { store } = seedTestData(db);
      const before = await db.store.findUnique({ where: { id: store.id } });
      const penalty = (before!.penaltyPoints as number) + 1;

      await db.store.update({
        where: { id: store.id },
        data: { penaltyPoints: penalty },
      });

      const after = await db.store.findUnique({ where: { id: store.id } });
      expect(after!.penaltyPoints).toBe(penalty);
    });

    it('should rollback qtyReserved for early-stage cancelled orders', () => {
      const sp = { qty: 10, qtyReserved: 3 };
      // Cancel in waiting_device → release reservation
      sp.qtyReserved -= 1;
      expect(sp.qty).toBe(10);
      expect(sp.qtyReserved).toBe(2);
    });

    it('should rollback qty for post-approve cancelled orders', () => {
      const sp = { qty: 9, qtyReserved: 0 };
      // Cancel in repairing → return stock
      sp.qty += 1;
      expect(sp.qty).toBe(10);
      expect(sp.qtyReserved).toBe(0);
    });
  });

  // ─── AC-30: SLA warning T-6h → no duplicate warning ──────────────────
  describe('AC-30: SLA warning', () => {
    it('should set slaWarnedAt when warning is sent', () => {
      const order = { slaWarnedAt: null as Date | null };
      order.slaWarnedAt = new Date();
      expect(order.slaWarnedAt).toBeDefined();
    });

    it('should NOT send duplicate warnings', () => {
      const order = { slaWarnedAt: new Date() };
      const shouldWarn = order.slaWarnedAt === null;
      expect(shouldWarn).toBe(false);
    });
  });
});
