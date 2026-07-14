import { withSupabase } from 'npm:@supabase/server'
import { ok, fail, requireUser } from '../_shared/helpers.ts'
import { corsHeaders } from '../_shared/cors.ts'
import { sendNotificationEmail, isEmailConfigured } from '../_shared/email.ts'
import { generateOrderNumber } from '../_shared/crypto.ts'

export default {
  fetch: withSupabase({ auth: 'none' }, async (req: Request, ctx) => {
    if (req.method === 'OPTIONS') return new Response('ok', { headers: { ...corsHeaders } });
    if (req.method !== 'POST') return fail('METHOD_NOT_ALLOWED', 'POST only', 405);

    try {
      const { supabaseAdmin: admin } = ctx; const userClaims = await requireUser(req, admin);

      const body = await req.json();
      const now = new Date().toISOString();

      const action = body.action as string | undefined;

      if (action === 'create') {
        const { order_id, dispute_type, description, evidence_urls } = body;
        if (!order_id || !dispute_type || !description) return fail('INVALID_INPUT', 'order_id, dispute_type, description wajib');

        const { data: order } = await admin.from('service_orders').select('id, user_id, store_id').eq('id', order_id).single();
        if (!order) return fail('ORDER_NOT_FOUND', 'Order not found', 404);
        if (order.user_id !== userClaims.id) return fail('FORBIDDEN', 'Bukan order Anda', 403);

        const { data: existing } = await admin.from('disputes').select('id').eq('order_id', order_id).maybeSingle();
        if (existing) return fail('DUPLICATE', 'Dispute sudah ada untuk order ini');

        const { data: dispute, error: dErr } = await admin.from('disputes').insert({
          order_id, user_id: userClaims.id, store_id: order.store_id,
          dispute_type, description,
          evidence_urls: evidence_urls || [], status: 'open',
        }).select().single();
        if (dErr) return fail('DB_ERROR', dErr.message);

        await admin.from('service_orders').update({ status: 'disputed', updated_at: now }).eq('id', order_id);
        await admin.from('service_tracking').insert({
          order_id, status: 'disputed', note: `Klaim: ${description.substring(0, 100)}`,
          created_by_type: 'customer', created_by_id: userClaims.id,
        });
        return ok(dispute);
      }

      const { dispute_id, decision, store_response } = body;
      const { data: adminRow } = await admin.from('store_admins').select('store_id').eq('id', userClaims.id).single();
      if (!adminRow) return fail('FORBIDDEN', 'Unauthorized', 403);

      const { data: dispute } = await admin.from('disputes').select('*').eq('id', dispute_id).eq('store_id', adminRow.store_id).single();
      if (!dispute) return fail('NOT_FOUND', 'Dispute tidak ditemukan', 404);
      if (dispute.status !== 'open') return fail('INVALID_STATE', 'Dispute sudah diproses');

      const newStatus = decision === 'store_accepted' ? 'store_accepted' : 'store_rejected';

      if (decision === 'store_accepted') {
        const { data: parentOrder } = await admin.from('service_orders').select('*, order_items(*)').eq('id', dispute.order_id).single();
        const orderNumber = generateOrderNumber() + '-W';

        const { data: warrantyOrder } = await admin.from('service_orders').insert({
          user_id: dispute.user_id, store_id: dispute.store_id, order_number: orderNumber,
          device_type: parentOrder.device_type, brand: parentOrder.brand, device_model: parentOrder.device_model,
          delivery_method: parentOrder.delivery_method, delivery_address: parentOrder.delivery_address,
          status: 'waiting_device', total_estimasi: 0, is_warranty_order: true, parent_order_id: dispute.order_id, updated_at: now,
        }).select().single();

        await admin.from('disputes').update({ status: newStatus, store_response, warranty_order_id: warrantyOrder.id, resolved_at: new Date().toISOString() }).eq('id', dispute_id);
        await admin.from('service_tracking').insert({ order_id: dispute.order_id, status: 'disputed', note: `Klaim diterima. Order garansi: ${orderNumber}`, created_by_type: 'store_admin', created_by_id: userClaims.id });

        for (const item of parentOrder.order_items) {

          const { data: reserved } = await admin.rpc('reserve_stock', { p_sparepart_id: item.sparepart_id, p_qty: 1 });
          if (!reserved) {
            throw new Error('STOCK_UNAVAILABLE: Insufficient stock to reserve');
          }

          await admin.from('order_items').insert({
            order_id: warrantyOrder.id,
            sparepart_id: item.sparepart_id,
            service_type: item.service_type,
            complaint: item.complaint,
            item_price: item.item_price || 0,
            status: 'pending',
          });
        }

        await admin.from('service_orders').update({ status: 'completed', completed_at: new Date().toISOString(), updated_at: now }).eq('id', dispute.order_id);

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

        // Email notification for dispute resolution
        if (isEmailConfigured()) {
          const { data: authUser } = await admin.auth.admin.getUserById(dispute.user_id).catch(() => ({ data: null }));
          const userEmail = authUser?.user?.email;
          if (userEmail) {
            await sendNotificationEmail(userEmail, 'Klaim Dispute Diterima — Service Me',
              'Klaim Diterima', `Klaim garansi Anda diterima. Order baru ${orderNumber} telah dibuat untuk memproses perbaikan.`);
          }
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
