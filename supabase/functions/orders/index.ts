import { withSupabase } from 'npm:@supabase/server'
import { assertValidTransition, VALID_TRANSITIONS, ok, fail, requireUser } from '../_shared/helpers.ts'
import { corsHeaders } from '../_shared/cors.ts'
import { sendActivationEmail, isEmailConfigured } from '../_shared/email.ts'
import { generateOrderNumber } from '../_shared/crypto.ts'

async function autoActivateGuest(userId: string, admin: any): Promise<void> {
  const { data: user } = await admin.from('users').select('*').eq('id', userId).single();
  if (!user || user.account_status === 'active') return;
  const { data: authUser, error: authErr } = await admin.auth.admin.getUserById(userId);
  if (authErr || !authUser?.user?.email) { console.error('autoActivateGuest: cannot get auth user email'); return; }
  const tempPw = Math.random().toString(36).slice(2, 10) + Math.random().toString(36).slice(2, 6).toUpperCase();
  await admin.auth.admin.updateUserById(userId, { password: tempPw });
  await admin.from('users').update({
    account_status: 'active', is_first_login: true, updated_at: new Date().toISOString(),
  }).eq('id', userId);
  if (isEmailConfigured()) {
    await sendActivationEmail(authUser.user.email, user.full_name, tempPw, admin);
  }
}

export default {
  fetch: withSupabase({ auth: 'none' }, async (req: Request, ctx) => {
    if (req.method === 'OPTIONS') return new Response('ok', { headers: { ...corsHeaders } });
    if (req.method !== 'POST') return fail('METHOD_NOT_ALLOWED', 'POST only', 405);

    try {
      const { supabaseAdmin: admin, supabase: sb } = ctx; const userClaims = await requireUser(req, admin);

      const role = userClaims.userMetadata?.role as string;
      const body = await req.json();
      const now = new Date().toISOString();
      const action = body.action as string | undefined;

      // ─── CREATE ORDER (Customer) ───
      if (action === 'orders') {
        const { store_id, device_type, brand, device_model, delivery_method, delivery_address, customer_name, phone_number, items, coupon_code } = body;

        if (!items || items.length === 0) return fail('INVALID_INPUT', 'Minimal 1 item');

        const { data: store } = await admin.from('stores').select('id, config').eq('id', store_id).eq('is_active', true).single();
        if (!store) return fail('STORE_NOT_ACTIVE', 'Toko tidak aktif');

        for (const i of items) {
          if (typeof i.item_price !== 'number' || i.item_price < 0) {
            return fail('INVALID_PRICE', 'Item price must be non-negative');
          }
        }

        const reservedIds: string[] = [];
        for (const item of items) {
          if (item.sparepart_id) {
            const { data: reserved } = await admin.rpc('reserve_stock', { p_sparepart_id: item.sparepart_id, p_qty: 1 });
            if (!reserved) {
              for (const id of reservedIds) await admin.rpc('release_stock', { p_sparepart_id: id }).catch(() => {});
              return fail('STOCK_UNAVAILABLE', `Stok tidak tersedia`);
            }
            reservedIds.push(item.sparepart_id);
          }
        }

        let coupon_id: string | null = null;
        let discount = 0;
        if (coupon_code) {
          const { data: coupon } = await admin.from('coupons')
            .select('id, amount').eq('code', coupon_code).eq('user_id', userClaims.id).eq('is_used', false).gt('expired_at', new Date().toISOString()).single();
          if (!coupon) {
            for (const id of reservedIds) await admin.rpc('release_stock', { p_sparepart_id: id }).catch(() => {});
            return fail('COUPON_INVALID', 'Kupon tidak valid');
          }
          coupon_id = coupon.id;
          discount = coupon.amount;
        }
        const totalEstimasi = items.reduce((sum: number, i: any) => sum + (i.item_price || 0), 0);
        const order_number = generateOrderNumber();

        const { data: order, error: orderErr } = await admin.from('service_orders').insert({
          user_id: userClaims.id, store_id, order_number, device_type, brand, device_model,
          delivery_method, delivery_address: delivery_address || null,
          status: 'waiting_device', total_estimasi: totalEstimasi, discount_amount: discount, coupon_id, updated_at: now,
        }).select().single();

        if (orderErr) {
          for (const id of reservedIds) await admin.rpc('release_stock', { p_sparepart_id: id }).catch(() => {});
          return fail('CREATE_FAILED', orderErr.message);
        }

        await admin.from('order_items').insert(items.map((item: any) => ({
          order_id: order.id, sparepart_id: item.sparepart_id || null,
          service_type: item.service_type, complaint: item.complaint, item_price: item.item_price || 0,
        })));

        if (coupon_id) await admin.from('coupons').update({ is_used: true, used_at: new Date().toISOString(), used_on_order_id: order.id }).eq('id', coupon_id);

        await admin.from('service_tracking').insert({
          order_id: order.id, status: 'waiting_device', note: 'Order dibuat',
          created_by_type: 'customer', created_by_id: userClaims.id,
        });

        await admin.from('notifications').insert({
          store_id, role: 'store_admin', type: 'new_order',
          title: 'Pesanan Baru', message: `#${order_number} — ${brand} ${device_model}`,
          link_to: `/store/orders/${order.id}`,
        });

        return ok({
          order_id: order.id, order_number, total_estimasi: totalEstimasi - discount,
          status: 'waiting_device', is_new_customer: true,
          message: 'Pesanan berhasil dibuat', allowed_actions: VALID_TRANSITIONS['waiting_device'] || [],
        });
      }

      // ─── APPROVE ORDER ───
      if (action === 'approve') {
        const { order_id } = body;
        const { data: order } = await admin.from('service_orders').select('*, order_items(id, sparepart_id)').eq('id', order_id).eq('user_id', userClaims.id).single();
        if (!order) return fail('ORDER_NOT_FOUND', 'Pesanan tidak ditemukan', 404);
        assertValidTransition(order.status, 'repairing');

        for (const item of order.order_items) {
          if (item.sparepart_id) await admin.rpc('consume_stock', { p_sparepart_id: item.sparepart_id });
        }
        await admin.from('service_orders').update({ status: 'repairing', sla_deadline: null, updated_at: now }).eq('id', order.id);
        await admin.from('service_tracking').insert({ order_id: order.id, status: 'repairing', note: 'Order disetujui, perbaikan dimulai', created_by_type: 'customer', created_by_id: userClaims.id });
        return ok({ status: 'repairing', allowed_actions: VALID_TRANSITIONS['repairing'] || [] });
      }

      // ─── REJECT ORDER ───
      if (action === 'reject') {
        const { order_id } = body;
        const { data: order } = await admin.from('service_orders').select('*, order_items(id, sparepart_id)').eq('id', order_id).eq('user_id', userClaims.id).single();
        if (!order) return fail('ORDER_NOT_FOUND', 'Pesanan tidak ditemukan', 404);
        assertValidTransition(order.status, 'cancelled');

        for (const item of order.order_items) {
          if (item.sparepart_id) await admin.rpc('release_stock', { p_sparepart_id: item.sparepart_id });
        }
        await admin.from('service_orders').update({ status: 'cancelled', cancelled_at: new Date().toISOString(), updated_at: now }).eq('id', order.id);
        await admin.from('service_tracking').insert({ order_id: order.id, status: 'cancelled', note: 'Order ditolak oleh pelanggan', created_by_type: 'customer', created_by_id: userClaims.id });
        return ok({ status: 'cancelled', allowed_actions: [] });
      }

      // ─── DIAGNOSIS (Store Admin) ───
      if (action === 'diagnosis') {
        if (role !== 'store_admin') return fail('FORBIDDEN', 'Unauthorized', 403);
        const { order_id, diagnosis_note, service_fee, items } = body;

        const { data: adminRow } = await admin.from('store_admins').select('store_id').eq('id', userClaims.id).single();
        if (!adminRow) return fail('FORBIDDEN', 'Unauthorized', 403);

        const { data: order } = await admin.from('service_orders').select('*, order_items(id, sparepart_id)').eq('id', order_id).eq('store_id', adminRow.store_id).single();
        if (!order) return fail('ORDER_NOT_FOUND', 'Pesanan tidak ditemukan', 404);
        assertValidTransition(order.status, 'waiting_approval');

        const finalPrice = items.reduce((sum: number, i: any) => sum + i.final_item_price, 0) + (service_fee || 0);

        for (const item of items) {
          const oldItem = order.order_items.find((oi: any) => oi.id === item.order_item_id);
          if (oldItem?.sparepart_id && item.replaced_sparepart_id) {
            await admin.rpc('swap_sparepart', { p_old_id: oldItem.sparepart_id, p_new_id: item.replaced_sparepart_id });
          }
          await admin.from('order_items').update({ status: item.status, final_item_price: item.final_item_price, technician_note: item.technician_note || null }).eq('id', item.order_item_id);
        }

        await admin.from('service_orders').update({ status: 'waiting_approval', final_price: finalPrice, service_fee: service_fee || 0, diagnosis_note: diagnosis_note || null, sla_deadline: null, updated_at: now }).eq('id', order.id);
        await admin.from('service_tracking').insert({ order_id: order.id, status: 'waiting_approval', note: 'Diagnosa dikirim', created_by_type: 'store_admin', created_by_id: userClaims.id });
        await admin.from('notifications').insert({
          user_id: order.user_id, role: 'customer', type: 'diagnosis_result',
          title: 'Diagnosa Selesai', message: `Diagnosa untuk #${order.order_number} sudah selesai. Total: Rp ${finalPrice.toLocaleString()}. Silakan cek dan setujui.`,
          link_to: `/orders/${order_id}`,
        });
        return ok({ final_price: finalPrice, allowed_actions: VALID_TRANSITIONS['waiting_approval'] || [] });
      }

      // ─── STATUS UPDATE (Store Admin) ───
      if (action === 'status') {
        if (role !== 'store_admin') return fail('FORBIDDEN', 'Unauthorized', 403);
        const { order_id, status, note } = body;

        const { data: adminRow } = await admin.from('store_admins').select('store_id').eq('id', userClaims.id).single();
        if (!adminRow) return fail('FORBIDDEN', 'Unauthorized', 403);

        const { data: order } = await admin.from('service_orders').select('*, order_items(id, sparepart_id), user:users(account_status)').eq('id', order_id).eq('store_id', adminRow.store_id).single();
        if (!order) return fail('ORDER_NOT_FOUND', 'Pesanan tidak ditemukan', 404);
        assertValidTransition(order.status, status);

        if (status === 'device_received' && order.user?.account_status === 'suspended') {
          await autoActivateGuest(order.user_id, admin);
        }

        const update: Record<string, any> = { status, updated_at: now };
        if (status === 'completed') update.completed_at = new Date().toISOString();
        if (status === 'cancelled') update.cancelled_at = new Date().toISOString();

        let slaDeadline: string | null = null;
        const sla24h = ['device_received', 'diagnosing', 'waiting_approval', 'waiting_sparepart', 'repairing', 'quality_check'].includes(status);
        if (sla24h) {
          slaDeadline = new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString();
          update.sla_deadline = slaDeadline;
        }
        if (status === 'waiting_payment') {
          slaDeadline = new Date(Date.now() + 48 * 60 * 60 * 1000).toISOString();
          update.sla_deadline = slaDeadline;
        }

        if (order.status === 'waiting_sparepart' && status === 'repairing') {
          for (const item of order.order_items) {
            if (item.sparepart_id) await admin.rpc('consume_stock', { p_sparepart_id: item.sparepart_id });
          }
        }

        const slaTitleMap: Record<string, string> = {
          device_received: 'Perangkat Diterima', diagnosing: 'Diagnosis Dimulai',
          waiting_approval: 'Menunggu Persetujuan', waiting_sparepart: 'Menunggu Suku Cadang',
          repairing: 'Perbaikan Dimulai', quality_check: 'Quality Check', waiting_payment: 'Waktu Pembayaran',
        };
        if (slaDeadline) {
          await admin.from('notifications').insert({
            user_id: order.user_id,
            store_id: order.store_id,
            role: 'customer',
            title: `SLA - ${slaTitleMap[status]}`,
            message: sla24h
              ? `Status diperbarui ke ${status}. Batas waktu SLA: ${slaDeadline}.`
              : `Waktu pembayaran telah dimulai. Silakan selesaikan pembayaran sebelum ${slaDeadline}.`,
            type: 'sla',
            is_read: false,
            link_to: `/orders/${order_id}`,
          });
        }

        if (status === 'completed') {
          await admin.from('notifications').insert({
            user_id: order.user_id,
            store_id: order.store_id,
            role: 'customer',
            title: 'Order Selesai',
            message: `Order telah selesai. Terima kasih telah menggunakan layanan kami.`,
            type: 'order_completion',
            is_read: false,
            link_to: `/orders/${order_id}`,
          });
        }

        if (status === 'cancelled') {
          await admin.from('notifications').insert({
            user_id: order.user_id,
            store_id: order.store_id,
            role: 'customer',
            title: 'Order Dibatalkan',
            message: `Order telah dibatalkan.`,
            type: 'order_cancellation',
            is_read: false,
            link_to: `/orders/${order_id}`,
          });
        }

        await admin.from('service_orders').update(update).eq('id', order.id);
        await admin.from('service_tracking').insert({ order_id: order.id, status, note: note || null, created_by_type: 'store_admin', created_by_id: userClaims.id });
        if (status === 'completed') await admin.rpc('update_rating_avg', { p_store_id: adminRow.store_id });

        return ok({ status, allowed_actions: VALID_TRANSITIONS[status] || [] });
      }

      return fail('NOT_FOUND', 'Endpoint not found', 404);
    } catch (err: any) {
      return fail(err.code || 'INTERNAL', err.message, 500);
    }
  }),
}
