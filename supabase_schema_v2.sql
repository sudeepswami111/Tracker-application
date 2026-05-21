-- =================================================================================
-- LIFE PULSE: COMPLETE SUPABASE SQL SCHEMA (V2)
-- =================================================================================
-- Run this in the Supabase Dashboard -> SQL Editor
-- This script safely creates or updates all tables, policies, functions, and triggers
-- required for the Instagram-style social graph, messaging, and notifications.

-- =================================================================================
-- 1. UPDATE PROFILES TABLE
-- =================================================================================
-- Ensure the profiles table has all the required columns for the new dart files
ALTER TABLE public.profiles 
  ADD COLUMN IF NOT EXISTS username TEXT,
  ADD COLUMN IF NOT EXISTS full_name TEXT,
  ADD COLUMN IF NOT EXISTS avatar_url TEXT,
  ADD COLUMN IF NOT EXISTS bio TEXT,
  ADD COLUMN IF NOT EXISTS followers_count INT DEFAULT 0,
  ADD COLUMN IF NOT EXISTS following_count INT DEFAULT 0,
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- Migration: Copy existing 'name' to 'full_name' if full_name is empty (for backward compatibility)
UPDATE public.profiles SET full_name = name WHERE full_name IS NULL AND name IS NOT NULL;
UPDATE public.profiles SET username = split_part(name, ' ', 1) WHERE username IS NULL AND name IS NOT NULL;

-- =================================================================================
-- 2. CREATE NEW TABLES
-- =================================================================================

-- FOLLOWS TABLE
CREATE TABLE IF NOT EXISTS public.follows (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  follower_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  following_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('pending', 'accepted')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(follower_id, following_id)
);

-- NOTIFICATIONS TABLE
CREATE TABLE IF NOT EXISTS public.notifications (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  actor_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  type TEXT NOT NULL,
  title TEXT,
  body TEXT,
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- CHATS TABLE
CREATE TABLE IF NOT EXISTS public.chats (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user1_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  user2_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user1_id, user2_id),
  CHECK (user1_id < user2_id) -- Ensure deterministic ordering to prevent duplicate rooms
);

-- MESSAGES TABLE
CREATE TABLE IF NOT EXISTS public.messages (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  chat_id UUID REFERENCES public.chats(id) ON DELETE CASCADE NOT NULL,
  sender_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  message TEXT NOT NULL,
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =================================================================================
-- 3. RPC FUNCTIONS (Used by Dart code)
-- =================================================================================

-- Get Suggestions (Users you haven't followed yet)
CREATE OR REPLACE FUNCTION get_suggestions(p_current_user UUID, p_limit INT DEFAULT 20)
RETURNS TABLE (
  id UUID,
  username TEXT,
  full_name TEXT,
  avatar_url TEXT,
  followers_count INT,
  following_count INT,
  follow_status TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    p.id, p.username, p.full_name, p.avatar_url, p.followers_count, p.following_count,
    f.status AS follow_status
  FROM public.profiles p
  LEFT JOIN public.follows f ON f.following_id = p.id AND f.follower_id = p_current_user
  WHERE p.id != p_current_user
    AND (f.status IS NULL) -- Only users not followed or requested
  ORDER BY p.followers_count DESC NULLS LAST, p.created_at DESC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- Get Followers
CREATE OR REPLACE FUNCTION get_followers(p_user_id UUID)
RETURNS TABLE (
  id UUID,
  username TEXT,
  full_name TEXT,
  avatar_url TEXT,
  followers_count INT,
  following_count INT,
  follow_status TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    p.id, p.username, p.full_name, p.avatar_url, p.followers_count, p.following_count,
    'accepted'::TEXT AS follow_status
  FROM public.follows f
  JOIN public.profiles p ON p.id = f.follower_id
  WHERE f.following_id = p_user_id AND f.status = 'accepted'
  ORDER BY f.created_at DESC;
END;
$$ LANGUAGE plpgsql;

-- Get Following
CREATE OR REPLACE FUNCTION get_following(p_user_id UUID)
RETURNS TABLE (
  id UUID,
  username TEXT,
  full_name TEXT,
  avatar_url TEXT,
  followers_count INT,
  following_count INT,
  follow_status TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    p.id, p.username, p.full_name, p.avatar_url, p.followers_count, p.following_count,
    'accepted'::TEXT AS follow_status
  FROM public.follows f
  JOIN public.profiles p ON p.id = f.following_id
  WHERE f.follower_id = p_user_id AND f.status = 'accepted'
  ORDER BY f.created_at DESC;
END;
$$ LANGUAGE plpgsql;

-- Search Users (for Chat Search Bar)
CREATE OR REPLACE FUNCTION search_users_by_username(p_query TEXT, p_current_user UUID)
RETURNS TABLE (
  id UUID,
  username TEXT,
  full_name TEXT,
  avatar_url TEXT,
  followers_count INT,
  following_count INT,
  follow_status TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    p.id, p.username, p.full_name, p.avatar_url, p.followers_count, p.following_count,
    f.status AS follow_status
  FROM public.profiles p
  LEFT JOIN public.follows f ON f.following_id = p.id AND f.follower_id = p_current_user
  WHERE (p.username ILIKE '%' || p_query || '%' OR p.full_name ILIKE '%' || p_query || '%')
    AND (p.id != p_current_user OR p_current_user IS NULL)
  ORDER BY p.followers_count DESC NULLS LAST
  LIMIT 20;
END;
$$ LANGUAGE plpgsql;

-- =================================================================================
-- 4. ACCEPT FOLLOW REQUEST RPC (called from Dart, bypasses RLS)
-- =================================================================================

CREATE OR REPLACE FUNCTION accept_follow_request(p_follow_id UUID, p_user_id UUID)
RETURNS VOID
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_follower_id UUID;
  v_following_id UUID;
  v_user1 UUID;
  v_user2 UUID;
BEGIN
  -- 1. Verify this follow request exists and is directed at p_user_id
  SELECT follower_id, following_id INTO v_follower_id, v_following_id
  FROM public.follows
  WHERE id = p_follow_id AND following_id = p_user_id AND status = 'pending';

  IF v_follower_id IS NULL THEN
    RAISE EXCEPTION 'Follow request not found or not authorized';
  END IF;

  -- 2. Update status to accepted
  UPDATE public.follows SET status = 'accepted', updated_at = NOW()
  WHERE id = p_follow_id;

  -- 3. Increment follower/following counts
  UPDATE public.profiles SET followers_count = COALESCE(followers_count, 0) + 1 WHERE id = v_following_id;
  UPDATE public.profiles SET following_count = COALESCE(following_count, 0) + 1 WHERE id = v_follower_id;

  -- 4. Create chat room (deterministic ordering to avoid duplicates)
  v_user1 := LEAST(v_follower_id, v_following_id);
  v_user2 := GREATEST(v_follower_id, v_following_id);
  INSERT INTO public.chats (user1_id, user2_id)
  VALUES (v_user1, v_user2)
  ON CONFLICT (user1_id, user2_id) DO NOTHING;

  -- 5. Notify the follower that their request was accepted
  INSERT INTO public.notifications (user_id, actor_id, type, title, body)
  VALUES (
    v_follower_id,
    v_following_id,
    'follow_accepted',
    'Follow Request Accepted',
    'Your follow request was accepted!'
  );
END;
$$ LANGUAGE plpgsql;

-- =================================================================================
-- 5. TRIGGERS
-- =================================================================================

-- NOTE: The handle_follow_accepted trigger is NO LONGER NEEDED because
-- the accept_follow_request RPC function handles all side effects
-- (count updates, chat creation, notifications) in a single atomic call.
-- We drop the trigger to prevent double-counting.
DROP TRIGGER IF EXISTS on_follow_accepted ON public.follows;

-- Trigger function to handle unfollow / deleting a request
CREATE OR REPLACE FUNCTION handle_unfollow()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF OLD.status = 'accepted' THEN
    -- Decrement counts
    UPDATE public.profiles SET followers_count = GREATEST(COALESCE(followers_count, 0) - 1, 0) WHERE id = OLD.following_id;
    UPDATE public.profiles SET following_count = GREATEST(COALESCE(following_count, 0) - 1, 0) WHERE id = OLD.follower_id;
  END IF;
  RETURN OLD;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS on_unfollow ON public.follows;
CREATE TRIGGER on_unfollow
  AFTER DELETE ON public.follows
  FOR EACH ROW
  EXECUTE FUNCTION handle_unfollow();


-- =================================================================================
-- 5. RLS POLICIES (Row Level Security)
-- =================================================================================

-- Enable RLS
ALTER TABLE public.follows ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chats ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

-- Follows Policies
DROP POLICY IF EXISTS "Users can read all follows" ON public.follows;
CREATE POLICY "Users can read all follows" ON public.follows FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can insert their own follows" ON public.follows;
CREATE POLICY "Users can insert their own follows" ON public.follows FOR INSERT WITH CHECK (auth.uid() = follower_id);

DROP POLICY IF EXISTS "Users can update follows directed at them" ON public.follows;
CREATE POLICY "Users can update follows directed at them" ON public.follows FOR UPDATE USING (auth.uid() = following_id);

DROP POLICY IF EXISTS "Users can delete their own follows or rejects" ON public.follows;
CREATE POLICY "Users can delete their own follows or rejects" ON public.follows FOR DELETE USING (auth.uid() = follower_id OR auth.uid() = following_id);

-- Notifications Policies
DROP POLICY IF EXISTS "Users can read own notifications" ON public.notifications;
CREATE POLICY "Users can read own notifications" ON public.notifications FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own notifications" ON public.notifications;
CREATE POLICY "Users can update own notifications" ON public.notifications FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "System can insert notifications" ON public.notifications;
CREATE POLICY "System can insert notifications" ON public.notifications FOR INSERT WITH CHECK (true);

-- Chats Policies
DROP POLICY IF EXISTS "Users can read their chats" ON public.chats;
CREATE POLICY "Users can read their chats" ON public.chats FOR SELECT USING (auth.uid() = user1_id OR auth.uid() = user2_id);

DROP POLICY IF EXISTS "Users can insert their chats" ON public.chats;
CREATE POLICY "Users can insert their chats" ON public.chats FOR INSERT WITH CHECK (auth.uid() = user1_id OR auth.uid() = user2_id);

-- Messages Policies
DROP POLICY IF EXISTS "Users can read messages in their chats" ON public.messages;
CREATE POLICY "Users can read messages in their chats" ON public.messages FOR SELECT USING (
  EXISTS (SELECT 1 FROM public.chats c WHERE c.id = chat_id AND (c.user1_id = auth.uid() OR c.user2_id = auth.uid()))
);

DROP POLICY IF EXISTS "Users can insert messages in their chats" ON public.messages;
CREATE POLICY "Users can insert messages in their chats" ON public.messages FOR INSERT WITH CHECK (
  auth.uid() = sender_id AND 
  EXISTS (SELECT 1 FROM public.chats c WHERE c.id = chat_id AND (c.user1_id = auth.uid() OR c.user2_id = auth.uid()))
);

-- =================================================================================
-- 6. ENABLE REALTIME
-- =================================================================================
-- Drop existing publications to avoid duplicates, then recreate
DROP PUBLICATION IF EXISTS supabase_realtime;
CREATE PUBLICATION supabase_realtime FOR TABLE 
  public.follows, 
  public.profiles, 
  public.messages, 
  public.notifications;
