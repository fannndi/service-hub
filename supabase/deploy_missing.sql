-- Mark all existing migrations as applied + run 019 trigger cleanup
CREATE TABLE IF NOT EXISTS _supabase_migrations (version TEXT PRIMARY KEY, name TEXT, timestamp TIMESTAMPTZ DEFAULT now());
INSERT INTO _supabase_migrations (version, name) VALUES
  ('001','001_init.sql'),('002','002_rls.sql'),('003','003_functions.sql'),
  ('004','004_seed.sql'),('005','005_notifications.sql'),('006','006_seed_data.sql'),
  ('007','007_cron.sql'),('008','008_auto_cron.sql'),('010','010_fix_schema.sql'),
  ('013','013_fix_missing_tables.sql'),('015','015_midtrans.sql'),('016','016_fix_rpc_and_seed.sql'),
  ('017','017_email_notifications.sql'),('018','018_add_midtrans_unique.sql')
ON CONFLICT (version) DO NOTHING;

-- Drop with CASCADE to remove dependent trigger too
DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
DECLARE v_role TEXT;
BEGIN
  v_role := NEW.raw_user_meta_data ->> 'role';
  IF v_role = 'customer' THEN
    INSERT INTO public.users (id, full_name, phone_number, email, password_hash)
    VALUES (NEW.id, COALESCE(NEW.raw_user_meta_data ->> 'full_name', 'Pelanggan'),
            SPLIT_PART(NEW.email, '@', 1), NEW.email, 'supabase-managed')
    ON CONFLICT (id) DO UPDATE SET email = EXCLUDED.email,
      full_name = COALESCE(EXCLUDED.full_name, public.users.full_name);
  END IF;
  RETURN NEW;
END;
$$;
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Mark 019 as applied
INSERT INTO _supabase_migrations (version, name) VALUES ('019','019_trigger_cleanup.sql') ON CONFLICT (version) DO NOTHING;
