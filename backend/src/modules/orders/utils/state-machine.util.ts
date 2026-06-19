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

export const ACTION_STATUS_MAP: Record<string, string> = {
  receive_device: 'device_received',
  start_diagnosis: 'diagnosing',
  sparepart_arrived: 'repairing',
  start_repair: 'repairing',
  complete_repair: 'quality_check',
  start_qc: 'quality_check',
  qc_ok: 'waiting_payment',
  request_payment: 'waiting_payment',
  mark_complete: 'completed',
};

const STATUS_ACTIONS: Record<string, string[]> = {
  waiting_device: ['receive_device'],
  device_received: ['start_diagnosis'],
  diagnosing: ['submit_diagnosis'],
  waiting_approval: [],
  waiting_sparepart: ['sparepart_arrived'],
  repairing: ['complete_repair'],
  quality_check: ['request_payment'],
  waiting_payment: [],
  completed: [],
  disputed: [],
  cancelled: [],
};

export function allowedActionsForStatus(status: string): string[] {
  return STATUS_ACTIONS[status] ?? [];
}

export function assertValidTransition(from: string, to: string): void {
  const allowed = VALID_TRANSITIONS[from];
  if (!allowed || !allowed.includes(to)) {
    throw new InvalidStatusTransitionException(from, to);
  }
}
