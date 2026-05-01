-- ==========================================
-- ShEC CSE - Database Update Script (Phase 3)
-- ==========================================

-- 1. Add 'designation' to profiles
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS designation TEXT DEFAULT 'Student';

-- 2. Add 'is_visible' and 'created_by_name' to content tables
-- Notices
ALTER TABLE notices ADD COLUMN IF NOT EXISTS is_visible BOOLEAN DEFAULT TRUE;
ALTER TABLE notices ADD COLUMN IF NOT EXISTS created_by_name TEXT DEFAULT '';

-- Jobs
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS is_visible BOOLEAN DEFAULT TRUE;
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS created_by_name TEXT DEFAULT '';

-- Contests
ALTER TABLE contests ADD COLUMN IF NOT EXISTS is_visible BOOLEAN DEFAULT TRUE;
ALTER TABLE contests ADD COLUMN IF NOT EXISTS created_by_name TEXT DEFAULT '';

-- Gallery
ALTER TABLE gallery ADD COLUMN IF NOT EXISTS is_visible BOOLEAN DEFAULT TRUE;
ALTER TABLE gallery ADD COLUMN IF NOT EXISTS created_by_name TEXT DEFAULT '';
-- Rename subtitle to description (if you want to keep data, otherwise drop/create)
-- Supabase doesn't have a simple RENAME if it might fail, so we add description and keep subtitle for compatibility or migration.
ALTER TABLE gallery ADD COLUMN IF NOT EXISTS description TEXT DEFAULT '';

-- Teachers
ALTER TABLE teachers ADD COLUMN IF NOT EXISTS is_visible BOOLEAN DEFAULT TRUE;
ALTER TABLE teachers ADD COLUMN IF NOT EXISTS created_by_name TEXT DEFAULT '';

-- 3. RLS for Teachers Table (Enable public read, restricted write)
ALTER TABLE teachers ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Enable public read access for teachers" ON teachers FOR SELECT USING (is_visible = true OR (SELECT role FROM profiles WHERE id = auth.uid()) != 'member'::user_role);
CREATE POLICY "Enable insert for committee and superusers" ON teachers FOR INSERT WITH CHECK ((SELECT role FROM profiles WHERE id = auth.uid()) != 'member'::user_role);
CREATE POLICY "Enable update for committee and superusers" ON teachers FOR UPDATE USING ((SELECT role FROM profiles WHERE id = auth.uid()) != 'member'::user_role);
CREATE POLICY "Enable delete for committee and superusers" ON teachers FOR DELETE USING ((SELECT role FROM profiles WHERE id = auth.uid()) != 'member'::user_role);

-- 4. Populate Sessions if empty
INSERT INTO "DUCMC_sessions_id" (sess_id, session) VALUES 
('21', '2020-21'),
('22', '2021-22'),
('23', '2022-23'),
('24', '2023-24'),
('25', '2024-25')
ON CONFLICT (sess_id) DO NOTHING;

-- 5. Update Existing Roles (Optional: Migrate 'superuser' to 'committee' with 'President' designation)
-- The user wants to remove 'superuser' category from UI, but we can keep the DB type for now or migrate.
-- Let's just make sure President/VP have the right designation.
UPDATE profiles SET designation = 'President' WHERE role = 'superuser'::user_role AND designation = 'Student';
