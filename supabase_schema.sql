-- ==============================================================================
-- 🚀 LIFEPULSE SOCIAL FITNESS SYSTEM — DATABASE SCHEMA
-- Run this completely in the Supabase SQL Editor (supabase.com → SQL Editor).
-- It is safe to re-run — all CREATE statements use IF NOT EXISTS.
-- ==============================================================================

-- ─────────────────────────────────────────────────────────────────
-- 1. UTILITY FUNCTION (auto-update updated_at column)
-- ─────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION handle_updated_at() RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ─────────────────────────────────────────────────────────────────
-- 2. AUTO-CREATE PROFILE ON SIGN UP
-- When a user signs up via Supabase Auth, this trigger automatically
-- inserts a row into public.profiles with their id and email username.
-- ─────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  base_username TEXT;
  final_username TEXT;
  suffix        INT := 0;
BEGIN
  -- Derive a base username from email or metadata
  base_username := COALESCE(
    NEW.raw_user_meta_data->>'user_name',
    SPLIT_PART(NEW.email, '@', 1)
  );
  -- Ensure no spaces / special chars
  base_username := REGEXP_REPLACE(base_username, '[^a-zA-Z0-9_]', '', 'g');
  IF base_username = '' THEN base_username := 'user'; END IF;

  final_username := base_username;

  -- Resolve uniqueness conflicts by appending a numeric suffix
  LOOP
    EXIT WHEN NOT EXISTS (
      SELECT 1 FROM public.profiles WHERE username = final_username
    );
    suffix        := suffix + 1;
    final_username := base_username || suffix::TEXT;
  END LOOP;

  INSERT INTO public.profiles (id, username, full_name, avatar_url)
  VALUES (
    NEW.id,
    final_username,
    COALESCE(NEW.raw_user_meta_data->>'full_name', final_username),
    COALESCE(NEW.raw_user_meta_data->>'avatar_url', NULL)
  )
  ON CONFLICT (id) DO NOTHING;

  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  -- Never let a profile error block user creation
  RAISE WARNING 'handle_new_user failed for %: %', NEW.id, SQLERRM;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ─────────────────────────────────────────────────────────────────
-- 3. CREATE TABLES
-- ─────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username TEXT UNIQUE NOT NULL,
  full_name TEXT,
  avatar_url TEXT,
  bio TEXT,
  city TEXT,
  fitness_goal TEXT,
  activity_level TEXT,
  daily_step_goal INTEGER DEFAULT 10000,
  interests TEXT[] DEFAULT '{}',
  is_online BOOLEAN DEFAULT false,
  last_seen TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.friend_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sender_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  receiver_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(sender_id, receiver_id),
  CHECK(sender_id != receiver_id)
);

CREATE TABLE IF NOT EXISTS public.chats (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user1_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  user2_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT chats_ordered CHECK (user1_id < user2_id),
  CONSTRAINT chats_unique_pair UNIQUE (user1_id, user2_id)
);

CREATE TABLE IF NOT EXISTS public.friendships (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user1_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  user2_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  chat_room_id UUID REFERENCES public.chats(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT friendships_ordered CHECK (user1_id < user2_id),
  CONSTRAINT friendships_unique UNIQUE (user1_id, user2_id)
);

CREATE TABLE IF NOT EXISTS public.messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  chat_id UUID NOT NULL REFERENCES public.chats(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  message TEXT NOT NULL,
  message_type TEXT DEFAULT 'text' CHECK (message_type IN ('text', 'image', 'system')),
  is_read BOOLEAN DEFAULT false,
  read_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  actor_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK (type IN ('friend_request', 'request_accepted', 'message', 'challenge')),
  reference_id UUID,
  title TEXT,
  body TEXT,
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─────────────────────────────────────────────────────────────────
-- 4. ENABLE ROW LEVEL SECURITY
-- ─────────────────────────────────────────────────────────────────
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.friend_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.friendships ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chats ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- ─────────────────────────────────────────────────────────────────
-- 5. DROP OLD POLICIES (safe to re-run)
-- ─────────────────────────────────────────────────────────────────
DO $$
BEGIN
  DROP POLICY IF EXISTS "profiles_select_all"    ON public.profiles;
  DROP POLICY IF EXISTS "profiles_insert_own"    ON public.profiles;
  DROP POLICY IF EXISTS "profiles_update_owner"  ON public.profiles;
  DROP POLICY IF EXISTS "requests_select"        ON public.friend_requests;
  DROP POLICY IF EXISTS "requests_insert"        ON public.friend_requests;
  DROP POLICY IF EXISTS "requests_update"        ON public.friend_requests;
  DROP POLICY IF EXISTS "friendships_select"     ON public.friendships;
  DROP POLICY IF EXISTS "friendships_insert"     ON public.friendships;
  DROP POLICY IF EXISTS "chats_select"           ON public.chats;
  DROP POLICY IF EXISTS "chats_insert"           ON public.chats;
  DROP POLICY IF EXISTS "messages_select"        ON public.messages;
  DROP POLICY IF EXISTS "messages_insert"        ON public.messages;
  DROP POLICY IF EXISTS "notifications_select"   ON public.notifications;
  DROP POLICY IF EXISTS "notifications_update"   ON public.notifications;
  DROP POLICY IF EXISTS "notifications_insert"   ON public.notifications;
END $$;

-- ─────────────────────────────────────────────────────────────────
-- 6. RECREATE POLICIES
-- ─────────────────────────────────────────────────────────────────

-- Profiles: anyone can read, only owner can insert/update
CREATE POLICY "profiles_select_all"   ON public.profiles FOR SELECT USING (true);
CREATE POLICY "profiles_insert_own"   ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "profiles_update_owner" ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- Friend Requests
CREATE POLICY "requests_select" ON public.friend_requests FOR SELECT USING (auth.uid() = sender_id OR auth.uid() = receiver_id);
CREATE POLICY "requests_insert" ON public.friend_requests FOR INSERT WITH CHECK (auth.uid() = sender_id);
CREATE POLICY "requests_update" ON public.friend_requests FOR UPDATE USING (auth.uid() = receiver_id);

-- Friendships
CREATE POLICY "friendships_select" ON public.friendships FOR SELECT USING (auth.uid() = user1_id OR auth.uid() = user2_id);
CREATE POLICY "friendships_insert" ON public.friendships FOR INSERT WITH CHECK (auth.uid() = user1_id OR auth.uid() = user2_id);

-- Chats
CREATE POLICY "chats_select" ON public.chats FOR SELECT USING (auth.uid() = user1_id OR auth.uid() = user2_id);
CREATE POLICY "chats_insert" ON public.chats FOR INSERT WITH CHECK (auth.uid() = user1_id OR auth.uid() = user2_id);

-- Messages
CREATE POLICY "messages_select" ON public.messages FOR SELECT USING (
  EXISTS (SELECT 1 FROM public.chats WHERE id = chat_id AND (user1_id = auth.uid() OR user2_id = auth.uid()))
);
CREATE POLICY "messages_insert" ON public.messages FOR INSERT WITH CHECK (
  auth.uid() = sender_id AND
  EXISTS (SELECT 1 FROM public.chats WHERE id = chat_id AND (user1_id = auth.uid() OR user2_id = auth.uid()))
);

-- Notifications
CREATE POLICY "notifications_select" ON public.notifications FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "notifications_update" ON public.notifications FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "notifications_insert" ON public.notifications FOR INSERT WITH CHECK (true);

-- ─────────────────────────────────────────────────────────────────
-- 7. TRIGGERS (updated_at auto-set)
-- ─────────────────────────────────────────────────────────────────
DROP TRIGGER IF EXISTS set_profiles_updated_at ON public.profiles;
CREATE TRIGGER set_profiles_updated_at BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION handle_updated_at();

DROP TRIGGER IF EXISTS set_friend_requests_updated_at ON public.friend_requests;
CREATE TRIGGER set_friend_requests_updated_at BEFORE UPDATE ON public.friend_requests FOR EACH ROW EXECUTE FUNCTION handle_updated_at();

DROP TRIGGER IF EXISTS set_messages_updated_at ON public.messages;
CREATE TRIGGER set_messages_updated_at BEFORE UPDATE ON public.messages FOR EACH ROW EXECUTE FUNCTION handle_updated_at();

-- ─────────────────────────────────────────────────────────────────
-- 8. ENABLE REALTIME
-- ─────────────────────────────────────────────────────────────────
ALTER PUBLICATION supabase_realtime ADD TABLE public.friend_requests;
ALTER PUBLICATION supabase_realtime ADD TABLE public.friendships;
ALTER PUBLICATION supabase_realtime ADD TABLE public.chats;
ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;
ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;

-- ─────────────────────────────────────────────────────────────────
-- 9. INDEXES (for query performance)
-- ─────────────────────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_friend_requests_receiver ON public.friend_requests(receiver_id);
CREATE INDEX IF NOT EXISTS idx_messages_chat_id ON public.messages(chat_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON public.notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_friendships_user1 ON public.friendships(user1_id);
CREATE INDEX IF NOT EXISTS idx_friendships_user2 ON public.friendships(user2_id);
