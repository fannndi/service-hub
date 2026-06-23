import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { corsHeaders } from '../_shared/cors.ts';
import { ok, fail } from '../_shared/helpers.ts';

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') return new Response(null, { headers: corsHeaders });

  try {
    const sb = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_ANON_KEY')!,
      { global: { headers: { Authorization: req.headers.get('Authorization')! } } }
    );
    const admin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    );

    const { data: { user } } = await sb.auth.getUser();
    if (!user) return fail('UNAUTHORIZED', 'Unauthorized', 401);

    const url = new URL(req.url);
    const path = url.pathname.split('/').pop();
    const body = await req.json();

    // ─── CONFIRM PAYMENT (Store Admin) ───
    if (path === 'confirm') {
      const { order_id, payment_id, note } = body;

      const { data: adminRow } = await admin.from('store_admins').select('store_id').eq('id', user.id).single();
      if (!adminRow) return fail('FORBIDDEN', 'Unauthorized', 403);

      const { data: payment } = await admin.from('payments')
        .select('id, order_id')
        .eq('id', payment_id)
        .eq('order_id', order_id)
        .single();

      if (!payment) return fail('NOT_FOUND', 'Pembayaran tidak ditemukan', 404);

      // Verify order belongs to store
      const { data: order } = await admin.from('service_orders')
        .select('id, status')
        .eq('id', order_id)
        .eq('store_id', adminRow.store_id)
        .single();

      if (!order) return fail('NOT_FOUND', 'Pesanan tidak ditemukan', 404);

      await admin.from('payments').update({
        status: 'confirmed',
        confirmed_by: user.id,
        confirmed_at: new Date().toISOString(),
      }).eq('id', payment_id);

      // Update order payment status
      const { count: totalPayments } = await admin.from('payments').select('*', { count: 'exact', head: true }).eq('order_id', order_id);
      const { count: confirmedPayments } = await admin.from('payments').select('*', { count: 'exact', head: true }).eq('order_id', order_id).eq('status', 'confirmed');

      if (confirmedPayments === totalPayments) {
        await admin.from('service_orders').update({ payment_status: 'paid' }).eq('id', order_id);
      } else {
        await admin.from('service_orders').update({ payment_status: 'partially_paid' }).eq('id', order_id);
      }

      await admin.from('service_tracking').insert({
        order_id,
        status: order.status,
        note: note || 'Pembayaran dikonfirmasi',
        created_by_type: 'store_admin',
        created_by_id: user.id,
      });

      return ok({ status: 'confirmed' });
    }

    return fail('NOT_FOUND', 'Endpoint not found', 404);
  } catch (err: any) {
    return fail(err.code || 'INTERNAL', err.message, 500);
  }
});
