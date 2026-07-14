-- 024: Fix handle_new_user trigger — use unique phone_number for guest signups
-- Previous version used SPLIT_PART(email, '@', 1) which violates UNIQUE constraint

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_role TEXT;
  v_phone TEXT;
BEGIN
  v_role := NEW.raw_user_meta_data ->> 'role';
  IF v_role = 'customer' THEN
    v_phone := NEW.raw_user_meta_data ->> 'phone_number';
    IF v_phone IS NULL OR v_phone = '' THEN
      v_phone := 'guest-' || encode(sha256(NEW.id::text::bytea), 'hex');
      v_phone := left(v_phone, 20);
    END IF;
    INSERT INTO public.users (id, full_name, phone_number, email, password_hash)
    VALUES (
      NEW.id,
      COALESCE(NEW.raw_user_meta_data ->> 'full_name', 'Pelanggan'),
      v_phone,
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
