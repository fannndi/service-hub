-- 003_functions.sql — POSTGRESQL FUNCTIONS + AUTH TRIGGER
-- All table references prefixed with public. (SET search_path TO '')

-- ─── ORDER NUMBER GENERATOR ───
CREATE OR REPLACE FUNCTION generate_order_number()
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  date_part TEXT;
  random_part TEXT;
  order_num TEXT;
BEGIN
  date_part := to_char(now(), 'YYYYMMDD');
  random_part := upper(substring(md5(random()::text) from 1 for 6));
  order_num := 'SG-' || date_part || '-' || random_part;
  RETURN order_num;
END;
$$;

-- ─── ATOMIC STOCK: Reserve ───
CREATE OR REPLACE FUNCTION reserve_stock(p_sparepart_id UUID, p_qty INT DEFAULT 1)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_available INT;
BEGIN
  SELECT qty - qty_reserved INTO v_available
  FROM public.spareparts WHERE id = p_sparepart_id FOR UPDATE;

  IF v_available >= p_qty THEN
    UPDATE public.spareparts
    SET qty_reserved = qty_reserved + p_qty,
        updated_at = now()
    WHERE id = p_sparepart_id;
    RETURN true;
  END IF;
  RETURN false;
END;
$$;

-- ─── ATOMIC STOCK: Consume (approve order) ───
CREATE OR REPLACE FUNCTION consume_stock(p_sparepart_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  UPDATE public.spareparts
  SET qty = qty - 1,
      qty_reserved = qty_reserved - 1,
      updated_at = now()
  WHERE id = p_sparepart_id AND qty_reserved > 0;

  RETURN FOUND;
END;
$$;

-- ─── ATOMIC STOCK: Release (reject/cancel order) ───
CREATE OR REPLACE FUNCTION release_stock(p_sparepart_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  UPDATE public.spareparts
  SET qty_reserved = GREATEST(qty_reserved - 1, 0),
      updated_at = now()
  WHERE id = p_sparepart_id;

  RETURN FOUND;
END;
$$;

-- ─── ATOMIC STOCK: Swap (diagnosis replace) ───
CREATE OR REPLACE FUNCTION swap_sparepart(p_old_id UUID, p_new_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  UPDATE public.spareparts
  SET qty_reserved = GREATEST(qty_reserved - 1, 0),
      updated_at = now()
  WHERE id = p_old_id;

  UPDATE public.spareparts
  SET qty_reserved = qty_reserved + 1,
      updated_at = now()
  WHERE id = p_new_id AND (qty - qty_reserved) > 0;

  RETURN FOUND;
END;
$$;

-- ─── DEVICE MODELS ───
CREATE OR REPLACE FUNCTION get_device_models()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  result JSONB;
BEGIN
  SELECT jsonb_agg(
    jsonb_build_object(
      'brand', brand,
      'models', models
    )
  ) INTO result
  FROM (
    SELECT s.brand,
           jsonb_agg(DISTINCT s.device_model ORDER BY s.device_model) AS models
    FROM public.spareparts s
    WHERE s.status = 'available'
    GROUP BY s.brand
  ) sub;

  RETURN COALESCE(result, '[]'::JSONB);
END;
$$;

-- ─── DASHBOARD SUMMARY ───
CREATE OR REPLACE FUNCTION get_dashboard_summary(p_store_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  result JSONB;
BEGIN
  SELECT jsonb_build_object(
    'store_name', st.store_name,
    'rating_avg', st.rating_avg::text,
    'active_orders', (SELECT count(*) FROM public.service_orders WHERE store_id = p_store_id AND status NOT IN ('completed', 'cancelled')),
    'pending_payments', (SELECT count(*) FROM public.payments p JOIN public.service_orders o ON p.order_id = o.id WHERE o.store_id = p_store_id AND p.status = 'pending'),
    'active_disputes', (SELECT count(*) FROM public.disputes WHERE store_id = p_store_id AND status NOT IN ('resolved', 'closed')),
    'completed_this_month', (SELECT count(*) FROM public.service_orders WHERE store_id = p_store_id AND status = 'completed' AND completed_at >= date_trunc('month', now())),
    'total_completed', st.total_completed,
    'total_customers', (SELECT count(DISTINCT user_id) FROM public.service_orders WHERE store_id = p_store_id),
    'revenue_this_month', (SELECT COALESCE(sum(final_price), 0) FROM public.service_orders WHERE store_id = p_store_id AND status = 'completed' AND completed_at >= date_trunc('month', now()))
  ) INTO result
  FROM public.stores st WHERE st.id = p_store_id;

  RETURN result;
END;
$$;

-- ─── ANALYTICS ───
CREATE OR REPLACE FUNCTION get_analytics(p_store_id UUID, p_days INT DEFAULT 30)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  result JSONB;
BEGIN
  SELECT jsonb_build_object(
    'total_orders', (SELECT count(*) FROM public.service_orders WHERE store_id = p_store_id AND created_at >= now() - (p_days || ' days')::interval),
    'completed', (SELECT count(*) FROM public.service_orders WHERE store_id = p_store_id AND status = 'completed' AND created_at >= now() - (p_days || ' days')::interval),
    'cancelled', (SELECT count(*) FROM public.service_orders WHERE store_id = p_store_id AND status = 'cancelled' AND created_at >= now() - (p_days || ' days')::interval),
    'revenue', (SELECT COALESCE(sum(final_price), 0) FROM public.service_orders WHERE store_id = p_store_id AND status = 'completed' AND completed_at >= now() - (p_days || ' days')::interval),
    'avg_rating', (SELECT round(avg(rating)::numeric, 2) FROM public.reviews WHERE store_id = p_store_id AND created_at >= now() - (p_days || ' days')::interval)
  ) INTO result;

  RETURN result;
END;
$$;

-- ─── UPDATE RATING AVG ───
CREATE OR REPLACE FUNCTION update_rating_avg(p_store_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  UPDATE public.stores
  SET rating_avg = COALESCE(
    (SELECT round(avg(rating)::numeric, 2) FROM public.reviews WHERE store_id = p_store_id),
    0
  ),
  total_completed = (
    SELECT count(*) FROM public.service_orders WHERE store_id = p_store_id AND status = 'completed'
  ),
  updated_at = now()
  WHERE id = p_store_id;
END;
$$;

-- ─── AUTO CANCEL SLA BREACH ───
CREATE OR REPLACE FUNCTION auto_cancel_sla()
RETURNS INT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_count INT := 0;
  v_order RECORD;
BEGIN
  -- Mark SLA warnings for newly breached orders
  FOR v_order IN
    SELECT id, store_id FROM public.service_orders
    WHERE sla_deadline < now()
      AND sla_warned_at IS NULL
      AND status NOT IN ('completed', 'cancelled')
    LIMIT 100
  LOOP
    UPDATE public.service_orders
    SET sla_warned_at = now(),
        sla_breach_count = sla_breach_count + 1,
        updated_at = now()
    WHERE id = v_order.id;

    INSERT INTO public.service_tracking (order_id, status, note, created_by_type, created_by_id)
    VALUES (v_order.id, 'cancelled', 'SLA breach: auto-warning', 'system', 'sla-monitor');

    v_count := v_count + 1;
  END LOOP;

  -- Auto-cancel orders breached >24h
  FOR v_order IN
    SELECT so.id, so.store_id, oi.id AS item_id, oi.sparepart_id
    FROM public.service_orders so
    LEFT JOIN public.order_items oi ON oi.order_id = so.id
    WHERE so.sla_deadline < now() - interval '24 hours'
      AND so.sla_warned_at IS NOT NULL
      AND so.status NOT IN ('completed', 'cancelled')
    LIMIT 50
  LOOP
    -- Release stock
    IF v_order.sparepart_id IS NOT NULL THEN
      PERFORM release_stock(v_order.sparepart_id);
    END IF;

    UPDATE public.service_orders
    SET status = 'cancelled',
        cancelled_at = now(),
        updated_at = now()
    WHERE id = v_order.id;

    UPDATE public.stores
    SET penalty_points = penalty_points + 1
    WHERE id = v_order.store_id;

    INSERT INTO public.service_tracking (order_id, status, note, created_by_type, created_by_id)
    VALUES (v_order.id, 'cancelled', 'Auto-cancelled: SLA breach >24h', 'system', 'sla-monitor');

    v_count := v_count + 1;
  END LOOP;

  RETURN v_count;
END;
$$;

-- ─── AUTH TRIGGER: Handle new user signup ───
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_role TEXT;
BEGIN
  v_role := NEW.raw_user_meta_data ->> 'role';

  -- Only auto-create customer profiles from self-signup.
  -- Store admin and platform admin accounts must be created via
  -- the admin API (platform-admin-jwt guarded endpoints), not via self-signup.
  IF v_role = 'customer' THEN
    INSERT INTO public.users (id, full_name, phone_number, password_hash)
    VALUES (
      NEW.id,
      COALESCE(NEW.raw_user_meta_data ->> 'full_name', 'Pelanggan'),
      SPLIT_PART(NEW.email, '@', 1),
      'supabase-managed'
    );
  END IF;

  RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_user();
