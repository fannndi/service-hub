#!/usr/bin/env bash
# ============================================
# Service Hub — Production Setup Script
# Jalankan dari komputer yang punya akses internet
# ============================================
set -e

echo "============================================"
echo "  Service Hub — Production Setup"
echo "============================================"
echo ""

# ─── 1. Cek prerequisites ───
echo "━━━ [1/5] Cek prerequisites ━━━"

if ! command -v supabase &> /dev/null; then
    echo "  ⚠️  Supabase CLI belum terinstall. Install dulu:"
    echo "     npm install -g supabase"
    echo "     Atau: brew install supabase/tap/supabase"
    exit 1
fi
echo "  ✅ Supabase CLI: $(supabase --version)"

if ! command -v node &> /dev/null; then
    echo "  ⚠️  Node.js belum terinstall"
    exit 1
fi
echo "  ✅ Node.js $(node --version)"

# ─── 2. Login Supabase ───
echo ""
echo "━━━ [2/5] Login ke Supabase ━━━"
supabase login

# ─── 3. Link project ───
echo ""
echo "━━━ [3/5] Link project ━━━"
supabase link --project-ref eboplbemgtvmviwhdlfa

# ─── 4. Push migration ───
echo ""
echo "━━━ [4/5] Push migration (fix RPC + seed) ━━━"
supabase db push

# ─── 5. Deploy Edge Functions ───
echo ""
echo "━━━ [5/5] Deploy Edge Functions ━━━"

# Guest function (tanpa JWT — bisa diakses tanpa login)
echo "  Deploying guest (no-verify-jwt)..."
supabase functions deploy guest --no-verify-jwt

# Fungsi lain (dengan JWT)
for fn in orders payments midtrans disputes reviews notifications admin store-applications cron-sla; do
    echo "  Deploying $fn..."
    supabase functions deploy "$fn"
done

echo ""
echo "============================================"
echo "  ✅ SETUP COMPLETE"
echo "============================================"
echo ""
echo "  RPC functions fixed: reserve_stock, consume_stock, release_stock, swap_sparepart"
echo "  Guest function: no-verify-jwt ✅"
echo "  All Edge Functions deployed ✅"
echo ""
echo "  Next: Build APK"
echo "    cd frontend"
echo '    flutter build apk --release --dart-define=SUPABASE_URL=$SUPABASE_URL --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY'
echo ""
