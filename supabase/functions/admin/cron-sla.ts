import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { corsHeaders } from '../_shared/cors.ts';
import { ok, fail } from '../_shared/helpers.ts';

serve(async (_req: Request) => {
  const admin = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  );

  try {
    const cancelled = await admin.rpc('auto_cancel_sla');
    return ok({ cancelled });
  } catch (err: any) {
    return fail('CRON_FAILED', err.message, 500);
  }
});
