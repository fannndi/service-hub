import { withSupabase } from 'npm:@supabase/server'
import { ok, fail } from '../_shared/helpers.ts'

const SNAP_URL = 'https://app.sandbox.midtrans.com/snap/v1/transactions';

async function createSnapToken(orderId: string, userId: string, admin: any) {
  const { data: order } = await admin
    .from('service_orders')
    .select('*, users(full_name, phone_number)')
    .eq('id', orderId)
    .eq('user_id', userId)
    .single();
  if (!order) return fail('ORDER_NOT_FOUND', 'Order not found');

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
    expiry: {
      start_time: new Date().toISOString().replace(/T/, ' ').substring(0, 19) + ' +0700',
      unit: 'hour', duration: 24,
    },
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

  const orderNumber = orderId.replace(/^ORDER-/, '').replace(/-\d+$/, '');
  const { data: order } = await admin.from('service_orders').select('id, user_id').eq('order_number', orderNumber).single();
  if (!order) return fail('ORDER_NOT_FOUND', 'Order ' + orderNumber + ' not found');

  let recordStatus: string, paymentStatus: string;
  if (transactionStatus === 'capture') {
    recordStatus = fraudStatus === 'accept' ? 'confirmed' : 'failed';
    paymentStatus = fraudStatus === 'accept' ? 'paid' : 'unpaid';
  } else if (transactionStatus === 'settlement') { recordStatus = 'confirmed'; paymentStatus = 'paid'; }
  else if (['deny', 'cancel', 'expire'].includes(transactionStatus)) { recordStatus = 'failed'; paymentStatus = 'unpaid'; }
  else if (transactionStatus === 'refund' || transactionStatus === 'partial_refund') { recordStatus = 'refunded'; paymentStatus = 'refunded'; }
  else { recordStatus = 'pending'; paymentStatus = 'unpaid'; }

  const now = new Date().toISOString();

  if (recordStatus === 'confirmed') {
    const { error: e1 } = await admin.from('payments').insert({
      order_id: order.id, user_id: order.user_id, amount: Number(grossAmount),
      payment_method: 'midtrans_other', payment_type: 'final_payment',
      status: 'confirmed', confirmed_at: now,
      midtrans_order_id: orderId, midtrans_transaction_id: body.transaction_id,
      midtrans_payment_type: paymentType,
    });
    if (e1) return fail('DB_ERROR', e1.message);

    const { error: e2 } = await admin.from('service_orders').update({ status: 'completed', payment_status: 'paid', completed_at: now }).eq('id', order.id);
    if (e2) return fail('DB_ERROR', e2.message);
    const { error: e3 } = await admin.from('service_tracking').insert({
      order_id: order.id, status: 'completed', created_by_type: 'system', created_by_id: 'midtrans',
      note: 'Pembayaran via Midtrans (' + paymentType + ')',
    });
    if (e3) return fail('DB_ERROR', e3.message);
  } else {
    await admin.from('payments').insert({
      order_id: order.id, user_id: order.user_id, amount: Number(grossAmount),
      payment_method: 'midtrans_other', payment_type: 'final_payment',
      status: recordStatus, midtrans_order_id: orderId,
      midtrans_transaction_id: body.transaction_id, midtrans_payment_type: paymentType,
    });
  }
  return ok({ status: recordStatus, payment_status: paymentStatus });
}

export default {
  fetch: withSupabase({ auth: false }, async (req: Request) => {
    const url = new URL(req.url);
    const action = url.pathname.split('/').pop();

    if (action === 'snap-token') {
      const { orderId, userId } = await req.json() as { orderId: string; userId: string };
      const ctx = await withSupabase({ auth: true }).fetch(req, new Map());
      if (!ctx?.supabaseAdmin) return fail('UNAUTHORIZED', 'Unauthorized', 401);
      return createSnapToken(orderId, userId, ctx.supabaseAdmin);
    }

    if (action === 'notification') {
      const body = await req.json();
      const ctx = await withSupabase({ auth: false }).fetch(req, new Map());
      return processNotification(body, ctx?.supabaseAdmin);
    }

    return fail('NOT_FOUND', 'Unknown action: use snap-token or notification');
  }),
};
