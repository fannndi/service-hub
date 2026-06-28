import { withSupabase } from 'npm:@supabase/server'
import { ok, fail } from '../_shared/helpers.ts'
import { corsHeaders } from '../_shared/cors.ts'
import { sendWA, isWAConfigured } from '../_shared/whatsapp.ts'

export default {
  fetch: withSupabase({ auth: 'user' }, async (req: Request, ctx) => {
    if (req.method === 'OPTIONS') return new Response('ok', { headers: { ...corsHeaders } });

    try {
      const { userClaims, supabaseAdmin: admin } = ctx;
      if (!userClaims) return fail('UNAUTHORIZED', 'Unauthorized', 401);

      const body = await req.json();
      const action = body.action as string | undefined;

      if (action === 'broadcast') {
        const role = userClaims.userMetadata?.role as string;
        if (role !== 'platform_admin') return fail('FORBIDDEN', 'Forbidden', 403);
        const { target_role, title, message } = body as any;
        if (!target_role || !title || !message) return fail('INVALID_INPUT', 'target_role, title, message required');
        const { data, error } = await admin.from('notifications').insert({ role: target_role, title, message, type: 'broadcast' }).select('id');
        if (error) return fail('INSERT_FAILED', error.message);
        return ok({ message: 'Broadcast sent' });
      }

      if (action === 'send') {
        const { phone, message } = body as any;
        if (!phone || !message) return fail('INVALID_INPUT', 'phone and message required');
        if (!isWAConfigured()) return fail('WA_NOT_CONFIGURED', 'WhatsApp gateway not configured');
        const sent = await sendWA(phone, message, admin);
        return sent ? ok({ message: 'Sent' }) : fail('SEND_FAILED', 'Failed to send notification');
      }

      return fail('NOT_FOUND', 'Endpoint not found', 404);
    } catch (err: any) {
      console.error('Notifications EF error:', err);
      return fail('INTERNAL', err.message || 'Unknown error', 500);
    }
  }),
}
