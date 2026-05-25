-- =================================================================================
-- COMMUNITY IMAGES STORAGE BUCKET SETUP
-- Run this in Supabase Dashboard -> SQL Editor
-- =================================================================================

-- 1. Create the public bucket
INSERT INTO storage.buckets (id, name, public) 
VALUES ('community_images', 'community_images', true)
ON CONFLICT (id) DO NOTHING;

-- 2. Allow public to read the images
CREATE POLICY "Give users access to read images" 
ON storage.objects FOR SELECT 
TO public 
USING ( bucket_id = 'community_images' );

-- 3. Allow authenticated users to upload images
CREATE POLICY "Give authenticated users access to upload images" 
ON storage.objects FOR INSERT 
TO authenticated 
WITH CHECK ( bucket_id = 'community_images' );

-- 4. Allow authenticated users to update their own images
CREATE POLICY "Give authenticated users access to update their own images" 
ON storage.objects FOR UPDATE 
TO authenticated 
USING ( auth.uid() = owner )
WITH CHECK ( bucket_id = 'community_images' );

-- 5. Allow authenticated users to delete their own images
CREATE POLICY "Give authenticated users access to delete their own images" 
ON storage.objects FOR DELETE 
TO authenticated 
USING ( auth.uid() = owner AND bucket_id = 'community_images' );
