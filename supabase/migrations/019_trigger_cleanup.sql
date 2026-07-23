-- 019_trigger_cleanup.sql
-- Definitively fix handle_new_user trigger and clean up migration artifacts

-- 1. Drop old orphaned trigger versions (no-op if they don't exist)
DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;

-- 2. Recreate the definitive version with email + upsert
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_role TEXT;
BEGIN
  v_role := NEW.raw_user_meta_data ->> 'role';
  IF v_role = 'customer' THEN
    INSERT INTO public.users (id, full_name, phone_number, email, password_hash)
    VALUES (
      NEW.id,
      COALESCE(NEW.raw_user_meta_data ->> 'full_name', 'Pelanggan'),
      SPLIT_PART(NEW.email, '@', 1),
      NEW.email,
      'supabase-managed'
    )
    ON CONFLICT (id) DO UPDATE SET
      email = EXCLUDED.email,
      full_name = COALESCE(EXCLUDED.full_name, public.users.full_name);
  END IF;
  RETURN NEW;
END;
$$;

-- 3. Drop and recreate trigger to ensure it's properly registered
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();
