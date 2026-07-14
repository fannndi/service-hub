const RESEND_KEY = () => Deno.env.get('RESEND_API_KEY');
const EMAIL_FROM = () => Deno.env.get('EMAIL_FROM') ?? 'onboarding@resend.dev';

export function isEmailConfigured(): boolean {
  return !!RESEND_KEY();
}

async function sendEmail(to: string, subject: string, html: string): Promise<{ ok: boolean; error?: string }> {
  const key = RESEND_KEY();
  if (!key) return { ok: false, error: 'RESEND_API_KEY not configured' };
  try {
    const res = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${key}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ from: EMAIL_FROM(), to, subject, html }),
    });
    if (!res.ok) {
      const err = await res.text();
      console.error('Resend error:', res.status, err);
      return { ok: false, error: `Resend ${res.status}: ${err}` };
    }
    return { ok: true };
  } catch (err) {
    console.error('Email send failed:', err);
    return { ok: false, error: `Exception: ${err}` };
  }
}



function baseHtml(body: string): string {
  return `<!DOCTYPE html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<style>body{font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;margin:0;padding:0;background:#f8fafc}
.container{max-width:600px;margin:0 auto;background:#fff}.header{background:linear-gradient(135deg,#8b5cf6,#6d28d9);padding:32px 24px;text-align:center}
.header h1{color:#fff;font-size:24px;margin:0}.body{padding:24px;color:#1e293b;line-height:1.6}
.card{background:#f1f5f9;border-radius:12px;padding:20px;margin:16px 0}.card h3{margin:0 0 12px;color:#475569;font-size:14px}
.credential{font-size:18px;font-weight:700;color:#8b5cf6;letter-spacing:1px}.footer{padding:16px 24px;text-align:center;color:#94a3b8;font-size:12px}
.badge{display:inline-block;background:#22c55e;color:#fff;padding:4px 12px;border-radius:20px;font-size:12px;font-weight:600}
</style></head><body><div class="container"><div class="header"><h1>🔧 Service Me</h1></div>
<div class="body">${body}</div>
<div class="footer">Service Me &copy; ${new Date().getFullYear()} — Gadget Repair Platform</div></div></body></html>`;
}

export async function sendOrderConfirmation(
  email: string, password: string, orderNumber: string, customerName: string,
  admin?: any,
): Promise<boolean> {
  const html = baseHtml(`
    <p>Halo <strong>${customerName}</strong>,</p>
    <p>Pesanan kamu berhasil dibuat! Berikut detail akun dan pesanan:</p>
    <div class="card">
      <h3>📋 DETAIL PESANAN</h3>
      <p>Nomor Pesanan: <span class="credential">${orderNumber}</span></p>
    </div>
    <div class="card">
      <h3>🔐 AKUN KAMU</h3>
      <p>Email: <strong>${email}</strong></p>
      <p>Password: <span class="credential">${password}</span></p>
    </div>
    <p>⚠️ <strong>Segera login dan ganti password</strong> setelah akun aktif.</p>
    <p>Akun akan aktif setelah toko menerima perangkatmu.</p>
  `);
  const result = await sendEmail(email, `Pesanan #${orderNumber} — Service Me`, html);
  if (!result.ok && admin) {
    try { await admin.from('failed_notifications').insert({
      recipient_type: 'email', recipient_id: email, channel: 'email', message_type: 'transactional',
      payload: { subject: `Pesanan #${orderNumber}`, order_number: orderNumber },
      attempt_count: 1, last_error: result.error || 'unknown',
    }); } catch (_) {}
  }
  return result.ok;
}

export async function sendActivationEmail(
  email: string, customerName: string, password: string, admin?: any,
): Promise<boolean> {
  const html = baseHtml(`
    <p>Halo <strong>${customerName}</strong>,</p>
    <p>🎉 <span class="badge">AKTIF</span></p>
    <p>Akun ServisGadget kamu sudah aktif! Kamu bisa login sekarang.</p>
    <div class="card">
      <h3>🔐 AKUN KAMU</h3>
      <p>Email: <strong>${email}</strong></p>
      <p>Password: <span class="credential">${password}</span></p>
    </div>
    <p>Segera login dan ganti passwordmu untuk keamanan.</p>
  `);
  const result = await sendEmail(email, 'Akun Aktif! — Service Me', html);
  if (!result.ok && admin) {
    try { await admin.from('failed_notifications').insert({
      recipient_type: 'email', recipient_id: email, channel: 'email', message_type: 'transactional',
      payload: { subject: 'Akun Aktif' }, attempt_count: 1, last_error: result.error || 'unknown',
    }); } catch (_) {}
  }
  return result.ok;
}

export async function sendNotificationEmail(
  to: string, subject: string, title: string, body: string,
): Promise<boolean> {
  const html = baseHtml(`
    <h2>${title}</h2>
    <p>${body.replace(/\n/g, '<br>')}</p>
  `);
  const result = await sendEmail(to, subject, html);
  return result.ok;
}
