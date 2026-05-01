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
