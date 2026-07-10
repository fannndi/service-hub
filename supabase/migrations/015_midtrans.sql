-- Midtrans payment support
-- Add 'midtrans' to payment_method enum (lowercase untuk schema dari 001_init.sql)
ALTER TYPE payment_method ADD VALUE IF NOT EXISTS 'midtrans';

-- Add Midtrans metadata columns to payments table
ALTER TABLE payments ADD COLUMN IF NOT EXISTS midtrans_order_id TEXT;
ALTER TABLE payments ADD COLUMN IF NOT EXISTS midtrans_transaction_id TEXT;
ALTER TABLE payments ADD COLUMN IF NOT EXISTS midtrans_payment_type TEXT;

-- Index for idempotency check on Midtrans notifications
CREATE INDEX IF NOT EXISTS idx_payments_midtrans_tx ON payments(midtrans_transaction_id);
