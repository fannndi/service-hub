-- 007_cron.sql — pg_cron jobs (ganti NestJS @Cron)
-- Requires pg_cron extension (enabled by default on Supabase)
-- https://supabase.com/docs/guides/platform/cron

-- Enable pg_cron if not already
CREATE EXTENSION IF NOT EXISTS pg_cron WITH SCHEMA extensions;

-- SLA Monitor: auto-cancel orders breaching SLA (every 30 seconds)
SELECT cron.schedule('sla-monitor', '*/30 * * * *', $$SELECT auto_cancel_sla();$$);

-- Credential Cleaner: clear credentialPlainEnc after 24h (every 30 minutes)
SELECT cron.schedule('credential-cleaner', '0 */30 * * *', $$
  UPDATE public.users
  SET credential_plain_enc = NULL
  WHERE password_changed_at < NOW() - INTERVAL '24 hours'
    AND credential_plain_enc IS NOT NULL;
$$);
