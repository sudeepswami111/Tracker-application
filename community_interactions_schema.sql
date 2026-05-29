-- Table: community_replies
CREATE TABLE IF NOT EXISTS public.community_replies (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id uuid NOT NULL REFERENCES public.community_posts(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  reply_text text NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Table: community_reactions
CREATE TABLE IF NOT EXISTS public.community_reactions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id uuid NOT NULL REFERENCES public.community_posts(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  reaction_type text NOT NULL CHECK (reaction_type IN ('cheer', 'fire')),
  created_at timestamptz DEFAULT now(),
  UNIQUE(post_id, user_id, reaction_type)
);

-- Enable RLS
ALTER TABLE public.community_replies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.community_reactions ENABLE ROW LEVEL SECURITY;

-- RLS Policies for Replies
CREATE POLICY "Anyone can read community replies" 
ON public.community_replies FOR SELECT 
TO authenticated 
USING (true);

CREATE POLICY "Users can insert their own replies" 
ON public.community_replies FOR INSERT 
TO authenticated 
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own replies" 
ON public.community_replies FOR UPDATE 
TO authenticated 
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own replies" 
ON public.community_replies FOR DELETE 
TO authenticated 
USING (auth.uid() = user_id);

-- RLS Policies for Reactions
CREATE POLICY "Anyone can read community reactions" 
ON public.community_reactions FOR SELECT 
TO authenticated 
USING (true);

CREATE POLICY "Users can insert their own reactions" 
ON public.community_reactions FOR INSERT 
TO authenticated 
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own reactions" 
ON public.community_reactions FOR DELETE 
TO authenticated 
USING (auth.uid() = user_id);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_community_replies_post_id ON public.community_replies(post_id);
CREATE INDEX IF NOT EXISTS idx_community_replies_created_at ON public.community_replies(created_at);
CREATE INDEX IF NOT EXISTS idx_community_reactions_post_id ON public.community_reactions(post_id);
CREATE INDEX IF NOT EXISTS idx_community_reactions_user_id ON public.community_reactions(user_id);
CREATE INDEX IF NOT EXISTS idx_community_reactions_post_user_type ON public.community_reactions(post_id, user_id, reaction_type);

-- Enable Realtime
-- This requires running within the Supabase SQL editor or CLI
alter publication supabase_realtime add table public.community_replies;
alter publication supabase_realtime add table public.community_reactions;

-- Optional: Trigger to update updated_at on community_replies
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
   NEW.updated_at = now(); 
   RETURN NEW;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS update_community_replies_modtime ON public.community_replies;
CREATE TRIGGER update_community_replies_modtime
BEFORE UPDATE ON public.community_replies
FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();
