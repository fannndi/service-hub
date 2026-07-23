DROP POLICY IF EXISTS notifications_insert ON notifications;
CREATE POLICY notifications_insert ON notifications FOR INSERT TO authenticated WITH CHECK (
  (role = 'customer' AND user_id = auth.uid()) OR
  (role = 'store_admin' AND store_id IN (SELECT store_id FROM store_admins WHERE id = auth.uid())) OR
  EXISTS (SELECT 1 FROM platform_admins WHERE id = auth.uid())
);
