-- =================================================================================
-- COMMUNITY POSTS SCHEMA
-- Run this in Supabase Dashboard -> SQL Editor
-- =================================================================================

-- 1. Create the table
CREATE TABLE IF NOT EXISTS public.community_posts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  image_url TEXT,
  activity_type TEXT,
  likes_count INT DEFAULT 0,
  comments_count INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Enable RLS
ALTER TABLE public.community_posts ENABLE ROW LEVEL SECURITY;

-- 3. RLS Policies
CREATE POLICY "Anyone can read posts" 
ON public.community_posts FOR SELECT 
TO authenticated 
USING (true);

CREATE POLICY "Users can insert own posts" 
ON public.community_posts FOR INSERT 
TO authenticated 
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own posts" 
ON public.community_posts FOR UPDATE 
TO authenticated 
USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own posts" 
ON public.community_posts FOR DELETE 
TO authenticated 
USING (auth.uid() = user_id);

-- 4. Like Increment RPC
CREATE OR REPLACE FUNCTION increment_likes(post_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.community_posts
  SET likes_count = likes_count + 1
  WHERE id = post_id;
END;
$$;

-- 5. Insert Seed Data
-- Note: Replace the user_id with a valid profile ID from your profiles table if you want seed data to show properly, 
-- or you can just leave it to create posts directly from the app.
