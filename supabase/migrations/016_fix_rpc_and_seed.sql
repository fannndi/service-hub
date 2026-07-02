-- Fix stock RPC functions — parameter type TEXT (kolom spareparts.id adalah TEXT dari Prisma)
CREATE OR REPLACE FUNCTION reserve_stock(p_sparepart_id TEXT, p_qty INT DEFAULT 1)
RETURNS BOOLEAN LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
DECLARE v_available INT;
BEGIN
  SELECT qty - qty_reserved INTO v_available FROM public.spareparts WHERE id = p_sparepart_id FOR UPDATE;
  IF v_available >= p_qty THEN
    UPDATE public.spareparts SET qty_reserved = qty_reserved + p_qty, updated_at = now() WHERE id = p_sparepart_id;
    RETURN TRUE;
  END IF;
  RETURN FALSE;
END;
$$;

CREATE OR REPLACE FUNCTION consume_stock(p_sparepart_id TEXT)
RETURNS BOOLEAN LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
BEGIN
  UPDATE public.spareparts SET qty = qty - 1, qty_reserved = qty_reserved - 1, updated_at = now()
  WHERE id = p_sparepart_id AND qty_reserved > 0;
  RETURN FOUND;
END;
$$;

CREATE OR REPLACE FUNCTION release_stock(p_sparepart_id TEXT)
RETURNS BOOLEAN LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
BEGIN
  UPDATE public.spareparts SET qty_reserved = GREATEST(qty_reserved - 1, 0), updated_at = now()
  WHERE id = p_sparepart_id;
  RETURN FOUND;
END;
$$;

CREATE OR REPLACE FUNCTION swap_sparepart(p_old_id TEXT, p_new_id TEXT)
RETURNS BOOLEAN LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
BEGIN
  UPDATE public.spareparts SET qty_reserved = GREATEST(qty_reserved - 1, 0), updated_at = now() WHERE id = p_old_id;
  UPDATE public.spareparts SET qty_reserved = qty_reserved + 1, updated_at = now() WHERE id = p_new_id;
  RETURN TRUE;
END;
$$;

-- ⚠️ HOW TO APPLY:
-- 1. Open https://supabase.com/dashboard/project/eboplbemgtvmviwhdlfa/sql/new
-- 2. Run the SQL below
-- =============================================

-- Seed test users
-- Customer: testcustomer@customer.servisgadget.com / test123456
-- Store Admin (TechFix): 6281111111@store.servisgadget.com / admin123

-- Create test customer via Supabase Auth (alternative: run from dashboard)
-- SELECT supabase_admin.create_user(...) -- or create via Auth UI

-- =============================================
-- QUICK START (copy and paste this entire file to Supabase SQL Editor)
-- =============================================
