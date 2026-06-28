-- 010_fix_schema.sql — Fix store_applications schema bugs
-- Add admin_phone, make id_card_url optional

ALTER TABLE store_applications ADD COLUMN IF NOT EXISTS admin_phone VARCHAR(20);
ALTER TABLE store_applications ALTER COLUMN id_card_url DROP NOT NULL;
ALTER TABLE store_applications ALTER COLUMN business_license_url DROP NOT NULL;
