import { withSupabase } from 'npm:@supabase/server'
import { ok, fail } from '../_shared/helpers.ts'

export default {
  fetch: withSupabase({ auth: 'none' }, async (_req: Request, ctx) => {
    try {
      const { supabaseAdmin: admin } = ctx;
      const cancelled = await admin.rpc('auto_cancel_sla');
      return ok({ cancelled });
    } catch (err: any) {
      return fail('CRON_FAILED', err.message, 500);
    }
  }),
}
