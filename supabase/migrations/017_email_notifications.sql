-- 017_email_notifications.sql
-- Add email column to users table for Resend.com integration

ALTER TABLE public.users ADD COLUMN IF NOT EXISTS email VARCHAR(255);

-- Update handle_new_user trigger to also store email
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
