-- ─── NOTIFICATIONS TABLE (In-App) ───

CREATE TABLE IF NOT EXISTS notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  store_id UUID REFERENCES stores(id) ON DELETE CASCADE,
  role VARCHAR(20) NOT NULL DEFAULT 'customer',
  title VARCHAR(200) NOT NULL,
  message TEXT NOT NULL,
  type VARCHAR(50) NOT NULL DEFAULT 'info',
  is_read BOOLEAN NOT NULL DEFAULT false,
  link_to VARCHAR(255),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_notifications_user_unread ON notifications(user_id, is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_store_unread ON notifications(store_id, is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_role_created ON notifications(role, created_at DESC);

-- Enable RLS
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Customer: see only their own notifications
CREATE POLICY notification_customer_select ON notifications
  FOR SELECT USING (
    auth.uid() = user_id
  );

-- Customer: update is_read on own notifications
CREATE POLICY notification_customer_update ON notifications
  FOR UPDATE USING (
    auth.uid() = user_id
  );

-- Store admin: see notifications for their store
CREATE POLICY notification_store_select ON notifications
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM store_admins WHERE store_admins.store_id = notifications.store_id AND store_admins.id = auth.uid())
  );

-- Store admin: update is_read
CREATE POLICY notification_store_update ON notifications
  FOR UPDATE USING (
    EXISTS (SELECT 1 FROM store_admins WHERE store_admins.store_id = notifications.store_id AND store_admins.id = auth.uid())
  );
