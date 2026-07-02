#!/usr/bin/env bash
# Service Hub — Fix RPC + Migration + Deploy Functions
# Jalankan dari root project service-hub
set -euo pipefail

FLAGS="--linked --debug"

echo "╔═══════════════════════════════════════╗"
echo "║  Service Hub — DB Fix + Deploy        ║"
echo "╚═══════════════════════════════════════╝"
echo ""

# ─── Step 1: Fix RPC (TEXT params) ───
echo "━━━ [1/6] Fix RPC functions (TEXT params) ━━━"
supabase db query $FLAGS < supabase/migrations/016_fix_rpc_and_seed.sql
echo "  ✅ RPC functions fixed"
echo ""

# ─── Step 2: Midtrans enum ───
echo "━━━ [2/6] Add midtrans enum ━━━"
supabase db query $FLAGS --command "ALTER TYPE \"PaymentMethod\" ADD VALUE IF NOT EXISTS 'midtrans';"
echo "  ✅ Enum PaymentMethod + midtrans"
echo ""

# ─── Step 3: Midtrans columns ───
echo "━━━ [3/6] Add midtrans columns ━━━"
supabase db query $FLAGS --command "ALTER TABLE payments ADD COLUMN IF NOT EXISTS midtrans_order_id TEXT;"
supabase db query $FLAGS --command "ALTER TABLE payments ADD COLUMN IF NOT EXISTS midtrans_transaction_id TEXT;"
supabase db query $FLAGS --command "ALTER TABLE payments ADD COLUMN IF NOT EXISTS midtrans_payment_type TEXT;"
supabase db query $FLAGS --command "CREATE INDEX IF NOT EXISTS idx_payments_midtrans_tx ON payments(midtrans_transaction_id);"
echo "  ✅ Midtrans columns added"
echo ""

# ─── Step 4: get_home_summary function ───
echo "━━━ [4/6] Create get_home_summary function ━━━"
supabase db query $FLAGS --command "$(cat <<'SQLEOF'
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
)"
echo "  ✅ get_home_summary created"
echo ""

# ─── Step 5: Deploy guest (no JWT) ───
echo "━━━ [5/6] Deploy guest function (no JWT) ━━━"
supabase functions deploy guest --no-verify-jwt --debug
echo "  ✅ Guest function deployed"
echo ""

# ─── Step 6: Deploy all functions ───
echo "━━━ [6/6] Deploy all Edge Functions ━━━"
for fn in orders payments midtrans disputes reviews notifications admin store-applications cron-sla seed-admin; do
  echo "  Deploying $fn..."
  supabase functions deploy "$fn" --debug 2>&1 | tail -2
done
echo ""

echo "╔═══════════════════════════════════════╗"
echo "║  ✅ ALL DONE!                        ║"
echo "║  RPC fixed, Midtrans added,          ║"
echo "║  Functions deployed                   ║"
echo "╚═══════════════════════════════════════╝"
