-- Create test profiles (public schema only)
-- Auth users created via Supabase Dashboard or app login
-- Password for ALL: test123

INSERT INTO store_admins (id, store_id, full_name, phone_number, password_hash, is_active, is_first_login)
VALUES
  (gen_random_uuid(), 'a0000001-0000-0000-0000-000000000001', 'Admin TechFix', '628123456781', 'supabase-managed', true, false),
  (gen_random_uuid(), 'a0000001-0000-0000-0000-000000000002', 'Admin GadgetCare', '628123456782', 'supabase-managed', true, false),
  (gen_random_uuid(), 'a0000001-0000-0000-0000-000000000003', 'Admin AppleOnly', '628123456783', 'supabase-managed', true, false),
  (gen_random_uuid(), 'a0000001-0000-0000-0000-000000000004', 'Admin Android', '628123456784', 'supabase-managed', true, false),
  (gen_random_uuid(), 'a0000001-0000-0000-0000-000000000005', 'Admin FixPedia', '628123456785', 'supabase-managed', true, false)
ON CONFLICT (store_id, phone_number) DO NOTHING;

INSERT INTO users (id, full_name, phone_number, password_hash, account_status, is_first_login, updated_at)
VALUES
  (gen_random_uuid(), 'Budi Santoso', '081234567890', 'supabase-managed', 'active', false, now()),
  (gen_random_uuid(), 'Siti Rahma', '081234567891', 'supabase-managed', 'active', false, now())
ON CONFLICT (id) DO NOTHING;
