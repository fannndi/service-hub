-- =============================================
-- Migration 013: Add missing tables (shipments, user_sessions)
-- Fix: Add credential_plain_enc column
-- Fix: Add missing indexes
-- =============================================

-- 1. SHIPMENTS table (was in Prisma, missing in Supabase)
CREATE TABLE IF NOT EXISTS shipments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES service_orders(id) ON DELETE CASCADE,
  shipment_type VARCHAR(20) NOT NULL DEFAULT 'pickup',
  courier_name VARCHAR(80),
  tracking_number VARCHAR(100) UNIQUE,
  pickup_address TEXT NOT NULL,
  destination_address TEXT NOT NULL,
  status VARCHAR(20) NOT NULL DEFAULT 'scheduled',
  scheduled_at TIMESTAMPTZ,
  delivered_at TIMESTAMPTZ,
  shipping_fee DECIMAL(12,2) NOT NULL DEFAULT 0,
  fee_bearer VARCHAR(20) NOT NULL DEFAULT 'customer',
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE shipments ENABLE ROW LEVEL SECURITY;

-- Shipment policies
CREATE POLICY shipments_owner_select ON shipments
  FOR SELECT TO authenticated
  USING (
    order_id IN (SELECT id FROM service_orders WHERE user_id = auth.uid())
  );
CREATE POLICY shipments_store_admin_select ON shipments
  FOR SELECT TO authenticated
  USING (
    order_id IN (SELECT id FROM service_orders WHERE store_id IN (
      SELECT store_id FROM store_admins WHERE id = auth.uid()
    ))
  );

-- 2. USER_SESSIONS table (was in Prisma, missing in Supabase)
CREATE TABLE IF NOT EXISTS user_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token_hash VARCHAR(64) UNIQUE NOT NULL,
  ip_address VARCHAR(45),
  is_active BOOLEAN NOT NULL DEFAULT true,
  expires_at TIMESTAMPTZ NOT NULL,
  last_active_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE user_sessions ENABLE ROW LEVEL SECURITY;

CREATE POLICY user_sessions_owner ON user_sessions
  FOR ALL TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- 3. Add credential_plain_enc column to users
ALTER TABLE users ADD COLUMN IF NOT EXISTS credential_plain_enc TEXT;

-- 4. Add missing indexes for frequent queries
CREATE INDEX IF NOT EXISTS idx_disputes_store_status ON disputes(store_id, status);
CREATE INDEX IF NOT EXISTS idx_disputes_user ON disputes(user_id);
CREATE INDEX IF NOT EXISTS idx_reviews_store ON reviews(store_id);
CREATE INDEX IF NOT EXISTS idx_coupons_code ON coupons(code);
CREATE INDEX IF NOT EXISTS idx_coupons_user ON coupons(user_id);
CREATE INDEX IF NOT EXISTS idx_store_applications_status ON store_applications(status, applied_at);
CREATE INDEX IF NOT EXISTS idx_store_applications_phone ON store_applications(phone_number);
CREATE INDEX IF NOT EXISTS idx_payments_status ON payments(status);
CREATE INDEX IF NOT EXISTS idx_spareparts_store_status ON spareparts(store_id, status);

-- 5. Fix RLS: failed_notifications needs INSERT policy
DROP POLICY IF EXISTS failed_notifications_insert ON failed_notifications;
CREATE POLICY failed_notifications_insert ON failed_notifications
  FOR INSERT TO authenticated
  WITH CHECK (true);

-- 6. Fix RLS: store_applications needs RLS enabled + policies
DROP POLICY IF EXISTS store_applications_insert ON store_applications;
CREATE POLICY store_applications_insert ON store_applications
  FOR INSERT TO anon, authenticated
  WITH CHECK (true);
CREATE POLICY store_applications_select ON store_applications
  FOR SELECT TO authenticated
  USING (true);
