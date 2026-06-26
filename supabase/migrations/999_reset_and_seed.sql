-- ══════════════════════════════════════════════════
-- 999_reset_and_seed.sql — TRUNCATE + SEED FRESH
-- Run ONCE after deployment.
-- Password admin ada di data.md (gitignored)
-- ══════════════════════════════════════════════════

-- ─── TRUNCATE ALL DATA (reset to zero) ───
TRUNCATE TABLE
  notifications,
  failed_notifications,
  coupons,
  reviews,
  disputes,
  payments,
  service_tracking,
  shipments,
  order_items,
  service_orders,
  user_sessions,
  spareparts,
  store_applications,
  store_admins,
  users,
  stores,
  platform_admins
RESTART IDENTITY CASCADE;

-- ─── PLATFORM ADMIN ───
-- Password ada di data.md (bcrypt hash di-generate otomatis)
INSERT INTO platform_admins (username, password_hash, full_name)
SELECT 'admin', crypt('U7ooPmJArZxIGBfH', gen_salt('bf', 10)), 'Platform Admin'
WHERE NOT EXISTS (SELECT 1 FROM platform_admins WHERE username = 'admin');

-- ─── STORES ───
INSERT INTO stores (id, store_name, address, phone_number, config, is_active, rating_avg, total_completed, updated_at)
VALUES
  ('a0000001-0000-0000-0000-000000000001', 'TechFix Center', 'Jl. Merdeka No. 123, Jakarta', '628123456781', '{"warranty_days": 30}', true, 4.5, 150, now()),
  ('a0000001-0000-0000-0000-000000000002', 'GadgetCare Plus', 'Jl. Sudirman No. 45, Bandung', '628123456782', '{"warranty_days": 45}', true, 4.8, 230, now()),
  ('a0000001-0000-0000-0000-000000000003', 'AppleOnly Service', 'Jl. Thamrin No. 67, Jakarta', '628123456783', '{"warranty_days": 60, "device_types": {"android": false, "ios": true}}', true, 4.9, 310, now()),
  ('a0000001-0000-0000-0000-000000000004', 'Android Masters', 'Jl. Gatot Subroto No. 89, Surabaya', '628123456784', '{"warranty_days": 30, "device_types": {"android": true, "ios": false}}', true, 4.6, 180, now()),
  ('a0000001-0000-0000-0000-000000000005', 'FixPedia', 'Jl. Diponegoro No. 12, Yogyakarta', '628123456785', '{"warranty_days": 30}', true, 4.3, 95, now())
ON CONFLICT (id) DO NOTHING;

-- ─── SPAREPARTS ───
ALTER TABLE spareparts ALTER COLUMN updated_at SET DEFAULT now();

-- TechFix Center (Samsung S24 + Xiaomi)
INSERT INTO spareparts (store_id, brand, device_model, part_type, part_name, price, qty, qty_reserved, status)
SELECT 'a0000001-0000-0000-0000-000000000001', 'Samsung', 'S24', 'screen_replacement', 'LCD Samsung S24 Original', 1200000, 10, 0, 'available'
WHERE NOT EXISTS (SELECT 1 FROM spareparts WHERE store_id = 'a0000001-0000-0000-0000-000000000001' AND part_name = 'LCD Samsung S24 Original');
INSERT INTO spareparts (store_id, brand, device_model, part_type, part_name, price, qty, qty_reserved, status) SELECT 'a0000001-0000-0000-0000-000000000001', 'Samsung', 'S24', 'battery_replacement', 'Baterai Samsung S24 Original', 350000, 15, 0, 'available' WHERE NOT EXISTS (SELECT 1 FROM spareparts WHERE store_id = 'a0000001-0000-0000-0000-000000000001' AND part_name = 'Baterai Samsung S24 Original');
INSERT INTO spareparts (store_id, brand, device_model, part_type, part_name, price, qty, qty_reserved, status) SELECT 'a0000001-0000-0000-0000-000000000001', 'Samsung', 'S24', 'charging_port', 'Flex Charging Samsung S24', 250000, 12, 0, 'available' WHERE NOT EXISTS (SELECT 1 FROM spareparts WHERE store_id = 'a0000001-0000-0000-0000-000000000001' AND part_name = 'Flex Charging Samsung S24');
INSERT INTO spareparts (store_id, brand, device_model, part_type, part_name, price, qty, qty_reserved, status) SELECT 'a0000001-0000-0000-0000-000000000001', 'Xiaomi', 'Redmi Note 13', 'screen_replacement', 'LCD Redmi Note 13 Original', 800000, 8, 0, 'available' WHERE NOT EXISTS (SELECT 1 FROM spareparts WHERE store_id = 'a0000001-0000-0000-0000-000000000001' AND part_name = 'LCD Redmi Note 13 Original');
INSERT INTO spareparts (store_id, brand, device_model, part_type, part_name, price, qty, qty_reserved, status) SELECT 'a0000001-0000-0000-0000-000000000001', 'Xiaomi', 'Redmi Note 13', 'battery_replacement', 'Baterai Redmi Note 13', 250000, 10, 0, 'available' WHERE NOT EXISTS (SELECT 1 FROM spareparts WHERE store_id = 'a0000001-0000-0000-0000-000000000001' AND part_name = 'Baterai Redmi Note 13');

-- GadgetCare Plus (Samsung + Oppo)
INSERT INTO spareparts (store_id, brand, device_model, part_type, part_name, price, qty, qty_reserved, status) SELECT 'a0000001-0000-0000-0000-000000000002', 'Samsung', 'S24', 'screen_replacement', 'LCD Samsung S24 Garansi 3bln', 1350000, 7, 0, 'available' WHERE NOT EXISTS (SELECT 1 FROM spareparts WHERE store_id = 'a0000001-0000-0000-0000-000000000002' AND part_name = 'LCD Samsung S24 Garansi 3bln');
INSERT INTO spareparts (store_id, brand, device_model, part_type, part_name, price, qty, qty_reserved, status) SELECT 'a0000001-0000-0000-0000-000000000002', 'Samsung', 'S24', 'battery_replacement', 'Baterai Samsung S24 Original+', 380000, 12, 0, 'available' WHERE NOT EXISTS (SELECT 1 FROM spareparts WHERE store_id = 'a0000001-0000-0000-0000-000000000002' AND part_name = 'Baterai Samsung S24 Original+');
INSERT INTO spareparts (store_id, brand, device_model, part_type, part_name, price, qty, qty_reserved, status) SELECT 'a0000001-0000-0000-0000-000000000002', 'Oppo', 'Reno 11', 'screen_replacement', 'LCD Oppo Reno 11 Original', 900000, 6, 0, 'available' WHERE NOT EXISTS (SELECT 1 FROM spareparts WHERE store_id = 'a0000001-0000-0000-0000-000000000002' AND part_name = 'LCD Oppo Reno 11 Original');
INSERT INTO spareparts (store_id, brand, device_model, part_type, part_name, price, qty, qty_reserved, status) SELECT 'a0000001-0000-0000-0000-000000000002', 'Oppo', 'Reno 11', 'battery_replacement', 'Baterai Oppo Reno 11', 300000, 8, 0, 'available' WHERE NOT EXISTS (SELECT 1 FROM spareparts WHERE store_id = 'a0000001-0000-0000-0000-000000000002' AND part_name = 'Baterai Oppo Reno 11');
INSERT INTO spareparts (store_id, brand, device_model, part_type, part_name, price, qty, qty_reserved, status) SELECT 'a0000001-0000-0000-0000-000000000002', 'Oppo', 'Reno 11', 'camera', 'Kamera Oppo Reno 11', 650000, 4, 0, 'available' WHERE NOT EXISTS (SELECT 1 FROM spareparts WHERE store_id = 'a0000001-0000-0000-0000-000000000002' AND part_name = 'Kamera Oppo Reno 11');

-- AppleOnly Service (iOS only)
INSERT INTO spareparts (store_id, brand, device_model, part_type, part_name, price, qty, qty_reserved, status) SELECT 'a0000001-0000-0000-0000-000000000003', 'Apple', 'iPhone 15', 'screen_replacement', 'Display iPhone 15 Original', 2000000, 5, 0, 'available' WHERE NOT EXISTS (SELECT 1 FROM spareparts WHERE store_id = 'a0000001-0000-0000-0000-000000000003' AND part_name = 'Display iPhone 15 Original');
INSERT INTO spareparts (store_id, brand, device_model, part_type, part_name, price, qty, qty_reserved, status) SELECT 'a0000001-0000-0000-0000-000000000003', 'Apple', 'iPhone 15', 'battery_replacement', 'Baterai iPhone 15 Original', 500000, 10, 0, 'available' WHERE NOT EXISTS (SELECT 1 FROM spareparts WHERE store_id = 'a0000001-0000-0000-0000-000000000003' AND part_name = 'Baterai iPhone 15 Original');
INSERT INTO spareparts (store_id, brand, device_model, part_type, part_name, price, qty, qty_reserved, status) SELECT 'a0000001-0000-0000-0000-000000000003', 'Apple', 'iPhone 15 Pro', 'battery_replacement', 'Baterai iPhone 15 Pro', 550000, 7, 0, 'available' WHERE NOT EXISTS (SELECT 1 FROM spareparts WHERE store_id = 'a0000001-0000-0000-0000-000000000003' AND part_name = 'Baterai iPhone 15 Pro');
INSERT INTO spareparts (store_id, brand, device_model, part_type, part_name, price, qty, qty_reserved, status) SELECT 'a0000001-0000-0000-0000-000000000003', 'Apple', 'iPhone 15 Pro', 'camera', 'Kamera iPhone 15 Pro', 1800000, 2, 0, 'available' WHERE NOT EXISTS (SELECT 1 FROM spareparts WHERE store_id = 'a0000001-0000-0000-0000-000000000003' AND part_name = 'Kamera iPhone 15 Pro');

-- Android Masters (Android only)
INSERT INTO spareparts (store_id, brand, device_model, part_type, part_name, price, qty, qty_reserved, status) SELECT 'a0000001-0000-0000-0000-000000000004', 'Samsung', 'S24', 'screen_replacement', 'LCD Samsung S24 AMOLED', 1100000, 15, 0, 'available' WHERE NOT EXISTS (SELECT 1 FROM spareparts WHERE store_id = 'a0000001-0000-0000-0000-000000000004' AND part_name = 'LCD Samsung S24 AMOLED');
INSERT INTO spareparts (store_id, brand, device_model, part_type, part_name, price, qty, qty_reserved, status) SELECT 'a0000001-0000-0000-0000-000000000004', 'Samsung', 'S24', 'battery_replacement', 'Baterai Samsung S24 5000mAh', 320000, 20, 0, 'available' WHERE NOT EXISTS (SELECT 1 FROM spareparts WHERE store_id = 'a0000001-0000-0000-0000-000000000004' AND part_name = 'Baterai Samsung S24 5000mAh');
INSERT INTO spareparts (store_id, brand, device_model, part_type, part_name, price, qty, qty_reserved, status) SELECT 'a0000001-0000-0000-0000-000000000004', 'Samsung', 'Galaxy A55', 'screen_replacement', 'LCD Galaxy A55 Original', 650000, 10, 0, 'available' WHERE NOT EXISTS (SELECT 1 FROM spareparts WHERE store_id = 'a0000001-0000-0000-0000-000000000004' AND part_name = 'LCD Galaxy A55 Original');
INSERT INTO spareparts (store_id, brand, device_model, part_type, part_name, price, qty, qty_reserved, status) SELECT 'a0000001-0000-0000-0000-000000000004', 'Xiaomi', 'Redmi Note 13', 'screen_replacement', 'LCD Redmi Note 13 AMOLED', 750000, 8, 0, 'available' WHERE NOT EXISTS (SELECT 1 FROM spareparts WHERE store_id = 'a0000001-0000-0000-0000-000000000004' AND part_name = 'LCD Redmi Note 13 AMOLED');
INSERT INTO spareparts (store_id, brand, device_model, part_type, part_name, price, qty, qty_reserved, status) SELECT 'a0000001-0000-0000-0000-000000000004', 'Google', 'Pixel 8', 'screen_replacement', 'Display Google Pixel 8', 1400000, 4, 0, 'available' WHERE NOT EXISTS (SELECT 1 FROM spareparts WHERE store_id = 'a0000001-0000-0000-0000-000000000004' AND part_name = 'Display Google Pixel 8');
INSERT INTO spareparts (store_id, brand, device_model, part_type, part_name, price, qty, qty_reserved, status) SELECT 'a0000001-0000-0000-0000-000000000004', 'Google', 'Pixel 8', 'battery_replacement', 'Baterai Google Pixel 8', 400000, 6, 0, 'available' WHERE NOT EXISTS (SELECT 1 FROM spareparts WHERE store_id = 'a0000001-0000-0000-0000-000000000004' AND part_name = 'Baterai Google Pixel 8');

-- FixPedia (limited stock)
INSERT INTO spareparts (store_id, brand, device_model, part_type, part_name, price, qty, qty_reserved, status) SELECT 'a0000001-0000-0000-0000-000000000005', 'Samsung', 'S24', 'screen_replacement', 'LCD Samsung S24 Compatible', 950000, 3, 0, 'available' WHERE NOT EXISTS (SELECT 1 FROM spareparts WHERE store_id = 'a0000001-0000-0000-0000-000000000005' AND part_name = 'LCD Samsung S24 Compatible');
INSERT INTO spareparts (store_id, brand, device_model, part_type, part_name, price, qty, qty_reserved, status) SELECT 'a0000001-0000-0000-0000-000000000005', 'Samsung', 'S24', 'battery_replacement', 'Baterai Samsung S24', 300000, 5, 0, 'available' WHERE NOT EXISTS (SELECT 1 FROM spareparts WHERE store_id = 'a0000001-0000-0000-0000-000000000005' AND part_name = 'Baterai Samsung S24');
INSERT INTO spareparts (store_id, brand, device_model, part_type, part_name, price, qty, qty_reserved, status) SELECT 'a0000001-0000-0000-0000-000000000005', 'Xiaomi', 'Redmi Note 13', 'screen_replacement', 'LCD Redmi Note 13', 700000, 2, 0, 'available' WHERE NOT EXISTS (SELECT 1 FROM spareparts WHERE store_id = 'a0000001-0000-0000-0000-000000000005' AND part_name = 'LCD Redmi Note 13');
INSERT INTO spareparts (store_id, brand, device_model, part_type, part_name, price, qty, qty_reserved, status) SELECT 'a0000001-0000-0000-0000-000000000005', 'Google', 'Pixel 8', 'camera', 'Kamera Google Pixel 8', 900000, 1, 0, 'available' WHERE NOT EXISTS (SELECT 1 FROM spareparts WHERE store_id = 'a0000001-0000-0000-0000-000000000005' AND part_name = 'Kamera Google Pixel 8');
