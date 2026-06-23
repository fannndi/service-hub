import { withSupabase } from 'npm:@supabase/server'
import { assertValidTransition, ok, fail } from '../_shared/helpers.ts'

export default {
  fetch: withSupabase({ auth: 'user' }, async (req: Request, ctx) => {
    if (req.method !== 'POST') return fail('METHOD_NOT_ALLOWED', 'POST only', 405);

    try {
      const { userClaims, supabaseAdmin: admin, supabase: sb } = ctx;
      if (!userClaims) return fail('UNAUTHORIZED', 'Unauthorized', 401);

      const role = userClaims.userMetadata?.role as string;
      const body = await req.json();

      const url = new URL(req.url);
      const action = url.pathname.split('/').pop();

      // ─── CREATE ORDER (Customer) ───
      if (action === 'orders') {
        const { store_id, device_type, brand, device_model, delivery_method, delivery_address, customer_name, phone_number, items, coupon_code } = body;

        if (!items || items.length === 0) return fail('INVALID_INPUT', 'Minimal 1 item');

        const { data: store } = await admin.from('stores').select('id').eq('id', store_id).eq('is_active', true).single();
        if (!store) return fail('STORE_NOT_ACTIVE', 'Toko tidak aktif');

        for (const item of items) {
          if (item.sparepart_id) {
            const { data: reserved } = await admin.rpc('reserve_stock', { p_sparepart_id: item.sparepart_id, p_qty: 1 });
            if (!reserved) return fail('STOCK_UNAVAILABLE', `Stok tidak tersedia`);
          }
        }

        let coupon_id: string | null = null;
        let discount = 0;
        if (coupon_code) {
          const { data: coupon } = await admin.from('coupons')
            .select('id, amount').eq('code', coupon_code).eq('user_id', userClaims.id).eq('is_used', false).gt('expired_at', new Date().toISOString()).single();
          if (!coupon) return fail('COUPON_INVALID', 'Kupon tidak valid');
          coupon_id = coupon.id;
          discount = coupon.amount;
        }

        const totalEstimasi = items.reduce((sum: number, i: any) => sum + (i.item_price || 0), 0);
        const dateStr = new Date().toISOString().slice(0, 10).replace(/-/g, '');
        const chars = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';
        const rand = Array.from({ length: 6 }, () => chars[Math.floor(Math.random() * chars.length)]).join('');
        const order_number = `SG-${dateStr}-${rand}`;

        const { data: order, error: orderErr } = await admin.from('service_orders').insert({
          user_id: userClaims.id, store_id, order_number, device_type, brand, device_model,
          delivery_method, delivery_address: delivery_address || null,
          status: 'waiting_device', total_estimasi: totalEstimasi, discount_amount: discount, coupon_id,
        }).select().single();

        if (orderErr) return fail('CREATE_FAILED', orderErr.message);

        await admin.from('order_items').insert(items.map((item: any) => ({
          order_id: order.id, sparepart_id: item.sparepart_id || null,
          service_type: item.service_type, complaint: item.complaint, item_price: item.item_price || 0,
        })));

        if (coupon_id) await admin.from('coupons').update({ is_used: true, used_at: new Date().toISOString(), used_on_order_id: order.id }).eq('id', coupon_id);

        await admin.from('service_tracking').insert({
          order_id: order.id, status: 'waiting_device', note: 'Order dibuat',
          created_by_type: 'customer', created_by_id: userClaims.id,
        });

        return ok({ order_id: order.id, order_number });
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
        await admin.from('service_orders').update({ status: 'repairing', sla_deadline: null }).eq('id', order.id);
        await admin.from('service_tracking').insert({ order_id: order.id, status: 'repairing', note: 'Order disetujui, perbaikan dimulai', created_by_type: 'customer', created_by_id: userClaims.id });
        return ok({ status: 'repairing' });
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
        await admin.from('service_orders').update({ status: 'cancelled', cancelled_at: new Date().toISOString() }).eq('id', order.id);
        await admin.from('service_tracking').insert({ order_id: order.id, status: 'cancelled', note: 'Order ditolak oleh pelanggan', created_by_type: 'customer', created_by_id: userClaims.id });
        return ok({ status: 'cancelled' });
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

        await admin.from('service_orders').update({ status: 'waiting_approval', final_price: finalPrice, service_fee: service_fee || 0, diagnosis_note: diagnosis_note || null, sla_deadline: null }).eq('id', order.id);
        await admin.from('service_tracking').insert({ order_id: order.id, status: 'waiting_approval', note: 'Diagnosa dikirim', created_by_type: 'store_admin', created_by_id: userClaims.id });
        return ok({ final_price: finalPrice });
      }

      // ─── STATUS UPDATE (Store Admin) ───
      if (action === 'status') {
        if (role !== 'store_admin') return fail('FORBIDDEN', 'Unauthorized', 403);
        const { order_id, status, note } = body;

        const { data: adminRow } = await admin.from('store_admins').select('store_id').eq('id', userClaims.id).single();
        if (!adminRow) return fail('FORBIDDEN', 'Unauthorized', 403);

        const { data: order } = await admin.from('service_orders').select('*, order_items(id, sparepart_id)').eq('id', order_id).eq('store_id', adminRow.store_id).single();
        if (!order) return fail('ORDER_NOT_FOUND', 'Pesanan tidak ditemukan', 404);
        assertValidTransition(order.status, status);

        if (order.status === 'waiting_sparepart' && status === 'repairing') {
          for (const item of order.order_items) {
            if (item.sparepart_id) await admin.rpc('consume_stock', { p_sparepart_id: item.sparepart_id });
          }
        }

        const update: Record<string, any> = { status };
        if (status === 'completed') update.completed_at = new Date().toISOString();
        if (status === 'cancelled') update.cancelled_at = new Date().toISOString();
        if (status === 'waiting_payment') update.sla_deadline = null;

        await admin.from('service_orders').update(update).eq('id', order.id);
        await admin.from('service_tracking').insert({ order_id: order.id, status, note: note || null, created_by_type: 'store_admin', created_by_id: userClaims.id });
        if (status === 'completed') await admin.rpc('update_rating_avg', { p_store_id: adminRow.store_id });

        return ok({ status });
      }

      return fail('NOT_FOUND', 'Endpoint not found', 404);
    } catch (err: any) {
      return fail(err.code || 'INTERNAL', err.message, 500);
    }
  }),
}
