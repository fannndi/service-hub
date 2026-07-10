-- 002_rls.sql — ROW LEVEL SECURITY POLICIES
-- Anon, Customer, Store Admin, Platform Admin

-- ─── ANON ───
DROP POLICY IF EXISTS anon_stores_select ON stores;
CREATE POLICY anon_stores_select ON stores FOR SELECT TO anon USING (is_active = true);

DROP POLICY IF EXISTS anon_spareparts_select ON spareparts;
CREATE POLICY anon_spareparts_select ON spareparts FOR SELECT TO anon USING (status = 'available');

DROP POLICY IF EXISTS anon_reviews_select ON reviews;
CREATE POLICY anon_reviews_select ON reviews FOR SELECT TO anon USING (is_public = true);

-- ─── CUSTOMER ───
DROP POLICY IF EXISTS customer_users_select ON users;
CREATE POLICY customer_users_select ON users FOR SELECT TO authenticated USING (id = auth.uid());

DROP POLICY IF EXISTS customer_users_update ON users;
CREATE POLICY customer_users_update ON users FOR UPDATE TO authenticated USING (id = auth.uid());

DROP POLICY IF EXISTS customer_orders_select ON service_orders;
CREATE POLICY customer_orders_select ON service_orders FOR SELECT TO authenticated USING (user_id = auth.uid());

DROP POLICY IF EXISTS customer_orders_insert ON service_orders;
CREATE POLICY customer_orders_insert ON service_orders FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS customer_order_items_select ON order_items;
CREATE POLICY customer_order_items_select ON order_items FOR SELECT TO authenticated USING (order_id IN (SELECT id FROM service_orders WHERE user_id = auth.uid()));

DROP POLICY IF EXISTS customer_payments_select ON payments;
CREATE POLICY customer_payments_select ON payments FOR SELECT TO authenticated USING (user_id = auth.uid());

DROP POLICY IF EXISTS customer_payments_insert ON payments;
CREATE POLICY customer_payments_insert ON payments FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS customer_tracking_select ON service_tracking;
CREATE POLICY customer_tracking_select ON service_tracking FOR SELECT TO authenticated USING (order_id IN (SELECT id FROM service_orders WHERE user_id = auth.uid()));

DROP POLICY IF EXISTS customer_reviews_select ON reviews;
CREATE POLICY customer_reviews_select ON reviews FOR SELECT TO authenticated USING (user_id = auth.uid());

DROP POLICY IF EXISTS customer_reviews_insert ON reviews;
CREATE POLICY customer_reviews_insert ON reviews FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS customer_coupons_select ON coupons;
CREATE POLICY customer_coupons_select ON coupons FOR SELECT TO authenticated USING (user_id = auth.uid());

DROP POLICY IF EXISTS customer_disputes_select ON disputes;
CREATE POLICY customer_disputes_select ON disputes FOR SELECT TO authenticated USING (user_id = auth.uid());

DROP POLICY IF EXISTS customer_disputes_insert ON disputes;
CREATE POLICY customer_disputes_insert ON disputes FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS customer_stores_select ON stores;
CREATE POLICY customer_stores_select ON stores FOR SELECT TO authenticated USING (is_active = true);

DROP POLICY IF EXISTS customer_spareparts_select ON spareparts;
CREATE POLICY customer_spareparts_select ON spareparts FOR SELECT TO authenticated USING (status = 'available');

-- ─── STORE ADMIN ───
DROP POLICY IF EXISTS store_admin_stores_select ON stores;
CREATE POLICY store_admin_stores_select ON stores FOR SELECT TO authenticated USING (id IN (SELECT store_id FROM store_admins WHERE id = auth.uid() AND is_active = true));

DROP POLICY IF EXISTS store_admin_stores_update ON stores;
CREATE POLICY store_admin_stores_update ON stores FOR UPDATE TO authenticated USING (id IN (SELECT store_id FROM store_admins WHERE id = auth.uid() AND is_active = true));

DROP POLICY IF EXISTS store_admin_spareparts_select ON spareparts;
CREATE POLICY store_admin_spareparts_select ON spareparts FOR SELECT TO authenticated USING (store_id IN (SELECT store_id FROM store_admins WHERE id = auth.uid() AND is_active = true));

DROP POLICY IF EXISTS store_admin_spareparts_insert ON spareparts;
CREATE POLICY store_admin_spareparts_insert ON spareparts FOR INSERT TO authenticated WITH CHECK (store_id IN (SELECT store_id FROM store_admins WHERE id = auth.uid() AND is_active = true));

DROP POLICY IF EXISTS store_admin_spareparts_update ON spareparts;
CREATE POLICY store_admin_spareparts_update ON spareparts FOR UPDATE TO authenticated USING (store_id IN (SELECT store_id FROM store_admins WHERE id = auth.uid() AND is_active = true));

DROP POLICY IF EXISTS store_admin_orders_select ON service_orders;
CREATE POLICY store_admin_orders_select ON service_orders FOR SELECT TO authenticated USING (store_id IN (SELECT store_id FROM store_admins WHERE id = auth.uid() AND is_active = true));

DROP POLICY IF EXISTS store_admin_orders_update ON service_orders;
CREATE POLICY store_admin_orders_update ON service_orders FOR UPDATE TO authenticated USING (store_id IN (SELECT store_id FROM store_admins WHERE id = auth.uid() AND is_active = true));

DROP POLICY IF EXISTS store_admin_order_items_select ON order_items;
CREATE POLICY store_admin_order_items_select ON order_items FOR SELECT TO authenticated USING (order_id IN (SELECT id FROM service_orders WHERE store_id IN (SELECT store_id FROM store_admins WHERE id = auth.uid() AND is_active = true)));

DROP POLICY IF EXISTS store_admin_order_items_update ON order_items;
CREATE POLICY store_admin_order_items_update ON order_items FOR UPDATE TO authenticated USING (order_id IN (SELECT id FROM service_orders WHERE store_id IN (SELECT store_id FROM store_admins WHERE id = auth.uid() AND is_active = true)));

DROP POLICY IF EXISTS store_admin_tracking_select ON service_tracking;
CREATE POLICY store_admin_tracking_select ON service_tracking FOR SELECT TO authenticated USING (order_id IN (SELECT id FROM service_orders WHERE store_id IN (SELECT store_id FROM store_admins WHERE id = auth.uid() AND is_active = true)));

DROP POLICY IF EXISTS store_admin_tracking_insert ON service_tracking;
CREATE POLICY store_admin_tracking_insert ON service_tracking FOR INSERT TO authenticated WITH CHECK (order_id IN (SELECT id FROM service_orders WHERE store_id IN (SELECT store_id FROM store_admins WHERE id = auth.uid() AND is_active = true)));

DROP POLICY IF EXISTS store_admin_payments_select ON payments;
CREATE POLICY store_admin_payments_select ON payments FOR SELECT TO authenticated USING (order_id IN (SELECT id FROM service_orders WHERE store_id IN (SELECT store_id FROM store_admins WHERE id = auth.uid() AND is_active = true)));

DROP POLICY IF EXISTS store_admin_payments_update ON payments;
CREATE POLICY store_admin_payments_update ON payments FOR UPDATE TO authenticated USING (order_id IN (SELECT id FROM service_orders WHERE store_id IN (SELECT store_id FROM store_admins WHERE id = auth.uid() AND is_active = true)));

DROP POLICY IF EXISTS store_admin_disputes_select ON disputes;
CREATE POLICY store_admin_disputes_select ON disputes FOR SELECT TO authenticated USING (store_id IN (SELECT store_id FROM store_admins WHERE id = auth.uid() AND is_active = true));

DROP POLICY IF EXISTS store_admin_disputes_update ON disputes;
CREATE POLICY store_admin_disputes_update ON disputes FOR UPDATE TO authenticated USING (store_id IN (SELECT store_id FROM store_admins WHERE id = auth.uid() AND is_active = true));

-- ─── PLATFORM ADMIN ───
DROP POLICY IF EXISTS platform_admin_all ON stores;
CREATE POLICY platform_admin_all ON stores FOR ALL TO authenticated USING (EXISTS (SELECT 1 FROM platform_admins WHERE id = auth.uid() AND is_active = true));

DROP POLICY IF EXISTS platform_admin_users ON users;
CREATE POLICY platform_admin_users ON users FOR ALL TO authenticated USING (EXISTS (SELECT 1 FROM platform_admins WHERE id = auth.uid() AND is_active = true));

DROP POLICY IF EXISTS platform_admin_store_admins ON store_admins;
CREATE POLICY platform_admin_store_admins ON store_admins FOR ALL TO authenticated USING (EXISTS (SELECT 1 FROM platform_admins WHERE id = auth.uid() AND is_active = true));

DROP POLICY IF EXISTS platform_admin_orders ON service_orders;
CREATE POLICY platform_admin_orders ON service_orders FOR ALL TO authenticated USING (EXISTS (SELECT 1 FROM platform_admins WHERE id = auth.uid() AND is_active = true));

DROP POLICY IF EXISTS platform_admin_spareparts ON spareparts;
CREATE POLICY platform_admin_spareparts ON spareparts FOR ALL TO authenticated USING (EXISTS (SELECT 1 FROM platform_admins WHERE id = auth.uid() AND is_active = true));

DROP POLICY IF EXISTS platform_admin_payments ON payments;
CREATE POLICY platform_admin_payments ON payments FOR ALL TO authenticated USING (EXISTS (SELECT 1 FROM platform_admins WHERE id = auth.uid() AND is_active = true));

DROP POLICY IF EXISTS platform_admin_reviews ON reviews;
CREATE POLICY platform_admin_reviews ON reviews FOR ALL TO authenticated USING (EXISTS (SELECT 1 FROM platform_admins WHERE id = auth.uid() AND is_active = true));

DROP POLICY IF EXISTS platform_admin_disputes ON disputes;
CREATE POLICY platform_admin_disputes ON disputes FOR ALL TO authenticated USING (EXISTS (SELECT 1 FROM platform_admins WHERE id = auth.uid() AND is_active = true));

DROP POLICY IF EXISTS platform_admin_tracking ON service_tracking;
CREATE POLICY platform_admin_tracking ON service_tracking FOR ALL TO authenticated USING (EXISTS (SELECT 1 FROM platform_admins WHERE id = auth.uid() AND is_active = true));

DROP POLICY IF EXISTS platform_admin_coupons ON coupons;
CREATE POLICY platform_admin_coupons ON coupons FOR ALL TO authenticated USING (EXISTS (SELECT 1 FROM platform_admins WHERE id = auth.uid() AND is_active = true));

DROP POLICY IF EXISTS platform_admin_order_items ON order_items;
CREATE POLICY platform_admin_order_items ON order_items FOR ALL TO authenticated USING (EXISTS (SELECT 1 FROM platform_admins WHERE id = auth.uid() AND is_active = true));

DROP POLICY IF EXISTS platform_admin_platform_admins ON platform_admins;
CREATE POLICY platform_admin_platform_admins ON platform_admins FOR ALL TO authenticated USING (EXISTS (SELECT 1 FROM platform_admins WHERE id = auth.uid() AND is_active = true));
