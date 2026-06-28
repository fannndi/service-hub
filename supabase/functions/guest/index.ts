import { withSupabase } from 'npm:@supabase/server'
import { ok, fail } from '../_shared/helpers.ts'
import { corsHeaders } from '../_shared/cors.ts'
import { sendWA, isWAConfigured } from '../_shared/whatsapp.ts'

export default {
  fetch: withSupabase({ auth: 'none' }, async (req: Request, ctx) => {
    if (req.method === 'OPTIONS') return new Response('ok', { headers: { ...corsHeaders } });
    let isNew = false;
    let userId = '';
    try {
      const body = await req.json();
      const action = body.action as string;
      const { supabaseAdmin: admin } = ctx;

      // ─── CREATE ORDER ───
      if (action === 'create-order') {
        const { store_id, device_type, brand, device_model, delivery_method, delivery_address, customer_name, phone_number, items } = body as any;
        if (!store_id || !device_type || !brand || !device_model || !customer_name || !phone_number || !items?.length) {
          return fail('INVALID_INPUT', 'Missing required fields');
        }
        const phone = phone_number.replace(/\D/g, '').replace(/^62/, '08').replace(/^8/, '08');
        const password = Array.from({ length: 12 }, () => 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789'[Math.floor(Math.random() * 57)]).join('');
        const now = new Date().toISOString();

        const { data: existing } = await admin.from('users').select('id').eq('phone_number', phone).maybeSingle();
        if (existing) { userId = existing.id; }
        else {
          const { data: nu } = await admin.from('users').insert({ full_name: customer_name, phone_number: phone, password_hash: password, account_status: 'suspended', is_first_login: true, is_credential_sent: false, updated_at: now }).select('id').single();
          if (!nu) return fail('CREATE_FAILED', 'Failed to create user');
          userId = nu.id; isNew = true;
        }

        const { data: store } = await admin.from('stores').select('id, phone_number').eq('id', store_id).eq('is_active', true).single();
        if (!store) return fail('STORE_NOT_ACTIVE', 'Store not active');

        for (const item of items) {
          if (item.sparepart_id) {
            const { data: reserved } = await admin.rpc('reserve_stock', { p_sparepart_id: item.sparepart_id, p_qty: 1 });
            if (!reserved) return fail('STOCK_UNAVAILABLE', 'Stock unavailable');
          }
        }

        const dateStr = now.slice(0, 10).replace(/-/g, '');
        const rand = Array.from({ length: 6 }, () => '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ'[Math.floor(Math.random() * 36)]).join('');
        const orderNumber = `SG-${dateStr}-${rand}`;
        const totalEstimasi = items.reduce((s: number, i: any) => s + (i.item_price || 0), 0);

        const { data: order, error: orderErr } = await admin.from('service_orders').insert({
          user_id: userId, store_id, order_number: orderNumber, device_type, brand, device_model,
          delivery_method, delivery_address: delivery_address || null, status: 'waiting_device',
          total_estimasi: totalEstimasi, sla_deadline: new Date(Date.now() + 86400000).toISOString(), updated_at: now,
        }).select().single();
        if (orderErr) {
          if (isNew) await admin.from('users').delete().eq('id', userId);
          return fail('CREATE_FAILED', orderErr.message);
        }

        await admin.from('order_items').insert(items.map((i: any) => ({ order_id: order.id, sparepart_id: i.sparepart_id || null, service_type: i.service_type, complaint: i.complaint, item_price: i.item_price || 0 })));
        await admin.from('service_tracking').insert({ order_id: order.id, status: 'waiting_device', note: 'Order dibuat', created_by_type: 'customer', created_by_id: userId });
        await admin.from('notifications').insert({ store_id, role: 'store_admin', type: 'new_order', title: 'Pesanan Baru', message: `#${orderNumber} — ${brand} ${device_model}`, link_to: `/store/orders/${order.id}` });

        if (isNew) {
          await sendWA(phone, `Halo ${customer_name}!\nAkun ServisGadget kamu sudah dibuat.\nNomor HP: ${phone}\nPassword: ${password}\nSegera login dan ganti passwordmu.`);
        }

        const waOk = isWAConfigured();
        return ok({ order_id: order.id, order_number: orderNumber, phone_number: phone, is_new_customer: isNew, temp_password: isNew ? password : undefined, message: isNew ? (waOk ? 'Cek WhatsApp' : 'Simpan password') : 'OK' });
      }

      // ─── TRACK ───
      if (action === 'track') {
        const { order_number, phone_number } = body as any;
        if (!order_number || !phone_number) return fail('INVALID_INPUT', 'order_number and phone_number required');
        const phone = phone_number.replace(/\D/g, '').replace(/^62/, '08').replace(/^8/, '08');
        const { data: order } = await admin.from('service_orders').select('*, user:users(phone_number), tracking:service_tracking(*), store:stores(store_name)').eq('order_number', order_number).single();
        if (!order || order.user.phone_number !== phone) return fail('ORDER_NOT_FOUND', 'Order not found', 404);
        return ok({
          order_number: order.order_number, status: order.status, store_name: order.store.store_name,
          device_type: order.device_type, brand: order.brand, device_model: order.device_model,
          delivery_method: order.delivery_method, created_at: order.created_at,
          tracking: order.tracking.map((t: any) => ({ status: t.status, note: t.note, created_at: t.created_at })),
        });
      }

      // ─── CREDENTIALS ───
      if (action === 'credentials') {
        const { order_id, phone_number } = body as any;
        if (!order_id || !phone_number) return fail('INVALID_INPUT', 'order_id and phone_number required');
        const phone = phone_number.replace(/\D/g, '').replace(/^62/, '08').replace(/^8/, '08');
        let { data: order } = await admin.from('service_orders').select('*, user:users(*)').eq('id', order_id).maybeSingle();
        if (!order) order = (await admin.from('service_orders').select('*, user:users(*)').eq('order_number', order_id).single()).data;
        if (!order || order.user.phone_number !== phone) return fail('ORDER_NOT_FOUND', 'Order not found', 404);
        const user = order.user;
        const canActivate = ['device_received','diagnosing','waiting_approval','waiting_sparepart','repairing','quality_check','waiting_payment','completed'].includes(order.status);
        const isActivated = user.account_status === 'active';
        return ok({ order_number: order.order_number, status: order.status, can_activate: canActivate, is_activated: isActivated, phone_number: user.phone_number, has_credential: !isActivated, masked_password: null, full_name: user.full_name });
      }

      return fail('NOT_FOUND', 'Unknown action', 404);
    } catch (err: any) {
      console.error('Guest EF error:', err);
      if (isNew && userId) {
        const { supabaseAdmin: admin } = ctx;
        await admin.from('users').delete().eq('id', userId);
        console.error(`Orphan user ${userId} deleted after error`);
      }
      return fail('INTERNAL', err.message || 'Unknown error', 500);
    }
  }),
}
