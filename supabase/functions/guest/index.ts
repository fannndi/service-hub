import { withSupabase } from 'npm:@supabase/server'
import { ok, fail } from '../_shared/helpers.ts'
import { corsHeaders } from '../_shared/cors.ts'
import { sendOrderConfirmation } from '../_shared/email.ts'
import { generatePassword, generateOrderNumber } from '../_shared/crypto.ts'

const VALID_ACTIONS = ['create-order', 'track', 'credentials'];

interface OrderItem {
  sparepart_id?: string;
  service_type?: string;
  complaint?: string;
  item_price?: number;
}

export default {
  fetch: withSupabase({ auth: 'none' }, async (req: Request, ctx) => {
    if (req.method === 'OPTIONS') return new Response('ok', { headers: { ...corsHeaders } });
    let isNew = false;
    let userId = '';
    let tempPassword = '';
    const reservedSparepartIds: string[] = [];
    try {
      const body = await req.json();
      const action = body.action as string;
      const { supabaseAdmin: admin } = ctx;

      if (!VALID_ACTIONS.includes(action)) return fail('NOT_FOUND', 'Unknown action', 404);

      // ─── CREATE ORDER ───
      if (action === 'create-order') {
        console.error('DEBUG admin keys:', Object.keys(admin).join(','));
        const { store_id, device_type, brand, device_model, delivery_method, delivery_address, customer_name, email, items } = body as Record<string, unknown>;
        if (!store_id || !device_type || !brand || !device_model || !customer_name || !email || !items?.length) {
          return fail('INVALID_INPUT', 'Missing required fields');
        }
        const customerEmail = (email as string).trim().toLowerCase();
        tempPassword = generatePassword();
        const now = new Date().toISOString();

        const fiveMinAgo = new Date(Date.now() - 5 * 60 * 1000).toISOString();
        const { data: rateUser } = await admin.from('users').select('id').eq('email', customerEmail).maybeSingle();
        if (rateUser) {
          const { count } = await admin.from('service_orders')
            .select('*', { count: 'exact', head: true })
            .eq('user_id', rateUser.id).gte('created_at', fiveMinAgo);
          if (count && count >= 5) {
            return fail('RATE_LIMITED', 'Too many orders. Try again later.', 429);
          }
        }

        const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || '';
        const supabaseUrl = Deno.env.get('SUPABASE_URL') || '';
        const signUpRes = await fetch(`${supabaseUrl}/auth/v1/admin/users`, {
          method: 'POST',
          headers: { 'apikey': serviceKey, 'Authorization': `Bearer ${serviceKey}`, 'Content-Type': 'application/json' },
          body: JSON.stringify({ email: customerEmail, password: tempPassword, email_confirm: true, user_metadata: { role: 'customer', full_name: customer_name } }),
        });
        const signUpBody = await signUpRes.json();
        if (!signUpRes.ok) {
          if (signUpBody.msg?.includes('already') || signUpBody.msg?.includes('exists')) {
            return fail('EMAIL_EXISTS', 'Email sudah terdaftar. Silakan login.');
          }
          return fail('CREATE_FAILED', `Auth user creation failed: ${signUpBody.msg || signUpRes.statusText}`);
        }
        userId = signUpBody.id;
        if (!userId) return fail('CREATE_FAILED', 'Auth user created but no ID returned');
        isNew = true;
        await admin.from('users').update({
          account_status: 'suspended', is_first_login: true, is_credential_sent: false, updated_at: now,
        }).eq('id', userId);

        const { data: store } = await admin.from('stores').select('id, phone_number').eq('id', store_id).eq('is_active', true).single();
        if (!store) return fail('STORE_NOT_ACTIVE', 'Store not active');

        // C7: Track reserved sparepart IDs for rollback
        for (const item of items as OrderItem[]) {
          if (item.sparepart_id) {
            const { data: reserved } = await admin.rpc('reserve_stock', { p_sparepart_id: item.sparepart_id, p_qty: 1 });
            if (!reserved) return fail('STOCK_UNAVAILABLE', 'Stock unavailable');
            reservedSparepartIds.push(item.sparepart_id);
          }
        }

        for (const i of items as OrderItem[]) {
          if (typeof i.item_price !== 'number' || i.item_price < 0) {
            return fail('INVALID_PRICE', 'Item price must be non-negative');
          }
        }
        const orderNumber = generateOrderNumber();
        const totalEstimasi = (items as OrderItem[]).reduce((s: number, i: OrderItem) => s + (i.item_price || 0), 0);

        const { data: order, error: orderErr } = await admin.from('service_orders').insert({
          user_id: userId, store_id, order_number: orderNumber, device_type, brand, device_model,
          delivery_method, delivery_address: delivery_address || null, status: 'waiting_device',
          total_estimasi: totalEstimasi, sla_deadline: new Date(Date.now() + 86400000).toISOString(), updated_at: now,
        }).select().single();
        if (orderErr) {
          if (isNew) await admin.auth.admin.deleteUser(userId);
          for (const spId of reservedSparepartIds) await admin.rpc('release_stock', { p_sparepart_id: spId });
          return fail('CREATE_FAILED', orderErr.message);
        }

        await admin.from('order_items').insert((items as OrderItem[]).map((i: OrderItem) => ({ order_id: order.id, sparepart_id: i.sparepart_id || null, service_type: i.service_type, complaint: i.complaint, item_price: i.item_price || 0 })));
        await admin.from('service_tracking').insert({ order_id: order.id, status: 'waiting_device', note: 'Order dibuat', created_by_type: 'customer', created_by_id: userId });
        await admin.from('notifications').insert({ store_id, role: 'store_admin', type: 'new_order', title: 'Pesanan Baru', message: `#${orderNumber} — ${brand} ${device_model}`, link_to: `/store/orders/${order.id}` });

        if (isNew) {
          await sendOrderConfirmation(customerEmail, tempPassword, orderNumber, customer_name as string, admin);
        }

        return ok({ order_id: order.id, order_number: orderNumber, email: customerEmail, is_new_customer: isNew, temp_password: isNew ? tempPassword : undefined, message: isNew ? 'Cek email untuk kredensial login' : 'OK', isGuest: true });
      }

      // ─── TRACK ───
      if (action === 'track') {
        const { order_number, email: trackEmail } = body as Record<string, unknown>;
        if (!order_number || !trackEmail) return fail('INVALID_INPUT', 'order_number and email required');
        const queryEmail = (trackEmail as string).trim().toLowerCase();
        // C2: Select email from users table, compare correctly
        const { data: order } = await admin.from('service_orders').select('*, user:users(id, email), tracking:service_tracking(*), store:stores(store_name)').eq('order_number', order_number).single();
        if (!order || order.user.email !== queryEmail) return fail('ORDER_NOT_FOUND', 'Order not found', 404);
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
        if (!order) order = (await admin.from('service_orders').select('*, user:users(*)').eq('order_number', order_id).maybeSingle()).data;
        if (!order || order.user.email !== queryEmail) return fail('ORDER_NOT_FOUND', 'Order not found', 404);
        const user = order.user;
        const canActivate = ['device_received','diagnosing','waiting_approval','waiting_sparepart','repairing','quality_check','waiting_payment','completed'].includes(order.status);
        const isActivated = user.account_status === 'active';
        // C4: Don't expose password_hash - return null instead
        return ok({ order_number: order.order_number, status: order.status, can_activate: canActivate, is_activated: isActivated, email: user.email, has_credential: !isActivated, temp_password: null, full_name: user.full_name });
      }

      return fail('NOT_FOUND', 'Unknown action', 404);
    } catch (err) {
      console.error('Guest EF error:', err);
      // C7: Release any reserved stock on unexpected error
      for (const spId of reservedSparepartIds) {
        const { supabaseAdmin: admin } = ctx;
        try { await admin.rpc('release_stock', { p_sparepart_id: spId }); } catch (_) {}
      }
      if (isNew && userId) {
        const { supabaseAdmin: admin } = ctx;
        try { await admin.auth.admin.deleteUser(userId); } catch (_) {}
      }
      return fail('INTERNAL', err instanceof Error ? err.message : 'Unknown error', 500);
    }
  }),
}
