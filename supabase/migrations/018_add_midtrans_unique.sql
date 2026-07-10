-- 018_add_midtrans_unique.sql
-- Add unique constraint on midtrans_transaction_id to prevent duplicate payments
ALTER TABLE payments ADD COLUMN IF NOT EXISTS midtrans_transaction_id VARCHAR(255);
ALTER TABLE payments ADD COLUMN IF NOT EXISTS midtrans_order_id VARCHAR(255);
ALTER TABLE payments ADD COLUMN IF NOT EXISTS midtrans_payment_type VARCHAR(50);
CREATE UNIQUE INDEX IF NOT EXISTS idx_payments_midtrans_txn ON payments(midtrans_transaction_id) WHERE midtrans_transaction_id IS NOT NULL;

-- Fix RLS for store_applications (was missing in 013)
ALTER TABLE IF EXISTS store_applications ENABLE ROW LEVEL SECURITY;

-- Add missing indexes for common queries
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email) WHERE email IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_stores_is_active ON stores(is_active);
CREATE INDEX IF NOT EXISTS idx_store_admins_store_id ON store_admins(store_id);
