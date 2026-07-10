-- 001_init.sql — FULL SCHEMA MIGRATION
-- Prisma schema → PostgreSQL DDL
-- ServiceHub v2.0 → Supabase

-- ─── EXTENSIONS ───
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ─── ENUMS ───
CREATE TYPE account_status AS ENUM ('active', 'suspended', 'deleted');
CREATE TYPE device_type AS ENUM ('android', 'ios');
CREATE TYPE delivery_method AS ENUM ('walk_in', 'courier_pickup');
CREATE TYPE order_status AS ENUM ('waiting_device', 'device_received', 'diagnosing', 'waiting_approval', 'waiting_sparepart', 'repairing', 'quality_check', 'waiting_payment', 'completed', 'cancelled', 'disputed');
CREATE TYPE payment_status AS ENUM ('unpaid', 'partially_paid', 'paid', 'refunded');
CREATE TYPE payment_method AS ENUM ('transfer_bank', 'qris', 'cash', 'ewallet');
CREATE TYPE payment_type AS ENUM ('deposit', 'final_payment', 'refund');
CREATE TYPE payment_record_status AS ENUM ('pending', 'confirmed', 'failed', 'refunded');
CREATE TYPE sparepart_status AS ENUM ('available', 'preorder', 'discontinued');
CREATE TYPE order_item_status AS ENUM ('pending', 'confirmed', 'replaced', 'cancelled');
CREATE TYPE dispute_type AS ENUM ('warranty_claim', 'service_quality', 'wrong_diagnosis', 'other');
CREATE TYPE dispute_status AS ENUM ('open', 'store_accepted', 'store_rejected', 'escalated', 'resolved', 'closed');
CREATE TYPE created_by_type AS ENUM ('customer', 'store_admin', 'system');
CREATE TYPE application_status AS ENUM ('pending', 'approved', 'rejected');

-- ─── USERS (Pelanggan) ───
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  full_name VARCHAR(150) NOT NULL,
  phone_number VARCHAR(20) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  avatar_url VARCHAR(255),
  address TEXT,
  account_status account_status NOT NULL DEFAULT 'active',
  is_first_login BOOLEAN NOT NULL DEFAULT true,
  is_credential_sent BOOLEAN NOT NULL DEFAULT false,
  login_attempt_count SMALLINT NOT NULL DEFAULT 0,
  locked_until TIMESTAMPTZ,
  last_login_at TIMESTAMPTZ,
  password_changed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ─── STORES ───
CREATE TABLE stores (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  store_name VARCHAR(150) NOT NULL,
  address TEXT NOT NULL,
  phone_number VARCHAR(20) NOT NULL,
  operational_hours JSONB NOT NULL DEFAULT '{}',
  config JSONB NOT NULL DEFAULT '{}',
  is_active BOOLEAN NOT NULL DEFAULT false,
  rating_avg NUMERIC(3,2) NOT NULL DEFAULT 0,
  total_completed INT NOT NULL DEFAULT 0,
  penalty_points INT NOT NULL DEFAULT 0,
  verified_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ─── STORE ADMINS ───
CREATE TABLE store_admins (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id UUID NOT NULL REFERENCES stores(id),
  full_name VARCHAR(150) NOT NULL,
  phone_number VARCHAR(20) NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT true,
  is_first_login BOOLEAN NOT NULL DEFAULT false,
  last_login_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(store_id, phone_number)
);

-- ─── STORE APPLICATIONS ───
CREATE TABLE store_applications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  store_name VARCHAR(150) NOT NULL,
  applicant_name VARCHAR(150) NOT NULL,
  phone_number VARCHAR(20) NOT NULL,
  address TEXT NOT NULL,
  business_license_url VARCHAR(255),
  id_card_url VARCHAR(255) NOT NULL,
  status application_status NOT NULL DEFAULT 'pending',
  reviewed_by VARCHAR(255),
  review_note TEXT,
  applied_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  reviewed_at TIMESTAMPTZ
);

-- ─── SPAREPARTS ───
CREATE TABLE spareparts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id UUID NOT NULL REFERENCES stores(id),
  brand VARCHAR(80) NOT NULL,
  device_model VARCHAR(100) NOT NULL,
  part_type VARCHAR(60) NOT NULL,
  part_name VARCHAR(150) NOT NULL,
  price INT NOT NULL,
  qty INT NOT NULL DEFAULT 0,
  qty_reserved INT NOT NULL DEFAULT 0,
  status sparepart_status NOT NULL DEFAULT 'available',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_spareparts_store ON spareparts(store_id);
CREATE INDEX idx_spareparts_brand ON spareparts(brand, device_model, part_type);

-- ─── SERVICE ORDERS ───
CREATE TABLE service_orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id),
  store_id UUID NOT NULL REFERENCES stores(id),
  order_number VARCHAR(30) NOT NULL UNIQUE,
  device_type device_type NOT NULL,
  brand VARCHAR(80) NOT NULL,
  device_model VARCHAR(100) NOT NULL,
  delivery_method delivery_method NOT NULL,
  delivery_address TEXT,
  status order_status NOT NULL DEFAULT 'waiting_device',
  payment_status payment_status NOT NULL DEFAULT 'unpaid',
  total_estimasi INT NOT NULL DEFAULT 0,
  discount_amount INT NOT NULL DEFAULT 0,
  final_price INT,
  service_fee INT,
  diagnosis_note TEXT,
  warranty_days INT,
  warranty_expired_at TIMESTAMPTZ,
  sla_deadline TIMESTAMPTZ,
  sla_warned_at TIMESTAMPTZ,
  sla_breach_count SMALLINT NOT NULL DEFAULT 0,
  coupon_id UUID UNIQUE,
  is_warranty_order BOOLEAN NOT NULL DEFAULT false,
  parent_order_id VARCHAR(255),
  completed_at TIMESTAMPTZ,
  cancelled_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_orders_user ON service_orders(user_id);
CREATE INDEX idx_orders_store ON service_orders(store_id);
CREATE INDEX idx_orders_status ON service_orders(status);
CREATE INDEX idx_orders_created ON service_orders(created_at);

-- ─── ORDER ITEMS ───
CREATE TABLE order_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES service_orders(id) ON DELETE CASCADE,
  sparepart_id UUID REFERENCES spareparts(id),
  service_type VARCHAR(100) NOT NULL,
  complaint TEXT NOT NULL,
  item_price INT NOT NULL,
  final_item_price INT,
  status order_item_status NOT NULL DEFAULT 'pending',
  technician_note TEXT
);

-- ─── SERVICE TRACKING ───
CREATE TABLE service_tracking (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES service_orders(id),
  status order_status NOT NULL,
  note TEXT,
  created_by_type created_by_type NOT NULL,
  created_by_id VARCHAR(255) NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_tracking_order ON service_tracking(order_id);

-- ─── PAYMENTS ───
CREATE TABLE payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES service_orders(id),
  user_id UUID NOT NULL REFERENCES users(id),
  amount INT NOT NULL,
  payment_method payment_method NOT NULL,
  payment_type payment_type NOT NULL,
  status payment_record_status NOT NULL DEFAULT 'pending',
  proof_url VARCHAR(255),
  confirmed_by VARCHAR(255),
  confirmed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_payments_order ON payments(order_id);

-- ─── REVIEWS ───
CREATE TABLE reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL UNIQUE REFERENCES service_orders(id),
  user_id UUID NOT NULL REFERENCES users(id),
  store_id UUID NOT NULL REFERENCES stores(id),
  rating SMALLINT NOT NULL CHECK (rating >= 1 AND rating <= 5),
  comment TEXT,
  is_public BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ─── COUPONS ───
CREATE TABLE coupons (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id),
  review_id UUID NOT NULL UNIQUE REFERENCES reviews(id),
  code VARCHAR(20) NOT NULL UNIQUE,
  amount INT NOT NULL DEFAULT 10000,
  is_used BOOLEAN NOT NULL DEFAULT false,
  used_at TIMESTAMPTZ,
  used_on_order_id UUID UNIQUE REFERENCES service_orders(id),
  expired_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_coupons_user ON coupons(user_id);

-- ─── DISPUTES ───
CREATE TABLE disputes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL UNIQUE REFERENCES service_orders(id),
  user_id UUID NOT NULL REFERENCES users(id),
  store_id UUID NOT NULL REFERENCES stores(id),
  dispute_type dispute_type NOT NULL,
  description TEXT NOT NULL,
  evidence_urls JSONB NOT NULL DEFAULT '[]',
  status dispute_status NOT NULL DEFAULT 'open',
  store_response TEXT,
  platform_decision TEXT,
  resolution TEXT,
  warranty_order_id UUID,
  resolved_at TIMESTAMPTZ,
  sla_deadline TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ─── FAILED NOTIFICATIONS ───
CREATE TABLE failed_notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  recipient_type VARCHAR(20) NOT NULL,
  recipient_id VARCHAR(255) NOT NULL,
  channel VARCHAR(20) NOT NULL DEFAULT 'whatsapp',
  message_type VARCHAR(50) NOT NULL,
  payload JSONB NOT NULL,
  attempt_count SMALLINT NOT NULL DEFAULT 0,
  last_error TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ─── PLATFORM ADMINS ───
CREATE TABLE platform_admins (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  username VARCHAR(50) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  full_name VARCHAR(150) NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT true,
  last_login_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ─── ENABLE RLS ───
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE store_admins ENABLE ROW LEVEL SECURITY;
ALTER TABLE stores ENABLE ROW LEVEL SECURITY;
ALTER TABLE spareparts ENABLE ROW LEVEL SECURITY;
ALTER TABLE service_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE service_tracking ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE coupons ENABLE ROW LEVEL SECURITY;
ALTER TABLE disputes ENABLE ROW LEVEL SECURITY;
ALTER TABLE failed_notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE platform_admins ENABLE ROW LEVEL SECURITY;
