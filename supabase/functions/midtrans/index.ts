import { withSupabase } from 'npm:@supabase/server'
import { ok, fail, assertValidTransition } from '../_shared/helpers.ts'

const SNAP_URL = Deno.env.get('MIDTRANS_SNAP_URL') || 'https://app.sandbox.midtrans.com/snap/v1/transactions';

async function verifyAuth(req: Request, admin: any) {
  const auth = req.headers.get('Authorization');
  if (!auth?.startsWith('Bearer ')) return null;
  const { data: { user }, error } = await admin.auth.getUser(auth.slice(7));
  return error || !user ? null : user;
}

async function createSnapToken(orderId: string, userId: string, admin: any) {
  const { data: order } = await admin
    .from('service_orders')
    .select('*, users(full_name, phone_number)')
    .eq('id', orderId)
    .eq('user_id', userId)
    .single();
  if (!order) return fail('ORDER_NOT_FOUND', 'Order not found');
  if (order.status !== 'waiting_payment') return fail('INVALID_STATUS', 'Order must be in waiting_payment status');

  const grossAmount = Number(order.final_price ?? order.total_estimasi);
  const user = order.users as Record<string, string>;
  const serverKey = Deno.env.get('MIDTRANS_SERVER_KEY')!;
  const body = {
    transaction_details: {
      order_id: 'ORDER-' + order.order_number + '-' + Date.now(),
      gross_amount: grossAmount,
    },
    credit_card: { secure: true },
    customer_details: { first_name: user.full_name, phone: user.phone_number },
    expiry: { start_time: new Date().toISOString().replace(/T/, ' ').substring(0, 19) + ' +0700', unit: 'hour', duration: 24 },
  };

  const auth = btoa(serverKey + ':');
  const res = await fetch(SNAP_URL, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'Accept': 'application/json', 'Authorization': 'Basic ' + auth },
    body: JSON.stringify(body),
  });
  const data = await res.json();
  if (!res.ok) return fail('MIDTRANS_ERROR', data.error_message || res.statusText);
  return ok({ token: data.token, redirect_url: data.redirect_url });
}

async function processNotification(body: Record<string, unknown>, admin: any) {
  const orderId = body.order_id as string;
  const statusCode = body.status_code as string;
  const grossAmount = body.gross_amount as string;
  const serverKey = Deno.env.get('MIDTRANS_SERVER_KEY')!;
  const signature = body.signature_key as string;

  const msgData = new TextEncoder().encode(orderId + statusCode + grossAmount + serverKey);
  const key = await crypto.subtle.importKey('raw', new TextEncoder().encode(serverKey), { name: 'HMAC', hash: 'SHA-512' }, false, ['sign']);
  const sig = await crypto.subtle.sign('HMAC', key, msgData);
  const hex = Array.from(new Uint8Array(sig)).map((b) => b.toString(16).padStart(2, '0')).join('');
  if (hex !== signature) return fail('INVALID_SIGNATURE', 'Invalid signature');

  const transactionStatus = body.transaction_status as string;
  const fraudStatus = body.fraud_status as string;
  const paymentType = body.payment_type as string;
  const transactionId = body.transaction_id as string;
  const orderNumber = orderId.replace(/^ORDER-/, '').replace(/-\d+$/, '');

  const { data: order } = await admin.from('service_orders').select('id, user_id, store_id, order_number, status').eq('order_number', orderNumber).single();
  if (!order) return fail('ORDER_NOT_FOUND', 'Order ' + orderNumber + ' not found');

  const { data: existing } = await admin.from('payments').select('id').eq('midtrans_transaction_id', transactionId).maybeSingle();
  if (existing) return ok({ status: 'skipped', reason: 'duplicate notification' });

  let recordStatus: string, paymentStatus: string;
  if (transactionStatus === 'capture') {
    recordStatus = fraudStatus === 'accept' ? 'confirmed' : 'failed';
    paymentStatus = fraudStatus === 'accept' ? 'paid' : 'unpaid';
  } else if (transactionStatus === 'settlement') { recordStatus = 'confirmed'; paymentStatus = 'paid'; }
  else if (['deny', 'cancel', 'expire'].includes(transactionStatus)) { recordStatus = 'failed'; paymentStatus = 'unpaid'; }
  else if (['refund', 'partial_refund'].includes(transactionStatus)) { recordStatus = 'refunded'; paymentStatus = 'refunded'; }
  else { recordStatus = 'pending'; paymentStatus = 'unpaid'; }

  const now = new Date().toISOString();

  const { error: e1 } = await admin.from('payments').insert({
    order_id: order.id, user_id: order.user_id, amount: Number(grossAmount),
    payment_method: 'midtrans', payment_type: 'final_payment',
    status: recordStatus, confirmed_at: recordStatus === 'confirmed' ? now : null,
    midtrans_order_id: orderId, midtrans_transaction_id: transactionId,
    midtrans_payment_type: paymentType,
  });
  if (e1) return fail('DB_ERROR', e1.message);

  if (recordStatus === 'confirmed') {
    assertValidTransition(order.status, 'completed');
    const { error: e2 } = await admin.from('service_orders').update({ status: 'completed', payment_status: 'paid', completed_at: now, updated_at: now }).eq('id', order.id);
    if (e2) return fail('DB_ERROR', e2.message);
    const { error: e3 } = await admin.from('service_tracking').insert({
      order_id: order.id, status: 'completed', created_by_type: 'system', created_by_id: 'midtrans',
      note: 'Pembayaran via Midtrans (' + paymentType + ')',
    });
    if (e3) return fail('DB_ERROR', e3.message);

    const { data: store } = await admin.from('stores').select('config').eq('id', order.store_id).single();
    const warrantyDays = (store?.config as Record<string, any>)?.['warranty_days'] ?? 30;
    const warrantyExpiredAt = new Date(Date.now() + warrantyDays * 24 * 60 * 60 * 1000).toISOString();
    await admin.from('service_orders').update({
      warranty_days: warrantyDays, warranty_expired_at: warrantyExpiredAt,
    }).eq('id', order.id);

    await admin.from('notifications').insert([
      { user_id: order.user_id, store_id: order.store_id, role: 'customer', title: 'Pembayaran Berhasil', message: `Pembayaran via Midtrans untuk #${order.order_number} berhasil. Garansi ${warrantyDays} hari.`, type: 'payment', is_read: false, link_to: `/orders/${order.id}` },
      { user_id: null, store_id: order.store_id, role: 'store_admin', title: 'Pembayaran Midtrans', message: `Pesanan #${order.order_number} lunas via Midtrans.`, type: 'payment', is_read: false, link_to: `/admin/orders/${order.id}` },
    ]);
  }

  return ok({ status: recordStatus, payment_status: paymentStatus });
}

export default {
  fetch: withSupabase({ auth: 'none' }, async (req: Request, ctx: any) => {
    try {
      const url = new URL(req.url);
      const action = url.pathname.split('/').pop();
      const admin = ctx?.supabaseAdmin;

      if (action === 'snap-token') {
        const user = await verifyAuth(req, admin);
        if (!user) return fail('UNAUTHORIZED', 'Unauthorized', 401);
        const { orderId, userId } = await req.json() as { orderId: string; userId: string };
        if (user.id !== userId) return fail('FORBIDDEN', 'User ID mismatch', 403);
        return createSnapToken(orderId, userId, admin);
      }

      if (action === 'notification') {
        const body = await req.json();
        return processNotification(body, admin);
      }

      return fail('NOT_FOUND', 'Unknown action: use snap-token or notification');
    } catch (err: any) {
      return fail(err.code || 'INTERNAL', err.message, 500);
    }
  }),
};
