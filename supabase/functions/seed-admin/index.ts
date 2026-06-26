import { withSupabase } from 'npm:@supabase/server'
import { ok, fail } from '../_shared/helpers.ts'

export default {
  fetch: withSupabase({ auth: 'none' }, async (_req: Request, ctx) => {
    const { supabaseAdmin: admin } = ctx;
    const { error } = await admin.auth.admin.createUser({
      email: 'admin@servisgadget.com',
      password: 'admin123',
      email_confirm: true,
      user_metadata: { role: 'platform_admin', full_name: 'Platform Admin' },
    });
    if (error) return fail('CREATE_FAILED', error.message);
    return ok({ message: 'Admin created: admin@servisgadget.com / admin123' });
  }),
}
