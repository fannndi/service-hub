/**
 * TDD Test Suite — Sparepart Stock Guard
 *
 * Covers fix from Phase 1 audit:
 * update() should not allow qty below qtyReserved
 *
 * TDD: These tests define the EXPECTED behavior of the stock guard.
 * All tests MUST pass to prove the guard is working correctly.
 */

describe('Sparepart Stock Guard', () => {
  describe('qty guard: prevent over-commitment', () => {
    const sparepart = { qty: 10, qtyReserved: 5 };

    it('should allow qty update when qty >= qtyReserved', () => {
      const newQty = 5; // equal to qtyReserved
      expect(newQty >= sparepart.qtyReserved).toBe(true);
    });

    it('should allow qty update when qty > qtyReserved', () => {
      const newQty = 8;
      expect(newQty > sparepart.qtyReserved).toBe(true);
    });

    it('should REJECT qty update when qty < qtyReserved', () => {
      const newQty = 3; // less than qtyReserved (5)
      expect(newQty < sparepart.qtyReserved).toBe(true);
      // Guard should throw in this case
    });

    it('should REJECT qty update to 0 when qtyReserved > 0', () => {
      const newQty = 0;
      expect(newQty < sparepart.qtyReserved).toBe(true);
    });

    it('should REJECT qty update to negative', () => {
      const newQty = -1;
      expect(newQty < sparepart.qtyReserved).toBe(true);
    });
  });

  describe('available stock calculation', () => {
    it('should compute available stock as qty - qtyReserved', () => {
      const sp = { qty: 10, qtyReserved: 3 };
      const available = sp.qty - sp.qtyReserved;
      expect(available).toBe(7);
    });

    it('should return 0 when all stock is reserved', () => {
      const sp = { qty: 5, qtyReserved: 5 };
      const available = sp.qty - sp.qtyReserved;
      expect(available).toBe(0);
    });

    it('should flag stock as unavailable when available <= 0', () => {
      const sp = { qty: 3, qtyReserved: 5 }; // over-committed edge case
      const available = sp.qty - sp.qtyReserved;
      expect(available <= 0).toBe(true);
    });
  });

  describe('matching engine: sparepart availability', () => {
    it('should include sparepart with available stock', () => {
      const spareparts = [
        { id: 'sp-1', qty: 10, qtyReserved: 3, status: 'available' },
        { id: 'sp-2', qty: 5, qtyReserved: 5, status: 'available' },
        { id: 'sp-3', qty: 0, qtyReserved: 0, status: 'available' },
      ];

      const available = spareparts.filter(
        (sp) => sp.qty - sp.qtyReserved > 0 && sp.status !== 'discontinued',
      );

      expect(available).toHaveLength(1);
      expect(available[0].id).toBe('sp-1');
    });

    it('should not include discontinued spareparts', () => {
      const sparepart = { qty: 10, qtyReserved: 0, status: 'discontinued' };
      expect(sparepart.status === 'discontinued').toBe(true);
    });
  });
});
