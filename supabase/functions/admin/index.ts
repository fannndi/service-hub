import { withSupabase } from 'npm:@supabase/server'
import { ok, fail, requireUser } from '../_shared/helpers.ts'
import { corsHeaders } from '../_shared/cors.ts'
import { sendNotificationEmail, isEmailConfigured } from '../_shared/email.ts'

export default {
  fetch: withSupabase({ auth: 'none' }, async (req: Request, ctx) => {
    if (req.method === 'OPTIONS') return new Response('ok', { headers: { ...corsHeaders } });
    if (req.method !== 'POST') return fail('METHOD_NOT_ALLOWED', 'POST only', 405);

    try {
      const { supabaseAdmin: admin } = ctx; const userClaims = await requireUser(req, admin);
      const role = userClaims.role as string;
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
        const { data: store, error: storeErr } = await admin.from('stores').insert({
          store_name: app.store_name, address: app.address, phone_number: app.phone_number, is_active: true,
          config: { warranty_days: 30 }, updated_at: now,
        }).select('id').single();
        if (storeErr || !store) {
          return fail('INSERT_FAILED', storeErr?.message || 'Failed to create store');
        }

        const adminPhone = app.admin_phone || app.phone_number;
        const email = `${adminPhone}@store.servisgadget.com`;
        const { data: authUser, error: authErr } = await admin.auth.admin.createUser({
          email, password, email_confirm: true,
          user_metadata: { role: 'store_admin', store_id: store.id, full_name: app.applicant_name },
        });

        if (authErr) {
          console.error(`Auth createUser failed for application ${application_id}: ${authErr.message}. Rolling back store ${store.id}...`);
          const { error: delErr } = await admin.from('stores').delete().eq('id', store.id);
          if (delErr) console.error(`Rollback delete store ${store.id} failed:`, delErr.message);
          await admin.from('store_applications').update({
            status: 'pending', reviewed_by: null, reviewed_at: null,
          }).eq('id', application_id);
          console.error(`Rollback complete: store ${store.id} deleted, application ${application_id} reverted to pending.`);
          return fail('AUTH_FAILED', authErr.message);
        }

        await admin.from('store_admins').insert({
          id: authUser.user.id, store_id: store.id, full_name: app.applicant_name, phone_number: adminPhone,
          password_hash: 'supabase-managed', is_first_login: true,
        });

        await admin.from('store_applications').update({ status: 'approved', reviewed_by: userClaims.id, reviewed_at: new Date().toISOString() }).eq('id', application_id);

        if (isEmailConfigured()) {
          await sendNotificationEmail(email, 'Pendaftaran Toko Disetujui — Service Me',
            'Selamat! Toko Anda Disetujui',
            `Halo ${app.applicant_name}!\nPendaftaran toko ${app.store_name} telah disetujui!\n\nLogin: ${email}\nPassword: ${password}\n\nSegera ganti password setelah login.`);
        }

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
        const now = new Date().toISOString();
        const upd: Record<string, unknown> = {};
        if (store_name !== undefined) upd.store_name = store_name;
        if (address !== undefined) upd.address = address;
        if (phone_number !== undefined) upd.phone_number = phone_number;
        if (Object.keys(upd).length > 0) upd.updated_at = now;
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
        const now = new Date().toISOString();
        const upd: Record<string, unknown> = {};
        if (full_name !== undefined) upd.full_name = full_name;
        if (phone_number !== undefined) upd.phone_number = phone_number;
        if (address !== undefined) upd.address = address;
        if (Object.keys(upd).length > 0) upd.updated_at = now;
        if (Object.keys(upd).length > 0) await admin.from('users').update(upd).eq('id', user_id);
        if (password) {
          const { data: u } = await admin.from('users').select('phone_number').eq('id', user_id).single();
          if (u) {
            const email = `${u.phone_number}@customer.servisgadget.com`;
            const { error: pwErr } = await admin.auth.admin.updateUserById(user_id, { password, email });
            if (pwErr) { console.error(`updateUserById failed for ${user_id}:`, pwErr.message); return fail('AUTH_FAILED', pwErr.message); }
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

      // ─── LIST STORES ───
      if (action === 'stores') {
        const { data } = await admin.from('stores').select('*, admins:store_admins(id, full_name, phone_number, is_active)').order('created_at', { ascending: false });
        return ok(data || []);
      }

      // ─── DELETE ACCOUNT ───
      if (action === 'delete-account') {
        const token = req.headers.get('Authorization')?.replace('Bearer ', '');
        if (!token) return fail('UNAUTHORIZED', 'No token', 401);
        const { data: { user }, error: authErr } = await admin.auth.getUser(token);
        if (authErr || !user) return fail('UNAUTHORIZED', 'Invalid token', 401);
        const userId = user.id;
        const { data: orderIds } = await admin.from('service_orders').select('id').eq('user_id', userId);
        const ids = (orderIds || []).map((o: any) => o.id);
        await admin.from('disputes').delete().eq('user_id', userId);
        await admin.from('reviews').delete().eq('user_id', userId);
        await admin.from('coupons').delete().eq('user_id', userId);
        await admin.from('payments').delete().eq('user_id', userId);
        if (ids.length > 0) {
          await admin.from('service_tracking').delete().in('order_id', ids);
          await admin.from('order_items').delete().in('order_id', ids);
        }
        await admin.from('service_orders').delete().eq('user_id', userId);
        await admin.from('user_sessions').delete().eq('user_id', userId);
        await admin.from('users').delete().eq('id', userId);
        await admin.auth.admin.deleteUser(userId);
        return ok({ message: 'Account deleted' });
      }

      return fail('NOT_FOUND', 'Unknown action', 404);
    } catch (err: any) {
      return fail(err.code || 'INTERNAL', err.message, 500);
    }
  }),
}
