-- Fix handle_new_user() to only handle customers
CREATE OR REPLACE FUNCTION handle_new_user()
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
    INSERT INTO public.users (id, full_name, phone_number, password_hash)
    VALUES (
      NEW.id,
      COALESCE(NEW.raw_user_meta_data ->> 'full_name', 'Pelanggan'),
      SPLIT_PART(NEW.email, '@', 1),
      'supabase-managed'
    );
  END IF;
  RETURN NEW;
END;
$$;
