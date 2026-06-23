import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { corsHeaders } from '../_shared/cors.ts';
import { ok, fail } from '../_shared/helpers.ts';

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') return new Response(null, { headers: corsHeaders });

  try {
    const sb = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_ANON_KEY')!,
      { global: { headers: { Authorization: req.headers.get('Authorization')! } } }
    );
    const admin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    );

    const { data: { user } } = await sb.auth.getUser();
    if (!user) return fail('UNAUTHORIZED', 'Unauthorized', 401);

    const role = user.user_metadata?.role as string;
    if (role !== 'platform_admin') return fail('FORBIDDEN', 'Only platform admin', 403);

    const url = new URL(req.url);
    const path = url.pathname.split('/').pop();
    const body = await req.json();

    // ─── CREATE STORE ───
    if (path === 'create-store' && req.method === 'POST') {
      const { store_name, address, store_phone, admin_name, admin_phone, password, handles_android, handles_ios } = body;

      // Check duplicate admin phone
      const { data: existing } = await admin.from('store_admins').select('id').eq('phone_number', admin_phone).maybeSingle();
      if (existing) return fail('DUPLICATE', 'No HP admin sudah terdaftar');

      // Create store
      const { data: store } = await admin.from('stores').insert({
        store_name,
        address,
        phone_number: store_phone,
        is_active: true,
        config: {
          handles_android: handles_android ?? true,
          handles_ios: handles_ios ?? true,
        },
      }).select().single();

      // Create auth user for store admin
      const { data: authUser, error: authErr } = await admin.auth.admin.createUser({
        email: `${admin_phone.replace(/\D/g, '')}@store.servisgadget.com`,
        password,
        email_confirm: true,
        user_metadata: {
          role: 'store_admin',
          store_id: store.id,
          full_name: admin_name,
        },
      });

      if (authErr) {
        await admin.from('stores').delete().eq('id', store.id);
        return fail('AUTH_FAILED', authErr.message);
      }

      // Also create in store_admins table
      await admin.from('store_admins').insert({
        id: authUser.user.id,
        store_id: store.id,
        full_name: admin_name,
        phone_number: admin_phone,
        password_hash: 'supabase-managed',
        is_first_login: true,
      });

      return ok({ store_id: store.id, admin_id: authUser.user.id });
    }

    return fail('NOT_FOUND', 'Endpoint not found', 404);
  } catch (err: any) {
    return fail(err.code || 'INTERNAL', err.message, 500);
  }
});
