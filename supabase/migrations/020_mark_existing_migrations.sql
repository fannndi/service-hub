-- 020_mark_existing_migrations.sql
-- Menandai semua migrasi yang sudah ada di remote sebagai applied
-- Sehingga supabase db push tidak mencoba apply ulang 001-019
INSERT INTO _supabase_migrations (version, name, timestamp) VALUES
  ('001', '001_init.sql', now()),
  ('002', '002_rls.sql', now()),
  ('003', '003_functions.sql', now()),
  ('004', '004_seed.sql', now()),
  ('005', '005_notifications.sql', now()),
  ('006', '006_seed_data.sql', now()),
  ('007', '007_cron.sql', now()),
  ('008', '008_auto_cron.sql', now()),
  ('010', '010_fix_schema.sql', now()),
  ('013', '013_fix_missing_tables.sql', now()),
  ('015', '015_midtrans.sql', now()),
  ('016', '016_fix_rpc_and_seed.sql', now()),
  ('017', '017_email_notifications.sql', now()),
  ('018', '018_add_midtrans_unique.sql', now()),
  ('019', '019_trigger_cleanup.sql', now()),
  ('999', '999_create_test_users.sql', now()),
  ('999', '999_reset_and_seed.sql', now())
ON CONFLICT (version) DO NOTHING;
