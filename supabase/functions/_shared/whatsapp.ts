const WA_GW = () => Deno.env.get('WA_GATEWAY_URL');
const WA_TK = () => Deno.env.get('WA_GATEWAY_TOKEN');

export function isWAConfigured(): boolean {
  return !!(WA_GW() && WA_TK());
}

export async function sendWA(
  phone: string,
  message: string,
  admin?: any,
): Promise<boolean> {
  const gw = WA_GW();
  const tk = WA_TK();
  if (!gw || !tk) return false;
  try {
    await fetch(gw, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Authorization: tk },
      body: JSON.stringify({ target: phone, message, countryCode: '62' }),
    });
    return true;
  } catch (err) {
    console.error('WA send failed:', err);
    if (admin) {
      await admin.from('failed_notifications').insert({
        recipient_type: 'whatsapp',
        recipient_id: phone,
        message_type: 'transactional',
        payload: { message },
        attempt_count: 1,
        last_error: String(err),
      }).catch(() => {});
    }
    return false;
  }
}
