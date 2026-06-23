-- 004_seed.sql — SEED DATA

-- Seed Platform Admin (password: admin)
-- Note: In production, create via Supabase Auth admin API, not SQL.
-- This is for local dev only.
INSERT INTO platform_admins (username, password_hash, full_name)
VALUES ('admin', '$2a$12$LJ3m4ys3Lg3YOG.xKbY8O.YSLhps/iG5FMbPmIdkHeStY92Ss6qOa', 'Platform Admin')
ON CONFLICT (username) DO NOTHING;
