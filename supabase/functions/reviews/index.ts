import { withSupabase } from 'npm:@supabase/server'
import { ok, fail } from '../_shared/helpers.ts'
import { corsHeaders } from '../_shared/cors.ts'
import { generateCouponCode } from '../_shared/crypto.ts'

export default {
  fetch: withSupabase({ auth: 'user' }, async (req: Request, ctx: any) => {
    if (req.method === 'OPTIONS') return new Response('ok', { headers: { ...corsHeaders } });
    if (req.method !== 'POST') return fail('METHOD_NOT_ALLOWED', 'POST only', 405);

    try {
      if (!ctx?.userClaims) return fail('UNAUTHORIZED', 'Unauthorized', 401);
      const admin = ctx.supabaseAdmin;
      const userId = ctx.userClaims.id;
      const body = await req.json();
      const url = new URL(req.url);
      const action = url.pathname.split('/').pop();

      if (action === 'create') {
        const { orderId, rating, comment } = body;
        if (!orderId || !rating) return fail('INVALID_INPUT', 'orderId dan rating wajib');

        const { data: order } = await admin.from('service_orders').select('id, store_id, status, user_id').eq('id', orderId).single();
        if (!order) return fail('ORDER_NOT_FOUND', 'Order not found');
        if (order.user_id !== userId) return fail('FORBIDDEN', 'Bukan order Anda', 403);
        if (order.status !== 'completed') return fail('INVALID_STATUS', 'Order belum selesai');

        const { data: existing } = await admin.from('reviews').select('id').eq('order_id', orderId).maybeSingle();
        if (existing) return fail('DUPLICATE', 'Anda sudah mereview order ini');

        const { data: review, error: rErr } = await admin.from('reviews').insert({
          order_id: orderId, user_id: userId, store_id: order.store_id,
          rating, comment: comment || null, is_public: true,
        }).select().single();
        if (rErr) return fail('DB_ERROR', rErr.message);

        const { error: uErr } = await admin.rpc('update_rating_avg', { p_store_id: order.store_id });
        if (uErr) console.error('update_rating_avg error:', uErr.message);

        const code = generateCouponCode();
        const expiredAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString();
        const { error: cErr } = await admin.from('coupons').insert({
          user_id: userId, review_id: review.id, code,
          amount: 10000, expired_at: expiredAt,
        });
        if (cErr) {
          // H17: Rollback review if coupon insert fails
          await admin.from('reviews').delete().eq('id', review.id);
          return fail('COUPON_FAILED', 'Gagal membuat kupon reward');
        }

        return ok({ review, coupon: { code, amount: 10000, expired_at: expiredAt } });
      }

      if (action === 'store-list') {
        const { storeId } = body;
        if (!storeId) return fail('INVALID_INPUT', 'storeId wajib');
        const { data: reviews } = await admin.from('reviews').select('*, user:users(full_name)').eq('store_id', storeId).order('created_at', { ascending: false }).limit(20);
        return ok(reviews || []);
      }

      return fail('NOT_FOUND', 'Unknown action: use create or store-list');
    } catch (err: any) {
      return fail(err.code || 'INTERNAL', err.message, 500);
    }
  }),
};
