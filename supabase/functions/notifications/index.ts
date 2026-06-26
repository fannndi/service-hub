import { withSupabase } from 'npm:@supabase/server'
import { ok, fail } from '../_shared/helpers.ts'

export default {
  fetch: withSupabase({ auth: 'user' }, async (req: Request, ctx) => {
    if (req.method === 'OPTIONS') return new Response('ok', { headers: { 'Access-Control-Allow-Origin': '*', 'Access-Control-Allow-Methods': 'POST, OPTIONS', 'Access-Control-Allow-Headers': 'Content-Type, Authorization' } });

    const url = new URL(req.url);
    const action = url.pathname.split('/').pop();
    const { userClaims, supabaseAdmin: admin } = ctx;
    if (!userClaims) return fail('UNAUTHORIZED', 'Unauthorized', 401);

    let body: Record<string, unknown> = {};
    try { body = await req.json(); } catch { return fail('INVALID_JSON', 'Invalid JSON body'); }

    // ─── BROADCAST (platform_admin only) ───
    if (action === 'broadcast') {
      const role = userClaims.user_metadata?.role as string;
      if (role !== 'platform_admin') return fail('FORBIDDEN', 'Forbidden', 403);

      const { target_role, title, message } = body as any;
      if (!target_role || !title || !message) return fail('INVALID_INPUT', 'target_role, title, message required');

      const { error } = await admin.from('notifications').insert({ role: target_role, title, message, type: 'broadcast' });
      if (error) return fail('INSERT_FAILED', error.message);
      return ok({ message: 'Broadcast sent' });
    }

    // ─── SEND (any authenticated user — quick WA send) ───
    if (action === 'send') {
      const { phone, message, type } = body as any;
      if (!phone || !message) return fail('INVALID_INPUT', 'phone and message required');
      const gatewayUrl = Deno.env.get('WA_GATEWAY_URL');
      const token = Deno.env.get('WA_GATEWAY_TOKEN');
      if (!gatewayUrl || !token) return fail('WA_NOT_CONFIGURED', 'WhatsApp gateway not configured');
      try {
        await fetch(gatewayUrl, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json', Authorization: token },
          body: JSON.stringify({ target: phone, message, countryCode: '62' }),
        });
        return ok({ message: 'Sent' });
      } catch (err) {
        await admin.from('failed_notifications').insert({
          recipient_type: 'whatsapp', recipient_id: phone, message_type: type || 'generic',
          payload: { phone, message }, attempt_count: 1, last_error: String(err),
        });
        return fail('SEND_FAILED', 'Failed to send notification');
      }
    }

    return fail('NOT_FOUND', 'Endpoint not found', 404);
  }),
}
