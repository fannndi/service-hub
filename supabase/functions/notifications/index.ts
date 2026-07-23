import { withSupabase } from 'npm:@supabase/server'
import { ok, fail, requireUser } from '../_shared/helpers.ts'
import { corsHeaders } from '../_shared/cors.ts'
import { sendNotificationEmail, isEmailConfigured } from '../_shared/email.ts'

interface BroadcastBody {
  target_role: string;
  title: string;
  message: string;
}

interface SendBody {
  email: string;
  message: string;
}

export default {
  fetch: withSupabase({ auth: 'none' }, async (req: Request, ctx) => {
    if (req.method === 'OPTIONS') return new Response('ok', { headers: { ...corsHeaders } });
    if (req.method !== 'POST') return fail('METHOD_NOT_ALLOWED', 'POST only', 405);

    try {
      const { supabaseAdmin: admin } = ctx; const userClaims = await requireUser(req, admin);

      const body = await req.json();
      const action = body.action as string | undefined;

      if (action === 'broadcast') {
        const role = userClaims.userMetadata?.role as string;
        if (role !== 'platform_admin') return fail('FORBIDDEN', 'Forbidden', 403);
        const { target_role, title, message } = body as BroadcastBody;
        if (!target_role || !title || !message) return fail('INVALID_INPUT', 'target_role, title, message required');
        if (!['customer', 'store_admin'].includes(target_role)) return fail('INVALID_INPUT', 'Invalid target_role');

        // H1: Batch insert per-user so each recipient sees broadcast
        const table = target_role === 'customer' ? 'users' : 'store_admins';
        const { data: recipients } = await admin.from(table).select('id');
        const notifications = (recipients || []).map((r: any) => ({
          user_id: r.id, role: target_role, title, message, type: 'broadcast',
        }));
        if (notifications.length > 0) {
          const { error } = await admin.from('notifications').insert(notifications);
          if (error) return fail('INSERT_FAILED', error.message);
        }
        return ok({ message: `Broadcast sent to ${notifications.length} ${target_role}(s)` });
      }

      if (action === 'send') {
        // H2: Only platform_admin can send arbitrary emails
        const senderRole = userClaims.userMetadata?.role as string;
        if (senderRole !== 'platform_admin') return fail('FORBIDDEN', 'Forbidden', 403);
        const { email, message } = body as SendBody;
        if (!email || !message) return fail('INVALID_INPUT', 'email and message required');
        if (!isEmailConfigured()) return fail('EMAIL_NOT_CONFIGURED', 'Email service not configured');
        const sent = await sendNotificationEmail(email, 'Notifikasi — Service Me', 'Notifikasi', message);
        return sent ? ok({ message: 'Sent' }) : fail('SEND_FAILED', 'Failed to send notification');
      }

      return fail('NOT_FOUND', 'Endpoint not found', 404);
    } catch (err: any) {
      console.error('Notifications EF error:', err);
      return fail('INTERNAL', err.message || 'Unknown error', 500);
    }
  }),
}
