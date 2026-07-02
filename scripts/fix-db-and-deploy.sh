#!/usr/bin/env bash
# Service Hub — Fix RPC + Migration + Deploy Functions
# Jalankan dari root project service-hub

FLAGS="--linked"

echo "╔═══════════════════════════════════════╗"
echo "║  Service Hub — DB Fix + Deploy        ║"
echo "╚═══════════════════════════════════════╝"
echo ""

# ─── Step 1: Fix RPC ───
echo "━━━ [1/6] Fix RPC functions ─━━"
supabase db query $FLAGS < supabase/migrations/016_fix_rpc_and_seed.sql
echo "  ✅ RPC functions fixed"
echo ""

# ─── Step 2: Midtrans ───
echo "━━━ [2/6] Add midtrans support ━━━"
cat > /tmp/midtrans_migration.sql << 'SQLEOF'
ALTER TYPE "PaymentMethod" ADD VALUE IF NOT EXISTS 'midtrans';
ALTER TABLE payments ADD COLUMN IF NOT EXISTS midtrans_order_id TEXT;
ALTER TABLE payments ADD COLUMN IF NOT EXISTS midtrans_transaction_id TEXT;
ALTER TABLE payments ADD COLUMN IF NOT EXISTS midtrans_payment_type TEXT;
CREATE INDEX IF NOT EXISTS idx_payments_midtrans_tx ON payments(midtrans_transaction_id);
SQLEOF
supabase db query $FLAGS < /tmp/midtrans_migration.sql
echo "  ✅ Midtrans columns added"
echo ""

# ─── Step 3: get_home_summary ───
echo "━━━ [3/6] Create get_home_summary ━━━"
cat > /tmp/home_summary.sql << 'SQLEOF'
CREATE OR REPLACE FUNCTION get_home_summary(p_user_id UUID)
RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE result JSONB;
BEGIN
  SELECT jsonb_build_object(
    'active_orders', (SELECT COUNT(*) FROM service_orders WHERE user_id = p_user_id AND status NOT IN ('completed','cancelled')),
    'active_coupons', (SELECT COUNT(*) FROM coupons WHERE user_id = p_user_id AND is_used = false),
    'active_warranties', (SELECT COUNT(*) FROM service_orders WHERE user_id = p_user_id AND warranty_expired_at > now())
  ) INTO result;
  RETURN result;
END;
$$;
SQLEOF
supabase db query $FLAGS < /tmp/home_summary.sql
echo "  ✅ get_home_summary created"
echo ""

# ─── Step 4: Deploy guest ───
echo "━━━ [4/6] Deploy guest (no JWT) ━━━"
supabase functions deploy guest --no-verify-jwt 2>&1 | tail -1
echo "  ✅ Guest deployed"
echo ""

# ─── Step 5: Deploy all ───
echo "━━━ [5/6] Deploy all functions ━━━"
for fn in orders payments midtrans disputes reviews notifications admin store-applications cron-sla seed-admin; do
  printf "  Deploying %-20s ... " "$fn"
  supabase functions deploy "$fn" 2>&1 | tail -1
done
echo ""

echo "╔═══════════════════════════════════════╗"
echo "║  ✅ ALL DONE!                        ║"
echo "╚═══════════════════════════════════════╝"
