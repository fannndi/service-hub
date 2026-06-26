import { withSupabase } from 'npm:@supabase/server'
import { ok, fail } from '../_shared/helpers.ts'
import { corsHeaders } from '../_shared/cors.ts'

async function sendWA(phone: string, message: string) {
  const gw = Deno.env.get('WA_GATEWAY_URL');
  const tk = Deno.env.get('WA_GATEWAY_TOKEN');
  if (!gw || !tk) return;
  await fetch(gw, { method: 'POST', headers: { 'Content-Type': 'application/json', Authorization: tk }, body: JSON.stringify({ target: phone, message, countryCode: '62' }) }).catch(() => {});
}

export default {
  fetch: withSupabase({ auth: 'user' }, async (req: Request, ctx) => {
    if (req.method === 'OPTIONS') return new Response('ok', { headers: { ...corsHeaders } });
    if (req.method !== 'POST') return fail('METHOD_NOT_ALLOWED', 'POST only', 405);

    try {
      const { userClaims, supabaseAdmin: admin } = ctx;
      if (!userClaims) return fail('UNAUTHORIZED', 'Unauthorized', 401);
      const role = (userClaims.user_metadata?.role || userClaims.userMetadata?.role) as string;
      if (role !== 'platform_admin') return fail('FORBIDDEN', `Only platform admin. Got role: ${role}`, 403);

      const body = await req.json();
      const action = body.action;

      // ─── LIST APPLICATIONS ───
      if (action === 'applications') {
        const { data } = await admin.from('store_applications').select('*').order('applied_at', { ascending: false });
        return ok(data || []);
      }

      // ─── APPROVE APPLICATION ───
      if (action === 'approve') {
        const { application_id, password } = body;
        if (!application_id || !password) return fail('INVALID_INPUT', 'application_id dan password wajib');

        const { data: app } = await admin.from('store_applications').select('*').eq('id', application_id).eq('status', 'pending').single();
        if (!app) return fail('NOT_FOUND', 'Aplikasi tidak ditemukan');

        const now = new Date().toISOString();
        const { data: store } = await admin.from('stores').insert({
          store_name: app.store_name, address: app.address, phone_number: app.phone_number, is_active: true,
          config: { warranty_days: 30 }, updated_at: now,
        }).select('id').single();

        const email = `${app.phone_number}@store.servisgadget.com`;
        const { data: authUser, error: authErr } = await admin.auth.admin.createUser({
          email, password, email_confirm: true,
          user_metadata: { role: 'store_admin', store_id: store.id, full_name: app.applicant_name },
        });

        if (authErr) {
          await admin.from('stores').delete().eq('id', store.id);
          return fail('AUTH_FAILED', authErr.message);
        }

        await admin.from('store_admins').insert({
          id: authUser.user.id, store_id: store.id, full_name: app.applicant_name, phone_number: app.phone_number,
          password_hash: 'supabase-managed', is_first_login: true,
        });

        await admin.from('store_applications').update({ status: 'approved', reviewed_by: userClaims.id, reviewed_at: new Date().toISOString() }).eq('id', application_id);

        await sendWA(app.phone_number, `Halo ${app.applicant_name}!\nPendaftaran toko ${app.store_name} disetujui!\nLogin: ${app.phone_number}\nPassword: ${password}\nSegera ganti password setelah login.`);

        return ok({ store_id: store.id, admin_id: authUser.user.id });
      }

      // ─── REJECT APPLICATION ───
      if (action === 'reject') {
        const { application_id, reason } = body;
        await admin.from('store_applications').update({ status: 'rejected', reviewed_by: userClaims.id, review_note: reason || null, reviewed_at: new Date().toISOString() }).eq('id', application_id);
        return ok({ message: 'Ditolak' });
      }

      // ─── UPDATE STORE ───
      if (action === 'update-store') {
        const { store_id, store_name, address, phone_number } = body;
        const upd: Record<string, unknown> = {};
        if (store_name !== undefined) upd.store_name = store_name;
        if (address !== undefined) upd.address = address;
        if (phone_number !== undefined) upd.phone_number = phone_number;
        await admin.from('stores').update(upd).eq('id', store_id);
        return ok({ message: 'Store updated' });
      }

      // ─── UPDATE ADMIN ───
      if (action === 'update-admin') {
        const { admin_id, full_name, password } = body;
        if (full_name !== undefined) await admin.from('store_admins').update({ full_name }).eq('id', admin_id);
        if (password) {
          const { data: a } = await admin.from('store_admins').select('phone_number').eq('id', admin_id).single();
          if (a) {
            const email = `${a.phone_number}@store.servisgadget.com`;
            const { error: err } = await admin.auth.admin.updateUserById(admin_id, { password, email });
            if (err) return fail('AUTH_FAILED', err.message);
          }
        }
        return ok({ message: 'Admin updated' });
      }

      // ─── UPDATE CUSTOMER ───
      if (action === 'update-customer') {
        const { user_id, full_name, phone_number, address, password } = body;
        const upd: Record<string, unknown> = {};
        if (full_name !== undefined) upd.full_name = full_name;
        if (phone_number !== undefined) upd.phone_number = phone_number;
        if (address !== undefined) upd.address = address;
        if (Object.keys(upd).length > 0) await admin.from('users').update(upd).eq('id', user_id);
        if (password) {
          const { data: u } = await admin.from('users').select('phone_number').eq('id', user_id).single();
          if (u) {
            const email = `${u.phone_number}@customer.servisgadget.com`;
            await admin.auth.admin.updateUserById(user_id, { password, email }).catch(() => {});
          }
        }
        return ok({ message: 'Customer updated' });
      }

      // ─── CREATE STORE (existing, direct) ───
      if (action === 'create-store') {
        const { store_name, address, store_phone, admin_name, admin_phone, password } = body;
        if (!store_name || !address || !store_phone || !admin_name || !admin_phone || !password) {
          return fail('INVALID_INPUT', 'Semua field wajib diisi');
        }
        const now = new Date().toISOString();
        const { data: store } = await admin.from('stores').insert({
          store_name, address, phone_number: store_phone, is_active: true,
          config: { warranty_days: 30 }, updated_at: now,
        }).select('id').single();
        const email = `${admin_phone.replace(/\D/g, '')}@store.servisgadget.com`;
        const { data: authUser, error: authErr } = await admin.auth.admin.createUser({
          email, password, email_confirm: true,
          user_metadata: { role: 'store_admin', store_id: store.id, full_name: admin_name },
        });
        if (authErr) { await admin.from('stores').delete().eq('id', store.id); return fail('AUTH_FAILED', authErr.message); }
        await admin.from('store_admins').insert({ id: authUser.user.id, store_id: store.id, full_name: admin_name, phone_number: admin_phone, password_hash: 'supabase-managed', is_first_login: true });
        return ok({ store_id: store.id, admin_id: authUser.user.id });
      }

      return fail('NOT_FOUND', 'Unknown action', 404);
    } catch (err: any) {
      return fail(err.code || 'INTERNAL', err.message, 500);
    }
  }),
}
