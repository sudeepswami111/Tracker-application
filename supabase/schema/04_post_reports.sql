-- =================================================================================
-- POST REPORTS SCHEMA
-- Run this in Supabase Dashboard -> SQL Editor
-- =================================================================================

CREATE TABLE IF NOT EXISTS public.post_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id UUID REFERENCES public.community_posts(id) ON DELETE CASCADE,
  reporter_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  reason TEXT NOT NULL,
  details TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.post_reports ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can insert reports" 
ON public.post_reports FOR INSERT 
TO authenticated 
WITH CHECK (auth.uid() = reporter_id);

CREATE POLICY "Users can read own reports" 
ON public.post_reports FOR SELECT 
TO authenticated 
USING (auth.uid() = reporter_id);
