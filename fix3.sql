DROP FUNCTION IF EXISTS public.get_analytics(uuid,integer);

CREATE OR REPLACE FUNCTION public.get_analytics(p_store_id uuid, p_days integer)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $body$
DECLARE result jsonb;
BEGIN
  SELECT jsonb_build_object(
    'total_orders', (SELECT count(*) FROM public.service_orders WHERE store_id::text = p_store_id::text AND created_at >= now() - (p_days || ' days')::interval),
    'completed', (SELECT count(*) FROM public.service_orders WHERE store_id::text = p_store_id::text AND status = 'completed' AND created_at >= now() - (p_days || ' days')::interval)
  ) INTO result;
  RETURN result;
END;
$body$;
