import { withSupabase } from 'npm:@supabase/server'
import { ok, fail } from '../_shared/helpers.ts'

export default {
  fetch: withSupabase({ auth: 'none' }, async (req: Request, ctx) => {
    try {
      const password = Deno.env.get('SEED_ADMIN_PASSWORD');
      if (!password) return ok({ message: 'Skipped — set SEED_ADMIN_PASSWORD' });

      const secret = Deno.env.get('SEED_ADMIN_SECRET');
      if (secret && req.headers.get('x-seed-admin-secret') !== secret) {
        return fail('UNAUTHORIZED', 'Unauthorized', 401);
      }

      const { supabaseAdmin: admin } = ctx;
      const { error } = await admin.auth.admin.createUser({
        email: 'admin@servisgadget.com',
        password,
        email_confirm: true,
        user_metadata: { role: 'platform_admin', full_name: 'Platform Admin' },
      });
      if (error) return fail('CREATE_FAILED', error.message);
      return ok({ message: 'Admin created' });
    } catch (err: any) {
      return fail('INTERNAL', err.message || 'Unknown error', 500);
    }
  }),
}