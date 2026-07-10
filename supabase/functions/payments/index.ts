import { withSupabase } from 'npm:@supabase/server'
import { ok, fail } from '../_shared/helpers.ts'
import { corsHeaders } from '../_shared/cors.ts'
import { sendNotificationEmail, isEmailConfigured } from '../_shared/email.ts'

export default {
  fetch: withSupabase({ auth: 'user' }, async (req: Request, ctx) => {
    if (req.method === 'OPTIONS') return new Response('ok', { headers: { ...corsHeaders } });
    if (req.method !== 'POST') return fail('METHOD_NOT_ALLOWED', 'POST only', 405);

    try {
      const { userClaims, supabaseAdmin: admin } = ctx;
      if (!userClaims) return fail('UNAUTHORIZED', 'Unauthorized', 401);

      const body = await req.json();
      const now = new Date().toISOString();
      const action = body.action as string | undefined;

      if (action === 'create') {
        const { order_id, amount, payment_method, payment_type, proof_url } = body;
        if (!order_id || !amount) return fail('INVALID_INPUT', 'order_id dan amount wajib');

        const { data: order } = await admin.from('service_orders').select('id, status, user_id').eq('id', order_id).single();
        if (!order) return fail('ORDER_NOT_FOUND', 'Order not found', 404);
        if (order.user_id !== userClaims.id) return fail('FORBIDDEN', 'Bukan order Anda', 403);

        const { data: payment, error: pErr } = await admin.from('payments').insert({
          order_id, user_id: userClaims.id, amount,
          payment_method: payment_method || 'transfer_bank',
          payment_type: payment_type || 'final_payment',
          proof_url: proof_url || null, status: 'pending',
        }).select().single();
        if (pErr) return fail('DB_ERROR', pErr.message);
        return ok(payment);
      }

      if (action === 'confirm') {
        const { order_id, payment_id, note } = body;

        const { data: adminRow } = await admin.from('store_admins').select('store_id').eq('id', userClaims.id).single();
        if (!adminRow) return fail('FORBIDDEN', 'Unauthorized', 403);

        const { data: payment } = await admin.from('payments').select('id, order_id, status').eq('id', payment_id).eq('order_id', order_id).single();
        if (!payment) return fail('NOT_FOUND', 'Pembayaran tidak ditemukan', 404);
        // H4: Prevent double confirmation
        if (payment.status !== 'pending') return fail('ALREADY_CONFIRMED', 'Pembayaran sudah dikonfirmasi');

        const { data: order } = await admin.from('service_orders').select('id, status, user_id, store_id, order_number').eq('id', order_id).eq('store_id', adminRow.store_id).single();
        if (!order) return fail('NOT_FOUND', 'Pesanan tidak ditemukan', 404);

        await admin.from('payments').update({ status: 'confirmed', confirmed_by: userClaims.id, confirmed_at: new Date().toISOString() }).eq('id', payment_id);

        const { count: totalPayments } = await admin.from('payments').select('*', { count: 'exact', head: true }).eq('order_id', order_id);
        const { count: confirmedPayments } = await admin.from('payments').select('*', { count: 'exact', head: true }).eq('order_id', order_id).eq('status', 'confirmed');

        await admin.from('service_orders').update({ payment_status: confirmedPayments === totalPayments ? 'paid' : 'partially_paid', updated_at: now }).eq('id', order_id);
        // H5: Set order to completed after payment confirmation
        await admin.from('service_orders').update({
          status: 'completed', payment_status: 'paid', completed_at: new Date().toISOString(), updated_at: now,
        }).eq('id', order_id);
        await admin.from('service_tracking').insert({ order_id, status: 'completed', note: 'Pembayaran dikonfirmasi, order selesai', created_by_type: 'store_admin', created_by_id: userClaims.id });

        const { data: store } = await admin.from('stores').select('config').eq('id', adminRow.store_id).single();
        const warrantyDays = store?.config?.warranty_days || 30;
        const warrantyExpiredAt = new Date(Date.now() + warrantyDays * 24 * 60 * 60 * 1000).toISOString();

        await admin.from('service_orders').update({
          warranty_days: warrantyDays,
          warranty_expired_at: warrantyExpiredAt,
          completed_at: new Date().toISOString(),
          updated_at: now,
        }).eq('id', order_id);

        // Intentional: separate notification for each role (customer + store_admin)
        await admin.from('notifications').insert([{ user_id: order.user_id, store_id: order.store_id, role: 'customer', title: 'Pembayaran Berhasil', message: `Pembayaran untuk pesanan #${order.order_number} telah dikonfirmasi. Garansi berlaku selama ${warrantyDays} hari hingga ${warrantyExpiredAt}.`, type: 'payment', is_read: false, link_to: `/orders/${order_id}` }]);

        await admin.from('notifications').insert([{ user_id: null, store_id: order.store_id, role: 'store_admin', title: 'Pembayaran Berhasil', message: `Pembayaran untuk pesanan #${order.order_number} telah dikonfirmasi. Garansi berlaku selama ${warrantyDays} hari.`, type: 'payment', is_read: false, link_to: `/admin/orders/${order_id}` }]);

        // Email fallback for critical notification
        if (isEmailConfigured()) {
          const { data: user } = await admin.from('users').select('*').eq('id', order.user_id).single();
          if (user) {
            const { data: authUser } = await admin.auth.admin.getUserById(order.user_id).catch(() => ({ data: null }));
            const userEmail = authUser?.user?.email;
            if (userEmail) {
              await sendNotificationEmail(userEmail, 'Pembayaran Berhasil — Service Me', 'Pembayaran Berhasil', `Pembayaran untuk order #${order.order_number} sudah dikonfirmasi. Garansi ${warrantyDays} hari.`);
            }
          }
        }

        return ok({ status: 'confirmed', warranty_days: warrantyDays, warranty_expired_at: warrantyExpiredAt });
      }

      return fail('NOT_FOUND', 'Endpoint not found', 404);
    } catch (err: any) {
      return fail(err.code || 'INTERNAL', err.message, 500);
    }
  }),
}