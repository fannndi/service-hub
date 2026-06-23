export const VALID_TRANSITIONS: Record<string, string[]> = {
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
    throw new Error(`INVALID_STATUS_TRANSITION: Cannot transition from ${from} to ${to}`);
  }
}

export function ok(data: unknown): Response {
  return new Response(JSON.stringify({ success: true, data }), {
    headers: { 'Content-Type': 'application/json' },
  });
}

export function fail(code: string, message: string, status = 400): Response {
  return new Response(JSON.stringify({ success: false, error: { code, message } }), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}
