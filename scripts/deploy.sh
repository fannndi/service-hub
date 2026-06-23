#!/usr/bin/env bash
# ============================================
# ServisGadget — Full Deploy ke Supabase
# ============================================
# Cara pakai:
#   1. Buka link ini → buat access token sbp_xxx
#      https://supabase.com/dashboard/account/tokens
#
#   2. Jalankan:
#      SUPABASE_ACCESS_TOKEN=sbp_xxx bash scripts/deploy.sh
#
#   NOTE untuk Windows: jalankan dari WSL atau Git Bash.
#   Alternatif: jalankan perintah PER STEP manual (ada di setiap step).
# ============================================

set -e

echo ""
echo "============================================"
echo "  ServisGadget Deploy"
echo "============================================"
echo ""
echo "Project: eboplbemgtvmviwhdlfa"
echo ""

# ── STEP 1: SQL Migrations ──────────────────────────────────
echo "━━━ STEP 1/4: Push SQL Migrations ━━━"
echo ""
echo "Via API:"
echo "  node scripts/push-sql.js"
echo ""
echo "Via SQL Editor (alternatif browser):"
echo "  https://supabase.com/dashboard/project/eboplbemgtvmviwhdlfa/sql/new"
echo ""
echo "Copy-paste file ini (urutan):"
echo "  1. supabase/migrations/001_init.sql"
echo "  2. supabase/migrations/002_rls.sql"
echo "  3. supabase/migrations/003_functions.sql"
echo "  4. supabase/migrations/004_seed.sql"
echo ""

if [ -n "$SUPABASE_ACCESS_TOKEN" ]; then
  echo "SUPABASE_ACCESS_TOKEN ditemukan — push SQL..."
  node "$(dirname "$0")/push-sql.js"
  echo "SQL OK"
else
  echo "SKIP — export SUPABASE_ACCESS_TOKEN dulu, atau via SQL Editor manual."
fi

# ── STEP 2: Link Project ─────────────────────────────────────
echo ""
echo "━━━ STEP 2/4: Link Supabase Project ━━━"
echo ""
echo "  npx supabase link --project-ref eboplbemgtvmviwhdlfa"
echo ""

# ── STEP 3: Deploy Edge Functions ───────────────────────────
echo ""
echo "━━━ STEP 3/4: Deploy Edge Functions ━━━"
echo ""
echo "  npx supabase functions deploy orders"
echo "  npx supabase functions deploy payments"
echo "  npx supabase functions deploy disputes"
echo "  npx supabase functions deploy admin"
echo "  npx supabase functions deploy cron-sla"
echo ""

# ── STEP 4: Build APK ────────────────────────────────────────
echo ""
echo "━━━ STEP 4/4: Build APK ─━━"
echo ""
echo "  cd frontend"
echo '  flutter build apk --release \'
echo '    --dart-define=SUPABASE_URL=https://eboplbemgtvmviwhdlfa.supabase.co \'
echo '    --dart-define=SUPABASE_ANON_KEY=sb_publishable_sLbPJCOjGT9GRGZBosGlsQ_4cpeOMRV'
echo ""
echo "Output: frontend/build/app/outputs/flutter-apk/app-release.apk"
echo ""

echo "============================================"
echo "  DONE — App ready untuk di-share!"
echo "============================================"
