-- ==========================================
-- ShEC CSE - Database Update Script
-- ==========================================
-- Run these commands in your Supabase SQL Editor to apply the latest changes.

-- 1. Update the 'notices' table with new columns
ALTER TABLE notices ADD COLUMN IF NOT EXISTS description TEXT DEFAULT '';
ALTER TABLE notices ADD COLUMN IF NOT EXISTS image_path TEXT DEFAULT '';

-- 2. Create the 'notice_images' storage bucket (if you haven't created it via UI)
-- Note: You must have the storage extension enabled to run this INSERT command directly.
-- If this fails, just create the bucket manually in the Supabase Storage UI, name it "notice_images", and set it to Public.
INSERT INTO storage.buckets (id, name, public) 
VALUES ('notice_images', 'notice_images', true)
ON CONFLICT (id) DO NOTHING;

-- 3. Setup Storage Security Policies for 'notice_images'
-- Give public access to read images
CREATE POLICY "Give public access to notice images" 
ON storage.objects FOR SELECT 
USING (bucket_id = 'notice_images');

-- Allow authenticated users to upload images
CREATE POLICY "Allow authenticated users to upload notice images" 
ON storage.objects FOR INSERT 
WITH CHECK (bucket_id = 'notice_images' AND auth.role() = 'authenticated');

-- Allow authenticated users to update their images
CREATE POLICY "Allow authenticated users to update notice images" 
ON storage.objects FOR UPDATE 
USING (bucket_id = 'notice_images' AND auth.role() = 'authenticated');

-- Allow authenticated users to delete images
CREATE POLICY "Allow authenticated users to delete notice images" 
ON storage.objects FOR DELETE 
USING (bucket_id = 'notice_images' AND auth.role() = 'authenticated');

-- ==========================================
-- DUCMC Results Integration Tables
-- ==========================================

-- 4. Exams Table
CREATE TABLE IF NOT EXISTS "DUCMC_exams_id" (
  exam_id TEXT PRIMARY KEY,
  exam_name TEXT NOT NULL
);

-- 5. Sessions Table
CREATE TABLE IF NOT EXISTS "DUCMC_sessions_id" (
  sess_id TEXT PRIMARY KEY,
  session TEXT NOT NULL
);

-- 6. Student Results Table
CREATE TABLE IF NOT EXISTS student_results (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reg_no TEXT NOT NULL,
    exam_id TEXT NOT NULL REFERENCES "DUCMC_exams_id"(exam_id),
    gpa TEXT NOT NULL,
    cgpa TEXT NOT NULL,
    subjects JSONB NOT NULL DEFAULT '[]'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(reg_no, exam_id)
);

-- Enable RLS for student_results
ALTER TABLE student_results ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only select their own results (matching reg_no)
CREATE POLICY "Users can view their own results" 
ON student_results FOR SELECT 
USING (reg_no = (SELECT du_reg FROM profiles WHERE id = auth.uid()));

-- Policy: Users can insert their own results
CREATE POLICY "Users can insert their own results" 
ON student_results FOR INSERT 
WITH CHECK (reg_no = (SELECT du_reg FROM profiles WHERE id = auth.uid()));

-- Enable RLS for DUCMC_exams_id and DUCMC_sessions_id (Read only for all authenticated)
ALTER TABLE "DUCMC_exams_id" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can read exams" ON "DUCMC_exams_id" FOR SELECT USING (auth.role() = 'authenticated');

ALTER TABLE "DUCMC_sessions_id" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can read sessions" ON "DUCMC_sessions_id" FOR SELECT USING (auth.role() = 'authenticated');

-- ==========================================
-- Verification System & Enhancements
-- ==========================================

-- 7. Add is_approved to existing tables
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS is_approved BOOLEAN DEFAULT FALSE;
ALTER TABLE notices ADD COLUMN IF NOT EXISTS is_approved BOOLEAN DEFAULT FALSE;
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS is_approved BOOLEAN DEFAULT FALSE;
-- Ensure contests table exists, assuming it was created previously
ALTER TABLE contests ADD COLUMN IF NOT EXISTS is_approved BOOLEAN DEFAULT FALSE;
-- Ensure gallery table exists
ALTER TABLE gallery ADD COLUMN IF NOT EXISTS is_approved BOOLEAN DEFAULT FALSE;
-- Also, gallery needs an image_path
ALTER TABLE gallery ADD COLUMN IF NOT EXISTS image_path TEXT DEFAULT '';

-- 8. Create Teachers Table
CREATE TABLE IF NOT EXISTS teachers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    designation TEXT NOT NULL,
    phone TEXT DEFAULT '',
    email TEXT DEFAULT '',
    image_path TEXT DEFAULT '',
    is_approved BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 9. Create 'gallery_images' Storage Bucket
INSERT INTO storage.buckets (id, name, public) 
VALUES ('gallery_images', 'gallery_images', true)
ON CONFLICT (id) DO NOTHING;

-- Policies for 'gallery_images'
CREATE POLICY "Give public access to gallery images" 
ON storage.objects FOR SELECT USING (bucket_id = 'gallery_images');

CREATE POLICY "Allow authenticated users to upload gallery images" 
ON storage.objects FOR INSERT 
WITH CHECK (bucket_id = 'gallery_images' AND auth.role() = 'authenticated');

CREATE POLICY "Allow authenticated users to update gallery images" 
ON storage.objects FOR UPDATE 
USING (bucket_id = 'gallery_images' AND auth.role() = 'authenticated');

CREATE POLICY "Allow authenticated users to delete gallery images" 
ON storage.objects FOR DELETE 
USING (bucket_id = 'gallery_images' AND auth.role() = 'authenticated');

-- 10. Create 'teacher_images' Storage Bucket
INSERT INTO storage.buckets (id, name, public) 
VALUES ('teacher_images', 'teacher_images', true)
ON CONFLICT (id) DO NOTHING;

-- Policies for 'teacher_images'
CREATE POLICY "Give public access to teacher images" 
ON storage.objects FOR SELECT USING (bucket_id = 'teacher_images');

CREATE POLICY "Allow authenticated users to upload teacher images" 
ON storage.objects FOR INSERT 
WITH CHECK (bucket_id = 'teacher_images' AND auth.role() = 'authenticated');

CREATE POLICY "Allow authenticated users to update teacher images" 
ON storage.objects FOR UPDATE 
USING (bucket_id = 'teacher_images' AND auth.role() = 'authenticated');

CREATE POLICY "Allow authenticated users to delete teacher images" 
ON storage.objects FOR DELETE 
USING (bucket_id = 'teacher_images' AND auth.role() = 'authenticated');

