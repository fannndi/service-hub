-- 023: Ubah default channel failed_notifications dari 'whatsapp' ke 'email'
ALTER TABLE failed_notifications ALTER COLUMN channel SET DEFAULT 'email';
