import { withSupabase } from 'npm:@supabase/server'
import { ok, fail } from '../_shared/helpers.ts'

export default {
  fetch: withSupabase({ auth: 'user' }, async (req: Request, ctx) => {
    if (req.method !== 'POST') return fail('METHOD_NOT_ALLOWED', 'POST only', 405);

    try {
      const { userClaims, supabaseAdmin: admin } = ctx;
      if (!userClaims) return fail('UNAUTHORIZED', 'Unauthorized', 401);

      const role = userClaims.userMetadata?.role as string;
      if (role !== 'platform_admin') return fail('FORBIDDEN', 'Only platform admin', 403);

      const body = await req.json();
      const { store_name, address, store_phone, admin_name, admin_phone, password, handles_android, handles_ios } = body;

      const { data: existing } = await admin.from('store_admins').select('id').eq('phone_number', admin_phone).maybeSingle();
      if (existing) return fail('DUPLICATE', 'No HP admin sudah terdaftar');

      const { data: store } = await admin.from('stores').insert({
        store_name, address, phone_number: store_phone, is_active: true,
        config: { handles_android: handles_android ?? true, handles_ios: handles_ios ?? true },
      }).select().single();

      const { data: authUser, error: authErr } = await admin.auth.admin.createUser({
        email: `${admin_phone.replace(/\D/g, '')}@store.servisgadget.com`,
        password, email_confirm: true,
        user_metadata: { role: 'store_admin', store_id: store.id, full_name: admin_name },
      });

      if (authErr) {
        await admin.from('stores').delete().eq('id', store.id);
        return fail('AUTH_FAILED', authErr.message);
      }

      await admin.from('store_admins').insert({ id: authUser.user.id, store_id: store.id, full_name: admin_name, phone_number: admin_phone, password_hash: 'supabase-managed', is_first_login: true });

      return ok({ store_id: store.id, admin_id: authUser.user.id });
    } catch (err: any) {
      return fail(err.code || 'INTERNAL', err.message, 500);
    }
  }),
}
