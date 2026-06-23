import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';
import { createClient, SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { corsHeaders } from '../_shared/cors.ts';
import { assertValidTransition, ok, fail } from '../_shared/helpers.ts';

function supabase(req: Request): SupabaseClient {
  return createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_ANON_KEY')!,
    { global: { headers: { Authorization: req.headers.get('Authorization')! } } }
  );
}

function adminClient(): SupabaseClient {
  return createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  );
}

function generateOrderNumber(): string {
  const d = new Date();
  const datePart = d.toISOString().slice(0, 10).replace(/-/g, '');
  const chars = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  const rand = Array.from({ length: 6 }, () => chars[Math.floor(Math.random() * chars.length)]).join('');
  return `SG-${datePart}-${rand}`;
}

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') return new Response(null, { headers: corsHeaders });

  try {
    const url = new URL(req.url);
    const path = url.pathname.split('/').pop();
    const body = req.method === 'POST' ? await req.json() : {};

    const sb = supabase(req);
    const { data: { user } } = await sb.auth.getUser();
    if (!user) return fail('UNAUTHORIZED', 'Unauthorized', 401);

    const role = user.user_metadata?.role as string;
    const admin = adminClient();

    // ─── CREATE ORDER (Customer) ───
    if (path === 'orders' && req.method === 'POST') {
      const { store_id, device_type, brand, device_model, delivery_method, delivery_address, customer_name, phone_number, items, coupon_code } = body;

      if (!items || items.length === 0) return fail('INVALID_INPUT', 'Minimal 1 item');

      // Validate store is active
      const { data: store } = await admin.from('stores').select('id').eq('id', store_id).eq('is_active', true).single();
      if (!store) return fail('STORE_NOT_ACTIVE', 'Toko tidak aktif');

      // Reserve stock for each item
      for (const item of items) {
        if (item.sparepart_id) {
          const { data: reserved } = await admin.rpc('reserve_stock', { p_sparepart_id: item.sparepart_id, p_qty: 1 });
          if (!reserved) return fail('STOCK_UNAVAILABLE', `Stok tidak tersedia untuk ${item.sparepart_id}`);
        }
      }

      // Validate coupon if provided
      let coupon_id: string | null = null;
      let discount = 0;
      if (coupon_code) {
        const { data: coupon } = await admin.from('coupons')
          .select('id, amount')
          .eq('code', coupon_code)
          .eq('user_id', user.id)
          .eq('is_used', false)
          .gt('expired_at', new Date().toISOString())
          .single();
        if (!coupon) return fail('COUPON_INVALID', 'Kupon tidak valid');
        coupon_id = coupon.id;
        discount = coupon.amount;
      }

      // Calculate total
      const totalEstimasi = items.reduce((sum: number, i: any) => sum + (i.item_price || 0), 0);
      const order_number = generateOrderNumber();

      // Create order
      const { data: order, error: orderErr } = await admin.from('service_orders').insert({
        user_id: user.id,
        store_id,
        order_number,
        device_type,
        brand,
        device_model,
        delivery_method,
        delivery_address: delivery_address || null,
        status: 'waiting_device',
        total_estimasi: totalEstimasi,
        discount_amount: discount,
        coupon_id,
      }).select().single();

      if (orderErr) return fail('CREATE_FAILED', orderErr.message);

      // Create order items
      const orderItems = items.map((item: any) => ({
        order_id: order.id,
        sparepart_id: item.sparepart_id || null,
        service_type: item.service_type,
        complaint: item.complaint,
        item_price: item.item_price || 0,
      }));
      await admin.from('order_items').insert(orderItems);

      // Mark coupon used
      if (coupon_id) {
        await admin.from('coupons').update({ is_used: true, used_at: new Date().toISOString(), used_on_order_id: order.id }).eq('id', coupon_id);
      }

      // Create tracking
      await admin.from('service_tracking').insert({
        order_id: order.id,
        status: 'waiting_device',
        note: 'Order dibuat',
        created_by_type: 'customer',
        created_by_id: user.id,
      });

      return ok({ order_id: order.id, order_number });
    }

    // ─── APPROVE ORDER (Customer) ───
    if (path === 'approve' && req.method === 'POST') {
      const { order_id } = body;

      const { data: order } = await admin.from('service_orders')
        .select('*, order_items(id, sparepart_id)')
        .eq('id', order_id)
        .eq('user_id', user.id)
        .single();

      if (!order) return fail('ORDER_NOT_FOUND', 'Pesanan tidak ditemukan', 404);
      assertValidTransition(order.status, 'repairing');

      // Consume stock for each replaced item
      for (const item of order.order_items) {
        if (item.sparepart_id) {
          await admin.rpc('consume_stock', { p_sparepart_id: item.sparepart_id });
        }
      }

      await admin.from('service_orders').update({ status: 'repairing', sla_deadline: null }).eq('id', order.id);
      await admin.from('service_tracking').insert({
        order_id: order.id,
        status: 'repairing',
        note: 'Order disetujui, perbaikan dimulai',
        created_by_type: 'customer',
        created_by_id: user.id,
      });

      return ok({ status: 'repairing' });
    }

    // ─── REJECT ORDER (Customer) ───
    if (path === 'reject' && req.method === 'POST') {
      const { order_id } = body;

      const { data: order } = await admin.from('service_orders')
        .select('*, order_items(id, sparepart_id)')
        .eq('id', order_id)
        .eq('user_id', user.id)
        .single();

      if (!order) return fail('ORDER_NOT_FOUND', 'Pesanan tidak ditemukan', 404);
      assertValidTransition(order.status, 'cancelled');

      for (const item of order.order_items) {
        if (item.sparepart_id) {
          await admin.rpc('release_stock', { p_sparepart_id: item.sparepart_id });
        }
      }

      await admin.from('service_orders').update({ status: 'cancelled', cancelled_at: new Date().toISOString() }).eq('id', order.id);
      await admin.from('service_tracking').insert({
        order_id: order.id,
        status: 'cancelled',
        note: 'Order ditolak oleh pelanggan',
        created_by_type: 'customer',
        created_by_id: user.id,
      });

      return ok({ status: 'cancelled' });
    }

    // ─── DIAGNOSIS (Store Admin) ───
    if (path === 'diagnosis' && req.method === 'POST') {
      if (role !== 'store_admin') return fail('FORBIDDEN', 'Unauthorized', 403);

      const { order_id, diagnosis_note, service_fee, items } = body;

      // Get store admin's store
      const { data: adminRow } = await admin.from('store_admins').select('store_id').eq('id', user.id).single();
      if (!adminRow) return fail('FORBIDDEN', 'Unauthorized', 403);

      const { data: order } = await admin.from('service_orders')
        .select('*, order_items(id, sparepart_id)')
        .eq('id', order_id)
        .eq('store_id', adminRow.store_id)
        .single();

      if (!order) return fail('ORDER_NOT_FOUND', 'Pesanan tidak ditemukan', 404);
      assertValidTransition(order.status, 'waiting_approval');

      // Calculate final price
      const finalPrice = items.reduce((sum: number, i: any) => sum + i.final_item_price, 0) + (service_fee || 0);

      // Update items
      for (const item of items) {
        // Swap sparepart if replaced
        const oldItem = order.order_items.find((oi: any) => oi.id === item.order_item_id);
        if (oldItem?.sparepart_id && item.replaced_sparepart_id) {
          await admin.rpc('swap_sparepart', { p_old_id: oldItem.sparepart_id, p_new_id: item.replaced_sparepart_id });
        }

        await admin.from('order_items').update({
          status: item.status,
          final_item_price: item.final_item_price,
          technician_note: item.technician_note || null,
        }).eq('id', item.order_item_id);
      }

      await admin.from('service_orders').update({
        status: 'waiting_approval',
        final_price: finalPrice,
        service_fee: service_fee || 0,
        diagnosis_note: diagnosis_note || null,
        sla_deadline: null,
      }).eq('id', order.id);

      await admin.from('service_tracking').insert({
        order_id: order.id,
        status: 'waiting_approval',
        note: 'Diagnosa dikirim, menunggu persetujuan pelanggan',
        created_by_type: 'store_admin',
        created_by_id: user.id,
      });

      return ok({ final_price: finalPrice });
    }

    // ─── STATUS UPDATE (Store Admin) ───
    if (path === 'status' && req.method === 'POST') {
      if (role !== 'store_admin') return fail('FORBIDDEN', 'Unauthorized', 403);

      const { order_id, status, note } = body;

      const { data: adminRow } = await admin.from('store_admins').select('store_id').eq('id', user.id).single();
      if (!adminRow) return fail('FORBIDDEN', 'Unauthorized', 403);

      const { data: order } = await admin.from('service_orders')
        .select('*, order_items(id, sparepart_id)')
        .eq('id', order_id)
        .eq('store_id', adminRow.store_id)
        .single();

      if (!order) return fail('ORDER_NOT_FOUND', 'Pesanan tidak ditemukan', 404);
      assertValidTransition(order.status, status);

      // If moving to repairing from waiting_sparepart, consume stock
      if (order.status === 'waiting_sparepart' && status === 'repairing') {
        for (const item of order.order_items) {
          if (item.sparepart_id) {
            await admin.rpc('consume_stock', { p_sparepart_id: item.sparepart_id });
          }
        }
      }

      const update: Record<string, any> = { status };
      if (status === 'completed') update.completed_at = new Date().toISOString();
      if (status === 'cancelled') update.cancelled_at = new Date().toISOString();
      if (status === 'waiting_payment') update.sla_deadline = null;

      await admin.from('service_orders').update(update).eq('id', order.id);
      await admin.from('service_tracking').insert({
        order_id: order.id,
        status,
        note: note || null,
        created_by_type: 'store_admin',
        created_by_id: user.id,
      });

      // If completed, update store stats
      if (status === 'completed') {
        await admin.rpc('update_rating_avg', { p_store_id: adminRow.store_id });
      }

      return ok({ status });
    }

    return fail('NOT_FOUND', 'Endpoint not found', 404);
  } catch (err: any) {
    return fail(err.code || 'INTERNAL', err.message, 500);
  }
});
