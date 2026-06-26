import { withSupabase } from 'npm:@supabase/server'
import { ok, fail } from '../_shared/helpers.ts'

export default {
  fetch: withSupabase({ auth: 'none' }, async (req: Request, ctx) => {
    try {
      const cronSecret = Deno.env.get('CRON_SECRET');
      if (cronSecret && req.headers.get('x-cron-secret') !== cronSecret) {
        return fail('FORBIDDEN', 'Unauthorized', 403);
      }
      const { supabaseAdmin: admin } = ctx;
      const cancelled = await admin.rpc('auto_cancel_sla');
      return ok({ cancelled });
    } catch (err: any) {
      return fail('CRON_FAILED', err.message, 500);
    }
  }),
}
