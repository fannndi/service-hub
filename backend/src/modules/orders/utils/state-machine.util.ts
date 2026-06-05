import { InvalidStatusTransitionException } from '../../../common/exceptions';

const VALID_TRANSITIONS: Record<string, string[]> = {
  waiting_device: ['device_received', 'cancelled'],
  device_received: ['diagnosing', 'cancelled'],
  diagnosing: ['waiting_approval', 'cancelled'],
  waiting_approval: ['repairing', 'waiting_sparepart', 'cancelled'],
  waiting_sparepart: ['repairing', 'cancelled'],
  repairing: ['quality_check', 'cancelled'],
  quality_check: ['waiting_payment', 'cancelled'],
  waiting_payment: ['completed', 'cancelled'],
  completed: ['disputed'],
  disputed: ['completed'],
  cancelled: [],
};

export function assertValidTransition(from: string, to: string): void {
  const allowed = VALID_TRANSITIONS[from];
  if (!allowed || !allowed.includes(to)) {
    throw new InvalidStatusTransitionException(from, to);
  }
}
