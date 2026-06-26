import { withSupabase } from 'npm:@supabase/server'
import { ok, fail } from '../_shared/helpers.ts'
import { corsHeaders } from '../_shared/cors.ts'

const PASSWORD_CHARS = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789';
const ORDER_NO_CHARS = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';

function randomString(len: number): string {
  const arr = new Uint8Array(len);
  crypto.getRandomValues(arr);
  let result = '';
  for (let i = 0; i < len; i++) result += PASSWORD_CHARS[arr[i] % PASSWORD_CHARS.length];
  return result;
}

function generateOrderNumber(): string {
  const date = new Date().toISOString().slice(0, 10).replace(/-/g, '');
  const rand = Array.from({ length: 6 }, () => ORDER_NO_CHARS[Math.floor(Math.random() * ORDER_NO_CHARS.length)]).join('');
  return `SG-${date}-${rand}`;
}

function normalizePhone(phone: string): string {
  return phone.replace(/[^0-9]/g, '').replace(/^62/, '08').replace(/^8/, '08');
}

async function sendWhatsApp(phone: string, message: string, type: string): Promise<void> {
  const gatewayUrl = Deno.env.get('WA_GATEWAY_URL');
  const token = Deno.env.get('WA_GATEWAY_TOKEN');
  if (!gatewayUrl || !token) return;
  try {
    await fetch(gatewayUrl, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Authorization: token },
      body: JSON.stringify({ target: phone, message, countryCode: '62' }),
    });
  } catch (err) {
    console.error(`WA send failed for ${phone} (${type}):`, err);
  }
}

async function createSupabaseAuthUser(user: { id: string; phoneNumber: string; fullName: string }, password: string): Promise<string | undefined> {
  const projectRef = Deno.env.get('SUPABASE_PROJECT_REF');
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  if (!projectRef || !serviceRoleKey) return undefined;
  const email = `${user.phoneNumber}@customer.servisgadget.com`;
  try {
    const res = await fetch(`https://${projectRef}.supabase.co/auth/v1/admin/users`, {
      method: 'POST',
      headers: { Authorization: `Bearer ${serviceRoleKey}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password, email_confirm: true, user_metadata: { role: 'customer', phone: user.phoneNumber, full_name: user.fullName, is_first_login: true } }),
    });
    const data = await res.json();
    if (data.id) return data.id;
  } catch (err) {
    console.error(`Failed to create Supabase Auth user for ${email}:`, err);
  }
}

export default {
  fetch: withSupabase({ auth: 'none' }, async (req: Request, ctx) => {
    if (req.method === 'OPTIONS') return new Response('ok', { headers: { ...corsHeaders } });

    const url = new URL(req.url);
    const action = url.pathname.split('/').pop();
    let body: Record<string, unknown> = {};
    try { body = await req.json(); } catch { return fail('INVALID_JSON', 'Invalid JSON body'); }

    const { supabaseAdmin: admin } = ctx;
    const userClaims = (ctx as any).userClaims;

    // ─── CREATE ORDER (public) ───
    if (action === 'create-order') {
      const { store_id, device_type, brand, device_model, delivery_method, delivery_address, customer_name, phone_number, items, coupon_code } = body as any;
      if (!store_id || !device_type || !brand || !device_model || !customer_name || !phone_number || !items?.length) {
        return fail('INVALID_INPUT', 'Missing required fields');
      }

      const phone = normalizePhone(phone_number);
      const password = randomString(12);

      // Check existing user or create new
      const { data: existingUser } = await admin.from('users').select('id').eq('phone_number', phone).single();
      let userId: string;
      let isNew = false;
      if (existingUser) {
        userId = existingUser.id;
      } else {
        const { data: newUser } = await admin.from('users').insert({
          full_name: customer_name, phone_number: phone, password_hash: password, account_status: 'suspended', is_first_login: true, is_credential_sent: false
        }).select('id').single();
        if (!newUser) return fail('CREATE_FAILED', 'Failed to create user');
        userId = newUser.id;
        isNew = true;
      }

      // Verify store
      const { data: store } = await admin.from('stores').select('id, phone_number').eq('id', store_id).eq('is_active', true).single();
      if (!store) return fail('STORE_NOT_ACTIVE', 'Store is not active');

      // Reserve stock
      for (const item of items) {
        if (item.sparepart_id) {
          const { data: reserved } = await admin.rpc('reserve_stock', { p_sparepart_id: item.sparepart_id, p_qty: 1 });
          if (!reserved) return fail('STOCK_UNAVAILABLE', `Stock unavailable for sparepart ${item.sparepart_id}`);
        }
      }

      const orderNumber = generateOrderNumber();
      const totalEstimasi = items.reduce((s: number, i: any) => s + (i.item_price || 0), 0);
      const waConfigured = !!(Deno.env.get('WA_GATEWAY_URL') && Deno.env.get('WA_GATEWAY_TOKEN'));

      const { data: order, error: orderErr } = await admin.from('service_orders').insert({
        user_id: userId, store_id, order_number, device_type, brand, device_model,
        delivery_method, delivery_address: delivery_address || null,
        status: 'waiting_device', total_estimasi: totalEstimasi,
        sla_deadline: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(),
      }).select().single();
      if (orderErr) return fail('CREATE_FAILED', orderErr.message);

      await admin.from('order_items').insert(items.map((item: any) => ({
        order_id: order.id, sparepart_id: item.sparepart_id || null,
        service_type: item.service_type, complaint: item.complaint, item_price: item.item_price || 0,
      })));

      await admin.from('service_tracking').insert({
        order_id: order.id, status: 'waiting_device', note: 'Order dibuat',
        created_by_type: 'customer', created_by_id: userId,
      });

      // Notify store
      const storeMsg = `Order Baru!\nNo: ${orderNumber}\nPelanggan: ${customer_name} (${phone})\nDevice: ${device_type} ${brand} ${device_model}\nEstimasi: Rp ${totalEstimai.toLocaleString('id-ID')}\nSegera cek dashboard.`;
      await sendWhatsApp(store.phone_number, storeMsg, 'new_order');

      if (isNew) {
        const customerMsg = `Halo ${customer_name}!\nAkun ServisGadget kamu sudah dibuat.\nNomor HP: ${phone}\nPassword: ${password}\nSegera login dan ganti passwordmu.\nOrder #${orderNumber} akan segera diproses.`;
        await sendWhatsApp(phone, customerMsg, 'stealth_account');
      }

      return ok({
        order_id: order.id,
        order_number,
        is_new_customer: isNew,
        temp_password: isNew && !waConfigured ? password : undefined,
        message: isNew
          ? (waConfigured ? 'Order berhasil dibuat. Cek WhatsApp untuk info akun.' : 'Order berhasil dibuat. Simpan password yang ditampilkan.')
          : 'Order berhasil dibuat.',
      });
    }

    // ─── TRACK ORDER (public) ───
    if (action === 'track') {
      const { order_number, phone_number } = body as any;
      if (!order_number || !phone_number) return fail('INVALID_INPUT', 'order_number and phone_number required');
      const phone = normalizePhone(phone_number);
      const { data: order } = await admin.from('service_orders').select('*, user:users(phone_number), tracking:service_tracking(*, status, note, created_at), store:stores(store_name)')
        .eq('order_number', order_number).single();
      if (!order || order.user.phone_number !== phone) return fail('ORDER_NOT_FOUND', 'Order not found', 404);
      return ok({
        order_number: order.order_number, status: order.status, store_name: order.store.store_name,
        device_type: order.device_type, brand: order.brand, device_model: order.device_model,
        delivery_method: order.delivery_method, created_at: order.created_at,
        tracking: order.tracking.map((t: any) => ({ status: t.status, note: t.note, created_at: t.created_at })),
      });
    }

    // ─── CREDENTIALS (public) ───
    if (action === 'credentials') {
      const { order_id, phone_number } = body as any;
      if (!order_id || !phone_number) return fail('INVALID_INPUT', 'order_id and phone_number required');
      const phone = normalizePhone(phone_number);
      const { data: order } = await admin.from('service_orders').select('*, user:users(*)').eq('id', order_id).single();
      if (!order || order.user.phone_number !== phone) return fail('ORDER_NOT_FOUND', 'Order not found', 404);
      const user = order.user;
      const canActivate = ['device_received', 'diagnosing', 'waiting_approval', 'waiting_sparepart', 'repairing', 'quality_check', 'waiting_payment', 'completed'].includes(order.status);
      const isActivated = user.account_status === 'active';
      return ok({
        order_number: order.order_number, status: order.status, can_activate: canActivate, is_activated: isActivated,
        phone_number: user.phone_number, has_credential: !isActivated, masked_password: null, full_name: user.full_name,
      });
    }

    // ─── ACTIVATE (auth required, store admin only) ───
    if (action === 'activate') {
      if (!userClaims) return fail('UNAUTHORIZED', 'Unauthorized', 401);
      const role = userClaims.user_metadata?.role as string;
      if (role !== 'store_admin') return fail('FORBIDDEN', 'Forbidden', 403);

      const { order_id } = body as any;
      if (!order_id) return fail('INVALID_INPUT', 'order_id required');

      const { data: adminRow } = await admin.from('store_admins').select('store_id').eq('id', userClaims.id).single();
      if (!adminRow) return fail('FORBIDDEN', 'Forbidden', 403);

      const { data: order } = await admin.from('service_orders').select('*, user:users(*)').eq('id', order_id).eq('store_id', adminRow.store_id).single();
      if (!order) return fail('ORDER_NOT_FOUND', 'Order not found', 404);

      const user = order.user;
      if (user.account_status !== 'suspended') return fail('ALREADY_ACTIVATED', 'Account already activated');
      if (user.credential_plain_enc) return ok({ message: 'Akun sudah diaktifkan sebelumnya.' });

      // Generate new password and create Supabase Auth user
      const newPassword = randomString(12);
      const supabaseUserId = await createSupabaseAuthUser(user, newPassword);

      await admin.from('users').update({
        account_status: 'active', is_credential_sent: true,
        ...(supabaseUserId ? { supabase_user_id: supabaseUserId } : {}),
      }).eq('id', user.id);

      // Send WhatsApp
      const msg = `Halo ${user.full_name}!\nAkun ServisGadget kamu sekarang aktif!\nLogin dengan:\nUsername: ${user.phone_number}\nPassword: ${newPassword}\nJangan lupa ganti password setelah login.`;
      await sendWhatsApp(user.phone_number, msg, 'account_activated');

      // In-app notification
      await admin.from('notifications').insert({
        user_id: user.id, role: 'customer', title: 'Akun Aktif',
        message: 'Akun ServisGadget kamu sudah aktif! Kamu bisa login menggunakan nomor WhatsApp dan password.',
        type: 'account_activated',
      });

      return ok({ message: 'Akun berhasil diaktifkan. Cek WhatsApp untuk info login.' });
    }

    return fail('NOT_FOUND', 'Endpoint not found', 404);
  }),
}
