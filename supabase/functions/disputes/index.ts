import { withSupabase } from 'npm:@supabase/server'
import { ok, fail } from '../_shared/helpers.ts'

export default {
  fetch: withSupabase({ auth: 'user' }, async (req: Request, ctx) => {
    if (req.method !== 'POST') return fail('METHOD_NOT_ALLOWED', 'POST only', 405);

    try {
      const { userClaims, supabaseAdmin: admin } = ctx;
      if (!userClaims) return fail('UNAUTHORIZED', 'Unauthorized', 401);

      const { dispute_id, decision, store_response } = await req.json();

      const { data: adminRow } = await admin.from('store_admins').select('store_id').eq('id', userClaims.id).single();
      if (!adminRow) return fail('FORBIDDEN', 'Unauthorized', 403);

      const { data: dispute } = await admin.from('disputes').select('*').eq('id', dispute_id).eq('store_id', adminRow.store_id).single();
      if (!dispute) return fail('NOT_FOUND', 'Dispute tidak ditemukan', 404);
      if (dispute.status !== 'open') return fail('INVALID_STATE', 'Dispute sudah diproses');

      const newStatus = decision === 'store_accepted' ? 'store_accepted' : 'store_rejected';

      if (decision === 'store_accepted') {
        const { data: parentOrder } = await admin.from('service_orders').select('*, order_items(*)').eq('id', dispute.order_id).single();
        const orderNumber = `SG-${new Date().toISOString().slice(0, 10).replace(/-/g, '')}-W${Math.random().toString(36).slice(2, 7).toUpperCase()}`;

        const { data: warrantyOrder } = await admin.from('service_orders').insert({
          user_id: dispute.user_id, store_id: dispute.store_id, order_number: orderNumber,
          device_type: parentOrder.device_type, brand: parentOrder.brand, device_model: parentOrder.device_model,
          delivery_method: parentOrder.delivery_method, delivery_address: parentOrder.delivery_address,
          status: 'waiting_device', total_estimasi: 0, is_warranty_order: true, parent_order_id: dispute.order_id,
        }).select().single();

        await admin.from('disputes').update({ status: newStatus, store_response, warranty_order_id: warrantyOrder.id, resolved_at: new Date().toISOString() }).eq('id', dispute_id);
        await admin.from('service_tracking').insert({ order_id: dispute.order_id, status: 'disputed', note: `Klaim diterima. Order garansi: ${orderNumber}`, created_by_type: 'store_admin', created_by_id: userClaims.id });

        for (const item of parentOrder.order_items) {
          if (!item.sparepart_id) continue;

          const { data: sparepart } = await admin.from('spareparts').select('qty, qty_reserved').eq('id', item.sparepart_id).single();
          if (!sparepart) continue;

          if (sparepart.qty - sparepart.qty_reserved <= 0) {
            throw new Error('STOCK_UNAVAILABLE: Insufficient stock to reserve');
          }

          const newQtyReserved = sparepart.qty_reserved + 1;
          await admin.from('spareparts').update({ qty_reserved: newQtyReserved }).eq('id', item.sparepart_id);

          await admin.from('order_items').insert({
            order_id: warrantyOrder.id,
            sparepart_id: item.sparepart_id,
            service_type: item.service_type,
            complaint: item.complaint,
            item_price: item.item_price || 0,
            status: 'pending',
          });
        }

        await admin.from('service_orders').update({ status: 'completed', completed_at: new Date().toISOString() }).eq('id', dispute.order_id);

        await admin.from('notifications').insert({
          user_id: dispute.user_id,
          store_id: dispute.store_id,
          role: 'customer',
          title: 'Klaim Dispute Diterima - Order Garansi Dibuat',
          message: `Klaim Anda telah diterima. Order garansi ${orderNumber} telah dibuat untuk memproses barang Anda.`,
          type: 'dispute',
          is_read: false,
          link_to: `/orders/${warrantyOrder.id}`,
        });

        try {
          const waRes = await fetch('https://api.whatsapp.com/send', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
              to: parentOrder.phone_number || dispute.user_id,
              message: `Klaim garansi berhasil diterima! Order baru ${orderNumber} telah dibuat untuk memproses perbaikan perangkat Anda. Tim kami akan segera menghubungi Anda.`, 
            }),
          });
          await waRes.json();
        } catch (waErr) {
          console.error('WhatsApp notification failed:', waErr);
        }
      } else {
        await admin.from('disputes').update({ status: newStatus, store_response, resolved_at: new Date().toISOString() }).eq('id', dispute_id);
        await admin.from('service_tracking').insert({ order_id: dispute.order_id, status: 'completed', note: `Klaim ditolak: ${store_response || '-'}`, created_by_type: 'store_admin', created_by_id: userClaims.id });
      }

      return ok({ status: newStatus });
    } catch (err: any) {
      return fail(err.code || 'INTERNAL', err.message, 500);
    }
  }),
}
