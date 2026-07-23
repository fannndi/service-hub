-- 008_auto_cron.sql — Automation cron jobs
-- Run via: supabase db query --linked -f supabase/migrations/008_auto_cron.sql

-- Low Stock Alert (every hour): notif store admin if sparepart qty <= 2
SELECT cron.schedule('low-stock-alert', '0 * * * *', $$
  DELETE FROM notifications WHERE type = 'low_stock';
  INSERT INTO notifications (store_id, role, type, title, message, link_to)
  SELECT store_id, 'store_admin', 'low_stock',
    'Stok Menipis',
    'Sparepart "' || part_name || '" sisa ' || qty || ' pcs.',
    '/store/inventory'
  FROM spareparts
  WHERE qty > 0 AND qty <= 2 AND status = 'available'
    AND store_id IS NOT NULL;
$$);

-- Dispute Auto-Escalation (every 30 min): escalate if store admin doesn't respond in 24h
SELECT cron.schedule('dispute-escalation', '*/30 * * * *', $$
  UPDATE disputes
  SET status = 'escalated'
  WHERE status = 'open'
    AND created_at < NOW() - INTERVAL '24 hours';
$$);
