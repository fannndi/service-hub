-- 006_seed_data.sql — TEST DATA
-- Run in Supabase SQL Editor (https://supabase.com/dashboard/project/eboplbemgtvmviwhdlfa/sql/new)
-- Password hash: bcrypt of 'test123'

-- ─── STORES ───

INSERT INTO stores (id, store_name, address, phone_number, config, is_active, rating_avg, total_completed)
VALUES
  ('a0000001-0000-0000-0000-000000000001', 'TechFix Center', 'Jl. Merdeka No. 123, Jakarta', '628123456781', '{"warranty_days": 30}', true, 4.5, 150),
  ('a0000001-0000-0000-0000-000000000002', 'GadgetCare Plus', 'Jl. Sudirman No. 45, Bandung', '628123456782', '{"warranty_days": 45}', true, 4.8, 230),
  ('a0000001-0000-0000-0000-000000000003', 'AppleOnly Service', 'Jl. Thamrin No. 67, Jakarta', '628123456783', '{"warranty_days": 60, "device_types": {"android": false, "ios": true}}', true, 4.9, 310),
  ('a0000001-0000-0000-0000-000000000004', 'Android Masters', 'Jl. Gatot Subroto No. 89, Surabaya', '628123456784', '{"warranty_days": 30, "device_types": {"android": true, "ios": false}}', true, 4.6, 180),
  ('a0000001-0000-0000-0000-000000000005', 'FixPedia', 'Jl. Diponegoro No. 12, Yogyakarta', '628123456785', '{"warranty_days": 30}', true, 4.3, 95)
ON CONFLICT (id) DO NOTHING;

-- ─── SPAREPARTS ───
-- Samsung S24 series
INSERT INTO spareparts (store_id, brand, device_model, part_type, part_name, price, qty, qty_reserved, status)
VALUES
  ('a0000001-0000-0000-0000-000000000001', 'Samsung', 'S24', 'screen_replacement', 'LCD Samsung S24 Original', 1200000, 10, 0, 'available'),
  ('a0000001-0000-0000-0000-000000000001', 'Samsung', 'S24', 'screen_replacement', 'LCD Samsung S24 Premium', 1500000, 5, 0, 'available'),
  ('a0000001-0000-0000-0000-000000000001', 'Samsung', 'S24', 'battery_replacement', 'Baterai Samsung S24 Original', 350000, 15, 0, 'available'),
  ('a0000001-0000-0000-0000-000000000001', 'Samsung', 'S24', 'battery_replacement', 'Baterai Samsung S24 High Capacity', 450000, 8, 0, 'available'),
  ('a0000001-0000-0000-0000-000000000001', 'Samsung', 'S24', 'charging_port', 'Flex Charging Samsung S24', 250000, 12, 0, 'available'),
  ('a0000001-0000-0000-0000-000000000001', 'Samsung', 'S24', 'camera', 'Kamera Belakang Samsung S24', 800000, 4, 0, 'available'),
  ('a0000001-0000-0000-0000-000000000001', 'Samsung', 'S24', 'camera', 'Kamera Depan Samsung S24', 500000, 6, 0, 'available'),
-- Xiaomi Redmi Note 13
  ('a0000001-0000-0000-0000-000000000001', 'Xiaomi', 'Redmi Note 13', 'screen_replacement', 'LCD Redmi Note 13 Original', 800000, 8, 0, 'available'),
  ('a0000001-0000-0000-0000-000000000001', 'Xiaomi', 'Redmi Note 13', 'battery_replacement', 'Baterai Redmi Note 13', 250000, 10, 0, 'available'),
  ('a0000001-0000-0000-0000-000000000001', 'Xiaomi', 'Redmi Note 13', 'charging_port', 'Flex Charging Redmi Note 13', 180000, 6, 0, 'available')
ON CONFLICT DO NOTHING;

-- GadgetCare Plus (Samsung + Oppo)
INSERT INTO spareparts (store_id, brand, device_model, part_type, part_name, price, qty, qty_reserved, status)
VALUES
  ('a0000001-0000-0000-0000-000000000002', 'Samsung', 'S24', 'screen_replacement', 'LCD Samsung S24 Garansi 3bln', 1350000, 7, 0, 'available'),
  ('a0000001-0000-0000-0000-000000000002', 'Samsung', 'S24', 'battery_replacement', 'Baterai Samsung S24 Original+', 380000, 12, 0, 'available'),
  ('a0000001-0000-0000-0000-000000000002', 'Samsung', 'S24', 'charging_port', 'Port Charger Samsung S24', 220000, 9, 0, 'available'),
  ('a0000001-0000-0000-0000-000000000002', 'Samsung', 'S24', 'camera', 'Kamera Samsung S24 Set', 1200000, 3, 0, 'available'),
  ('a0000001-0000-0000-0000-000000000002', 'Oppo', 'Reno 11', 'screen_replacement', 'LCD Oppo Reno 11 Original', 900000, 6, 0, 'available'),
  ('a0000001-0000-0000-0000-000000000002', 'Oppo', 'Reno 11', 'battery_replacement', 'Baterai Oppo Reno 11', 300000, 8, 0, 'available'),
  ('a0000001-0000-0000-0000-000000000002', 'Oppo', 'Reno 11', 'camera', 'Kamera Oppo Reno 11', 650000, 4, 0, 'available')
ON CONFLICT DO NOTHING;

-- AppleOnly Service (iPhone only — device_types: ios only)
INSERT INTO spareparts (store_id, brand, device_model, part_type, part_name, price, qty, qty_reserved, status)
VALUES
  ('a0000001-0000-0000-0000-000000000003', 'Apple', 'iPhone 15', 'screen_replacement', 'Display iPhone 15 Original', 2000000, 5, 0, 'available'),
  ('a0000001-0000-0000-0000-000000000003', 'Apple', 'iPhone 15', 'screen_replacement', 'Display iPhone 15 OEM', 1500000, 8, 0, 'available'),
  ('a0000001-0000-0000-0000-000000000003', 'Apple', 'iPhone 15', 'battery_replacement', 'Baterai iPhone 15 Original', 500000, 10, 0, 'available'),
  ('a0000001-0000-0000-0000-000000000003', 'Apple', 'iPhone 15', 'charging_port', 'Charging Port iPhone 15', 350000, 6, 0, 'available'),
  ('a0000001-0000-0000-0000-000000000003', 'Apple', 'iPhone 15 Pro', 'screen_replacement', 'Display iPhone 15 Pro Original', 2500000, 3, 0, 'preorder'),
  ('a0000001-0000-0000-0000-000000000003', 'Apple', 'iPhone 15 Pro', 'battery_replacement', 'Baterai iPhone 15 Pro', 550000, 7, 0, 'available'),
  ('a0000001-0000-0000-0000-000000000003', 'Apple', 'iPhone 15 Pro', 'camera', 'Kamera iPhone 15 Pro', 1800000, 2, 0, 'available')
ON CONFLICT DO NOTHING;

-- Android Masters (Android only)
INSERT INTO spareparts (store_id, brand, device_model, part_type, part_name, price, qty, qty_reserved, status)
VALUES
  ('a0000001-0000-0000-0000-000000000004', 'Samsung', 'S24', 'screen_replacement', 'LCD Samsung S24 AMOLED', 1100000, 15, 0, 'available'),
  ('a0000001-0000-0000-0000-000000000004', 'Samsung', 'S24', 'battery_replacement', 'Baterai Samsung S24 5000mAh', 320000, 20, 0, 'available'),
  ('a0000001-0000-0000-0000-000000000004', 'Samsung', 'Galaxy A55', 'screen_replacement', 'LCD Galaxy A55 Original', 650000, 10, 0, 'available'),
  ('a0000001-0000-0000-0000-000000000004', 'Samsung', 'Galaxy A55', 'battery_replacement', 'Baterai Galaxy A55', 280000, 12, 0, 'available'),
  ('a0000001-0000-0000-0000-000000000004', 'Samsung', 'Galaxy A55', 'charging_port', 'Flex Charging Galaxy A55', 150000, 8, 0, 'available'),
  ('a0000001-0000-0000-0000-000000000004', 'Xiaomi', 'Redmi Note 13', 'screen_replacement', 'LCD Redmi Note 13 AMOLED', 750000, 8, 0, 'available'),
  ('a0000001-0000-0000-0000-000000000004', 'Xiaomi', 'Redmi Note 13', 'battery_replacement', 'Baterai Redmi Note 13 5020mAh', 230000, 15, 0, 'available'),
  ('a0000001-0000-0000-0000-000000000004', 'Google', 'Pixel 8', 'screen_replacement', 'Display Google Pixel 8', 1400000, 4, 0, 'available'),
  ('a0000001-0000-0000-0000-000000000004', 'Google', 'Pixel 8', 'battery_replacement', 'Baterai Google Pixel 8', 400000, 6, 0, 'available')
ON CONFLICT DO NOTHING;

-- FixPedia (all brands, limited stock)
INSERT INTO spareparts (store_id, brand, device_model, part_type, part_name, price, qty, qty_reserved, status)
VALUES
  ('a0000001-0000-0000-0000-000000000005', 'Samsung', 'S24', 'screen_replacement', 'LCD Samsung S24 Compatible', 950000, 3, 0, 'available'),
  ('a0000001-0000-0000-0000-000000000005', 'Samsung', 'S24', 'battery_replacement', 'Baterai Samsung S24', 300000, 5, 0, 'available'),
  ('a0000001-0000-0000-0000-000000000005', 'Xiaomi', 'Redmi Note 13', 'screen_replacement', 'LCD Redmi Note 13', 700000, 2, 0, 'available'),
  ('a0000001-0000-0000-0000-000000000005', 'Oppo', 'Reno 11', 'charging_port', 'Charging Port Oppo Reno 11', 160000, 4, 0, 'available'),
  ('a0000001-0000-0000-0000-000000000005', 'Google', 'Pixel 8', 'camera', 'Kamera Google Pixel 8', 900000, 1, 0, 'available')
ON CONFLICT DO NOTHING;

-- ═══════════════════════════════════════════
-- AUTH USERS (via auth schema)
-- ═══════════════════════════════════════════
-- Note: These use Supabase's auth schema. If they fail, create users via
-- Authentication → Add User in Supabase Dashboard with password 'test123'
-- ═══════════════════════════════════════════

-- Helper: create auth user + profile in one go
DO $$
DECLARE
  uid UUID;
BEGIN
  -- Store Admin 1 - TechFix Center
  uid := gen_random_uuid();
  INSERT INTO auth.users (id, email, phone, raw_user_meta_data, encrypted_password, email_confirmed_at, created_at, updated_at)
  VALUES (uid, '628123456781@store.servisgadget.com', '628123456781', 
    jsonb_build_object('role', 'store_admin', 'store_id', 'a0000001-0000-0000-0000-000000000001', 'full_name', 'Admin TechFix'),
    crypt('test123', gen_salt('bf', 10)), now(), now(), now())
  ON CONFLICT (email) DO NOTHING;
  INSERT INTO public.store_admins (id, store_id, full_name, phone_number, password_hash, is_active)
  VALUES (uid, 'a0000001-0000-0000-0000-000000000001', 'Admin TechFix', '628123456781', 'supabase-managed', true)
  ON CONFLICT (id, store_id) DO NOTHING;

  -- Store Admin 2 - GadgetCare Plus
  uid := gen_random_uuid();
  INSERT INTO auth.users (id, email, phone, raw_user_meta_data, encrypted_password, email_confirmed_at, created_at, updated_at)
  VALUES (uid, '628123456782@store.servisgadget.com', '628123456782',
    jsonb_build_object('role', 'store_admin', 'store_id', 'a0000001-0000-0000-0000-000000000002', 'full_name', 'Admin GadgetCare'),
    crypt('test123', gen_salt('bf', 10)), now(), now(), now())
  ON CONFLICT (email) DO NOTHING;
  INSERT INTO public.store_admins (id, store_id, full_name, phone_number, password_hash, is_active)
  VALUES (uid, 'a0000001-0000-0000-0000-000000000002', 'Admin GadgetCare', '628123456782', 'supabase-managed', true)
  ON CONFLICT (id, store_id) DO NOTHING;

  -- Store Admin 3 - AppleOnly Service
  uid := gen_random_uuid();
  INSERT INTO auth.users (id, email, phone, raw_user_meta_data, encrypted_password, email_confirmed_at, created_at, updated_at)
  VALUES (uid, '628123456783@store.servisgadget.com', '628123456783',
    jsonb_build_object('role', 'store_admin', 'store_id', 'a0000001-0000-0000-0000-000000000003', 'full_name', 'Admin AppleOnly'),
    crypt('test123', gen_salt('bf', 10)), now(), now(), now())
  ON CONFLICT (email) DO NOTHING;
  INSERT INTO public.store_admins (id, store_id, full_name, phone_number, password_hash, is_active)
  VALUES (uid, 'a0000001-0000-0000-0000-000000000003', 'Admin AppleOnly', '628123456783', 'supabase-managed', true)
  ON CONFLICT (id, store_id) DO NOTHING;

  -- Store Admin 4 - Android Masters
  uid := gen_random_uuid();
  INSERT INTO auth.users (id, email, phone, raw_user_meta_data, encrypted_password, email_confirmed_at, created_at, updated_at)
  VALUES (uid, '628123456784@store.servisgadget.com', '628123456784',
    jsonb_build_object('role', 'store_admin', 'store_id', 'a0000001-0000-0000-0000-000000000004', 'full_name', 'Admin Android'),
    crypt('test123', gen_salt('bf', 10)), now(), now(), now())
  ON CONFLICT (email) DO NOTHING;
  INSERT INTO public.store_admins (id, store_id, full_name, phone_number, password_hash, is_active)
  VALUES (uid, 'a0000001-0000-0000-0000-000000000004', 'Admin Android', '628123456784', 'supabase-managed', true)
  ON CONFLICT (id, store_id) DO NOTHING;

  -- Store Admin 5 - FixPedia
  uid := gen_random_uuid();
  INSERT INTO auth.users (id, email, phone, raw_user_meta_data, encrypted_password, email_confirmed_at, created_at, updated_at)
  VALUES (uid, '628123456785@store.servisgadget.com', '628123456785',
    jsonb_build_object('role', 'store_admin', 'store_id', 'a0000001-0000-0000-0000-000000000005', 'full_name', 'Admin FixPedia'),
    crypt('test123', gen_salt('bf', 10)), now(), now(), now())
  ON CONFLICT (email) DO NOTHING;
  INSERT INTO public.store_admins (id, store_id, full_name, phone_number, password_hash, is_active)
  VALUES (uid, 'a0000001-0000-0000-0000-000000000005', 'Admin FixPedia', '628123456785', 'supabase-managed', true)
  ON CONFLICT (id, store_id) DO NOTHING;

  -- Test Customer 1
  uid := gen_random_uuid();
  INSERT INTO auth.users (id, email, phone, raw_user_meta_data, encrypted_password, email_confirmed_at, created_at, updated_at)
  VALUES (uid, '081234567890@customer.servisgadget.com', '081234567890',
    jsonb_build_object('role', 'customer', 'phone', '081234567890', 'full_name', 'Budi Santoso'),
    crypt('test123', gen_salt('bf', 10)), now(), now(), now())
  ON CONFLICT (email) DO NOTHING;
  INSERT INTO public.users (id, full_name, phone_number, password_hash, account_status, is_first_login)
  VALUES (uid, 'Budi Santoso', '081234567890', 'supabase-managed', 'active', false)
  ON CONFLICT (id) DO NOTHING;

  -- Test Customer 2
  uid := gen_random_uuid();
  INSERT INTO auth.users (id, email, phone, raw_user_meta_data, encrypted_password, email_confirmed_at, created_at, updated_at)
  VALUES (uid, '081234567891@customer.servisgadget.com', '081234567891',
    jsonb_build_object('role', 'customer', 'phone', '081234567891', 'full_name', 'Siti Rahma'),
    crypt('test123', gen_salt('bf', 10)), now(), now(), now())
  ON CONFLICT (email) DO NOTHING;
  INSERT INTO public.users (id, full_name, phone_number, password_hash, account_status, is_first_login)
  VALUES (uid, 'Siti Rahma', '081234567891', 'supabase-managed', 'active', false)
  ON CONFLICT (id) DO NOTHING;
END $$;
