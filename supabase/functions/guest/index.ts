import { withSupabase } from 'npm:@supabase/server'
import { ok, fail } from '../_shared/helpers.ts'
import { corsHeaders } from '../_shared/cors.ts'
import { sendOrderConfirmation } from '../_shared/email.ts'
import { generatePassword, generateOrderNumber } from '../_shared/crypto.ts'

export default {
  fetch: withSupabase({ auth: 'none' }, async (req: Request, ctx) => {
    if (req.method === 'OPTIONS') return new Response('ok', { headers: { ...corsHeaders } });
    let isNew = false;
    let userId = '';
    let tempPassword = '';
    try {
      const body = await req.json();
      const action = body.action as string;
      const { supabaseAdmin: admin } = ctx;

      // ─── CREATE ORDER ───
      if (action === 'create-order') {
        const { store_id, device_type, brand, device_model, delivery_method, delivery_address, customer_name, email, items } = body as Record<string, unknown>;
        if (!store_id || !device_type || !brand || !device_model || !customer_name || !email || !items?.length) {
          return fail('INVALID_INPUT', 'Missing required fields');
        }
        const customerEmail = (email as string).trim().toLowerCase();
        tempPassword = generatePassword();
        const now = new Date().toISOString();
        const { data: existingFromAuth } = await admin.auth.admin.listUsers();
        const existingAuth = existingFromAuth?.users?.find((u: { email?: string }) => u.email === customerEmail);
        if (existingAuth) {
          userId = existingAuth.id;
          await admin.from('users').update({
            account_status: 'suspended', updated_at: now,
          }).eq('id', userId);
        } else {
          const { data: authUser, error: authErr } = await admin.auth.admin.createUser({
            email: customerEmail, password: tempPassword, email_confirm: true,
            user_metadata: { role: 'customer', full_name: customer_name },
          });
          if (authErr) return fail('CREATE_FAILED', `Auth user creation failed: ${authErr.message}`);
          userId = authUser.user.id;
          isNew = true;
          await admin.from('users').update({
            account_status: 'suspended', is_first_login: true, is_credential_sent: false, updated_at: now,
          }).eq('id', userId);
        }

        const fiveMinAgo = new Date(Date.now() - 5 * 60 * 1000).toISOString();
        const { count } = await admin.from('service_orders')
          .select('*', { count: 'exact', head: true })
          .eq('user_id', userId).gte('created_at', fiveMinAgo);
        if (count && count >= 5) {
          return fail('RATE_LIMITED', 'Too many orders. Try again later.', 429);
        }

        const { data: store } = await admin.from('stores').select('id, phone_number').eq('id', store_id).eq('is_active', true).single();
        if (!store) return fail('STORE_NOT_ACTIVE', 'Store not active');

        for (const item of items as any[]) {
          if (item.sparepart_id) {
            const { data: reserved } = await admin.rpc('reserve_stock', { p_sparepart_id: item.sparepart_id, p_qty: 1 });
            if (!reserved) return fail('STOCK_UNAVAILABLE', 'Stock unavailable');
          }
        }

        const orderNumber = generateOrderNumber();
        const totalEstimasi = (items as any[]).reduce((s: number, i: any) => s + (i.item_price || 0), 0);

        const { data: order, error: orderErr } = await admin.from('service_orders').insert({
          user_id: userId, store_id, order_number: orderNumber, device_type, brand, device_model,
          delivery_method, delivery_address: delivery_address || null, status: 'waiting_device',
          total_estimasi: totalEstimasi, sla_deadline: new Date(Date.now() + 86400000).toISOString(), updated_at: now,
        }).select().single();
        if (orderErr) {
          if (isNew) {
            await admin.auth.admin.deleteUser(userId);
          }
          return fail('CREATE_FAILED', orderErr.message);
        }

        await admin.from('order_items').insert((items as any[]).map((i: any) => ({ order_id: order.id, sparepart_id: i.sparepart_id || null, service_type: i.service_type, complaint: i.complaint, item_price: i.item_price || 0 })));
        await admin.from('service_tracking').insert({ order_id: order.id, status: 'waiting_device', note: 'Order dibuat', created_by_type: 'customer', created_by_id: userId });
        await admin.from('notifications').insert({ store_id, role: 'store_admin', type: 'new_order', title: 'Pesanan Baru', message: `#${orderNumber} — ${brand} ${device_model}`, link_to: `/store/orders/${order.id}` });

        if (isNew) {
          await sendOrderConfirmation(customerEmail, tempPassword, orderNumber, customer_name as string, admin);
        }

        const emailOk = Deno.env.get('RESEND_API_KEY') ? true : false;
        return ok({ order_id: order.id, order_number: orderNumber, email: customerEmail, is_new_customer: isNew, temp_password: isNew ? tempPassword : undefined, message: isNew ? (emailOk ? 'Cek Email' : 'Simpan password') : 'OK', isGuest: true });
      }

      // ─── TRACK ───
      if (action === 'track') {
        const { order_number, email: trackEmail } = body as Record<string, unknown>;
        if (!order_number || !trackEmail) return fail('INVALID_INPUT', 'order_number and email required');
        const queryEmail = (trackEmail as string).trim().toLowerCase();
        const { data: order } = await admin.from('service_orders').select('*, user:users(id), tracking:service_tracking(*), store:stores(store_name)').eq('order_number', order_number).single();
        if (!order || order.user.id !== queryEmail && order.user.email !== queryEmail) return fail('ORDER_NOT_FOUND', 'Order not found', 404);
        return ok({
          order_number: order.order_number, status: order.status, store_name: order.store.store_name,
          device_type: order.device_type, brand: order.brand, device_model: order.device_model,
          delivery_method: order.delivery_method, created_at: order.created_at,
          tracking: order.tracking.map((t: any) => ({ status: t.status, note: t.note, created_at: t.created_at })),
        });
      }

      // ─── CREDENTIALS ───
      if (action === 'credentials') {
        const { order_id, email: credEmail } = body as Record<string, unknown>;
        if (!order_id || !credEmail) return fail('INVALID_INPUT', 'order_id and email required');
        const queryEmail = (credEmail as string).trim().toLowerCase();
        let { data: order } = await admin.from('service_orders').select('*, user:users(*)').eq('id', order_id).maybeSingle();
        if (!order) order = (await admin.from('service_orders').select('*, user:users(*)').eq('order_number', order_id).single()).data;
        if (!order || order.user.email !== queryEmail) return fail('ORDER_NOT_FOUND', 'Order not found', 404);
        const user = order.user;
        const canActivate = ['device_received','diagnosing','waiting_approval','waiting_sparepart','repairing','quality_check','waiting_payment','completed'].includes(order.status);
        const isActivated = user.account_status === 'active';
        return ok({ order_number: order.order_number, status: order.status, can_activate: canActivate, is_activated: isActivated, email: user.email, has_credential: !isActivated, temp_password: user.password_hash, full_name: user.full_name });
      }

      return fail('NOT_FOUND', 'Unknown action', 404);
    } catch (err) {
      console.error('Guest EF error:', err);
      if (isNew && userId) {
        const { supabaseAdmin: admin } = ctx;
        await admin.auth.admin.deleteUser(userId).catch(() => {});
      }
      return fail('INTERNAL', err instanceof Error ? err.message : 'Unknown error', 500);
    }
  }),
}
