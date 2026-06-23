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

    const body = await req.json();
    const { dispute_id, decision, store_response } = body;

    // Get store admin's store
    const { data: adminRow } = await admin.from('store_admins').select('store_id').eq('id', user.id).single();
    if (!adminRow) return fail('FORBIDDEN', 'Unauthorized', 403);

    // Get dispute
    const { data: dispute } = await admin.from('disputes')
      .select('*')
      .eq('id', dispute_id)
      .eq('store_id', adminRow.store_id)
      .single();

    if (!dispute) return fail('NOT_FOUND', 'Dispute tidak ditemukan', 404);
    if (dispute.status !== 'open') return fail('INVALID_STATE', 'Dispute sudah diproses');

    const newStatus = decision === 'store_accepted' ? 'store_accepted' : 'store_rejected';

    if (decision === 'store_accepted') {
      // Create warranty order
      const { data: parentOrder } = await admin.from('service_orders')
        .select('*, order_items(*)')
        .eq('id', dispute.order_id)
        .single();

      const orderNumber = `SG-${new Date().toISOString().slice(0, 10).replace(/-/g, '')}-W${Math.random().toString(36).slice(2, 7).toUpperCase()}`;

      const { data: warrantyOrder } = await admin.from('service_orders').insert({
        user_id: dispute.user_id,
        store_id: dispute.store_id,
        order_number: orderNumber,
        device_type: parentOrder.device_type,
        brand: parentOrder.brand,
        device_model: parentOrder.device_model,
        delivery_method: parentOrder.delivery_method,
        delivery_address: parentOrder.delivery_address,
        status: 'waiting_device',
        total_estimasi: 0,
        is_warranty_order: true,
        parent_order_id: dispute.order_id,
      }).select().single();

      await admin.from('disputes').update({
        status: newStatus,
        store_response,
        warranty_order_id: warrantyOrder.id,
        resolved_at: new Date().toISOString(),
      }).eq('id', dispute_id);

      await admin.from('service_tracking').insert({
        order_id: dispute.order_id,
        status: 'disputed',
        note: `Klaim diterima. Order garansi: ${orderNumber}`,
        created_by_type: 'store_admin',
        created_by_id: user.id,
      });
    } else {
      await admin.from('disputes').update({
        status: newStatus,
        store_response,
        resolved_at: new Date().toISOString(),
      }).eq('id', dispute_id);

      await admin.from('service_tracking').insert({
        order_id: dispute.order_id,
        status: 'completed',
        note: `Klaim ditolak: ${store_response || '-'}`,
        created_by_type: 'store_admin',
        created_by_id: user.id,
      });
    }

    return ok({ status: newStatus });
  } catch (err: any) {
    return fail(err.code || 'INTERNAL', err.message, 500);
  }
});
