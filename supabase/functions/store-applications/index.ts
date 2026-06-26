import { withSupabase } from 'npm:@supabase/server'
import { ok, fail } from '../_shared/helpers.ts'
import { corsHeaders } from '../_shared/cors.ts'

export default {
  fetch: withSupabase({ auth: 'none' }, async (req: Request, ctx) => {
    if (req.method === 'OPTIONS') return new Response('ok', { headers: { ...corsHeaders } });
    if (req.method !== 'POST') return fail('METHOD_NOT_ALLOWED', 'POST only', 405);

    try {
      const { supabaseAdmin: admin } = ctx;
      const body = await req.json();
      const { store_name, address, phone_number, admin_name, admin_phone } = body;

      if (!store_name || !address || !phone_number || !admin_name || !admin_phone) {
        return fail('INVALID_INPUT', 'Semua field wajib diisi');
      }

      const phone = phone_number.replace(/\D/g, '');
      const adminPhone = admin_phone.replace(/\D/g, '');

      const { data: dup } = await admin.from('store_applications').select('id').eq('phone_number', phone).eq('status', 'pending').maybeSingle();
      if (dup) return fail('DUPLICATE', 'Sudah ada pendaftaran dengan nomor ini');

      const { data: app, error } = await admin.from('store_applications').insert({
        store_name: store_name.trim(),
        applicant_name: admin_name.trim(),
        phone_number: phone,
        address: address.trim(),
        status: 'pending',
      }).select('id').single();

      if (error) return fail('INSERT_FAILED', error.message);
      return ok({ application_id: app.id, message: 'Pendaftaran berhasil dikirim. Tunggu konfirmasi admin.' });
    } catch (err: any) {
      return fail(err.code || 'INTERNAL', err.message, 500);
    }
  }),
}
