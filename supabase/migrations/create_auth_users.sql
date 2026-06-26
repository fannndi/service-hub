-- Create auth users for store admins
INSERT INTO auth.users (id, email, phone, raw_user_meta_data, encrypted_password, email_confirmed_at, created_at, updated_at)
SELECT gen_random_uuid(), phone_number || '@store.servisgadget.com', phone_number,
  jsonb_build_object('role', 'store_admin', 'store_id', store_id, 'full_name', full_name),
  crypt('test123', gen_salt('bf', 10)), now(), now(), now()
FROM store_admins;
