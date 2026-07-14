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

import { corsHeaders } from '../_shared/cors.ts';

export function ok(data: unknown): Response {
  return new Response(JSON.stringify({ success: true, data }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

export function fail(code: string, message: string, status = 400): Response {
  return new Response(JSON.stringify({ success: false, error: { code, message } }), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

// Manual JWT verification via Supabase Auth API (works with both ES256 and HS256)
export async function requireUser(req: Request, admin: any): Promise<Record<string, any>> {
  const authHeader = req.headers.get('Authorization');
  if (!authHeader?.startsWith('Bearer ')) throw new Error('UNAUTHORIZED: Missing auth header');
  const token = authHeader.slice(7);
  const { data: { user }, error } = await admin.auth.getUser(token);
  if (error || !user) throw new Error('UNAUTHORIZED: Invalid token');
  return {
    id: user.id,
    email: user.email,
    role: (user.user_metadata?.role || user.app_metadata?.role) as string,
    userMetadata: user.user_metadata,
    storeId: user.user_metadata?.store_id as string,
  };
}
