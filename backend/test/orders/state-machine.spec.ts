import { assertValidTransition, ACTION_STATUS_MAP } from '../../src/modules/orders/utils/state-machine.util';
import { InvalidStatusTransitionException } from '../../src/common/exceptions';

describe('State Machine', () => {
  describe('assertValidTransition', () => {
    const validTransitions = [
      ['waiting_device', 'device_received'],
      ['waiting_device', 'cancelled'],
      ['device_received', 'diagnosing'],
      ['device_received', 'cancelled'],
      ['diagnosing', 'waiting_approval'],
      ['diagnosing', 'cancelled'],
      ['waiting_approval', 'repairing'],
      ['waiting_approval', 'waiting_sparepart'],
      ['waiting_approval', 'cancelled'],
      ['waiting_sparepart', 'repairing'],
      ['waiting_sparepart', 'cancelled'],
      ['repairing', 'quality_check'],
      ['repairing', 'cancelled'],
      ['quality_check', 'waiting_payment'],
      ['quality_check', 'cancelled'],
      ['waiting_payment', 'completed'],
      ['waiting_payment', 'cancelled'],
      ['completed', 'disputed'],
      ['disputed', 'completed'],
    ];

    it.each(validTransitions)('should allow %s → %s', (from, to) => {
      expect(() => assertValidTransition(from, to)).not.toThrow();
    });

    const invalidTransitions = [
      ['waiting_device', 'diagnosing'],
      ['waiting_device', 'completed'],
      ['device_received', 'waiting_approval'],
      ['diagnosing', 'repairing'],
      ['waiting_approval', 'completed'],
      ['repairing', 'waiting_payment'],
      ['quality_check', 'completed'],
      ['completed', 'repairing'],
      ['cancelled', 'waiting_device'],
      ['disputed', 'cancelled'],
    ];

    it.each(invalidTransitions)('should reject %s → %s', (from, to) => {
      expect(() => assertValidTransition(from, to)).toThrow(InvalidStatusTransitionException);
    });
  });

  describe('ACTION_STATUS_MAP', () => {
    it('should map receive_device to device_received', () => {
      expect(ACTION_STATUS_MAP['receive_device']).toBe('device_received');
    });

    it('should map start_diagnosis to diagnosing', () => {
      expect(ACTION_STATUS_MAP['start_diagnosis']).toBe('diagnosing');
    });

    it('should map sparepart_arrived and start_repair to repairing', () => {
      expect(ACTION_STATUS_MAP['sparepart_arrived']).toBe('repairing');
      expect(ACTION_STATUS_MAP['start_repair']).toBe('repairing');
    });

    it('should map complete_repair and start_qc to quality_check', () => {
      expect(ACTION_STATUS_MAP['complete_repair']).toBe('quality_check');
      expect(ACTION_STATUS_MAP['start_qc']).toBe('quality_check');
    });

    it('should map qc_ok and request_payment to waiting_payment', () => {
      expect(ACTION_STATUS_MAP['qc_ok']).toBe('waiting_payment');
      expect(ACTION_STATUS_MAP['request_payment']).toBe('waiting_payment');
    });

    it('should map mark_complete to completed', () => {
      expect(ACTION_STATUS_MAP['mark_complete']).toBe('completed');
    });

    it('should return undefined for unknown actions', () => {
      expect(ACTION_STATUS_MAP['unknown_action']).toBeUndefined();
    });
  });
});
