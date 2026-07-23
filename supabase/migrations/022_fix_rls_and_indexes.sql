-- 022_fix_rls_and_indexes.sql — RLS gaps, CHECK constraints, missing indexes, unique constraints
-- Note: remote DB uses TEXT for all UUID columns, so auth.uid() must be cast to text

-- ─── 1. MISSING INSERT POLICY: order_items ───

DROP POLICY IF EXISTS customer_order_items_insert ON order_items;
CREATE POLICY customer_order_items_insert ON order_items
  FOR INSERT TO authenticated
  WITH CHECK (order_id::text IN (SELECT id::text FROM service_orders WHERE user_id::text = auth.uid()::text));

DROP POLICY IF EXISTS store_admin_order_items_insert ON order_items;
CREATE POLICY store_admin_order_items_insert ON order_items
  FOR INSERT TO authenticated
  WITH CHECK (order_id::text IN (SELECT id::text FROM service_orders WHERE store_id::text IN (SELECT store_id::text FROM store_admins WHERE id::text = auth.uid()::text)));

-- ─── 2. MISSING SELECT POLICY: reviews (store_admin) ───

DROP POLICY IF EXISTS store_admin_reviews_select ON reviews;
CREATE POLICY store_admin_reviews_select ON reviews
  FOR SELECT TO authenticated
  USING (store_id::text IN (SELECT store_id::text FROM store_admins WHERE id::text = auth.uid()::text));

-- ─── 3. MISSING POLICIES: coupons INSERT/UPDATE ───

DROP POLICY IF EXISTS customer_coupons_insert ON coupons;
CREATE POLICY customer_coupons_insert ON coupons
  FOR INSERT TO authenticated
  WITH CHECK (user_id::text = auth.uid()::text);

DROP POLICY IF EXISTS customer_coupons_update ON coupons;
CREATE POLICY customer_coupons_update ON coupons
  FOR UPDATE TO authenticated
  USING (user_id::text = auth.uid()::text);

-- ─── 4. MISSING PLATFORM_ADMIN POLICIES ───

DROP POLICY IF EXISTS platform_admin_notifications ON notifications;
CREATE POLICY platform_admin_notifications ON notifications
  FOR ALL TO authenticated
  USING (EXISTS (SELECT 1 FROM platform_admins WHERE id::text = auth.uid()::text));

DROP POLICY IF EXISTS platform_admin_failed_notifications ON failed_notifications;
CREATE POLICY platform_admin_failed_notifications ON failed_notifications
  FOR SELECT TO authenticated
  USING (EXISTS (SELECT 1 FROM platform_admins WHERE id::text = auth.uid()::text));

DROP POLICY IF EXISTS platform_admin_store_applications ON store_applications;
CREATE POLICY platform_admin_store_applications ON store_applications
  FOR ALL TO authenticated
  USING (EXISTS (SELECT 1 FROM platform_admins WHERE id::text = auth.uid()::text));

-- Ensure RLS is enabled on store_applications (was missing from 001_init.sql)
ALTER TABLE store_applications ENABLE ROW LEVEL SECURITY;

-- ─── 5. MISSING CHECK CONSTRAINTS ───

ALTER TABLE payments ADD CONSTRAINT payments_amount_pos CHECK (amount > 0);
ALTER TABLE spareparts ADD CONSTRAINT spareparts_price_pos CHECK (price > 0);
ALTER TABLE stores ADD CONSTRAINT stores_rating_range CHECK (rating_avg >= 0 AND rating_avg <= 5);
ALTER TABLE stores ADD CONSTRAINT stores_penalty_points_nonneg CHECK (penalty_points >= 0);
ALTER TABLE stores ADD CONSTRAINT stores_total_completed_nonneg CHECK (total_completed >= 0);
ALTER TABLE service_orders ADD CONSTRAINT sla_breach_count_nonneg CHECK (sla_breach_count >= 0);

-- ─── 6. MISSING INDEXES ───

CREATE INDEX IF NOT EXISTS idx_order_items_order ON order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_order_items_sparepart ON order_items(sparepart_id);
CREATE INDEX IF NOT EXISTS idx_payments_user ON payments(user_id);
CREATE INDEX IF NOT EXISTS idx_reviews_user ON reviews(user_id);
CREATE INDEX IF NOT EXISTS idx_shipments_order ON shipments(order_id);
CREATE INDEX IF NOT EXISTS idx_user_sessions_user ON user_sessions(user_id);

-- ─── 7. MISSING UNIQUE CONSTRAINTS ───

ALTER TABLE store_applications ADD CONSTRAINT store_applications_phone_unique UNIQUE (phone_number);
ALTER TABLE stores ADD CONSTRAINT stores_phone_unique UNIQUE (phone_number);
