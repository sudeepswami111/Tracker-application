-- ============================================================
-- 👥 PEOPLE YOU MAY KNOW — Complete Supabase SQL Setup
-- ============================================================
-- Run ALL of this in Supabase Dashboard → SQL Editor
-- ============================================================


-- ═══════════════════════════════════════════════════════════════
-- PART 1: Auto-create profile on signup (Database Trigger)
-- ═══════════════════════════════════════════════════════════════

-- 1. Function that fires on new auth user
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (
    id,
    name,
    created_at
  )
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
    NOW()
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

-- 2. Attach trigger to auth.users table
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();


-- ═══════════════════════════════════════════════════════════════
-- PART 1B: Backfill existing users who have no profile row
-- (Run this ONCE after adding the trigger above)
-- ═══════════════════════════════════════════════════════════════

INSERT INTO public.profiles (id, name, created_at)
SELECT
  au.id,
  COALESCE(au.raw_user_meta_data->>'full_name', split_part(au.email, '@', 1)),
  NOW()
FROM auth.users au
LEFT JOIN public.profiles p ON p.id = au.id
WHERE p.id IS NULL
ON CONFLICT (id) DO NOTHING;


-- ═══════════════════════════════════════════════════════════════
-- PART 2: RLS Policies — Allow users to see each other
-- ═══════════════════════════════════════════════════════════════

-- Enable RLS on profiles
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they conflict (safe to run)
DROP POLICY IF EXISTS "Users can view all profiles" ON public.profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can insert their own profile" ON public.profiles;

-- Allow any logged-in user to READ all profiles (needed for suggestions)
CREATE POLICY "Users can view all profiles"
  ON public.profiles FOR SELECT
  TO authenticated
  USING (true);

-- Allow users to update only their own profile
CREATE POLICY "Users can update their own profile"
  ON public.profiles FOR UPDATE
  TO authenticated
  USING (auth.uid() = id);

-- Allow the Flutter upsert safety net to insert
CREATE POLICY "Users can insert their own profile"
  ON public.profiles FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = id);


-- ═══════════════════════════════════════════════════════════════
-- PART 2B: RLS Policies for friend_requests & friendships
-- ═══════════════════════════════════════════════════════════════

-- friend_requests
ALTER TABLE friend_requests ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own friend requests" ON public.friend_requests;
DROP POLICY IF EXISTS "Users can send friend requests" ON public.friend_requests;
DROP POLICY IF EXISTS "Users can update received requests" ON public.friend_requests;

CREATE POLICY "Users can view own friend requests"
  ON public.friend_requests FOR SELECT
  TO authenticated
  USING (auth.uid() = sender_id OR auth.uid() = receiver_id);

CREATE POLICY "Users can send friend requests"
  ON public.friend_requests FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = sender_id);

CREATE POLICY "Users can update received requests"
  ON public.friend_requests FOR UPDATE
  TO authenticated
  USING (auth.uid() = receiver_id OR auth.uid() = sender_id);

-- friendships
ALTER TABLE friendships ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own friendships" ON public.friendships;
DROP POLICY IF EXISTS "Users can create friendships" ON public.friendships;

CREATE POLICY "Users can view own friendships"
  ON public.friendships FOR SELECT
  TO authenticated
  USING (auth.uid() = user1_id OR auth.uid() = user2_id);

CREATE POLICY "Users can create friendships"
  ON public.friendships FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user1_id OR auth.uid() = user2_id);


-- ═══════════════════════════════════════════════════════════════
-- VERIFICATION: Run these after the above succeeds
-- ═══════════════════════════════════════════════════════════════

-- Check what columns profiles actually has:
-- SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'profiles' AND table_schema = 'public';

-- Check profiles exist for all auth users:
-- SELECT p.id, p.name FROM profiles p;

-- Check total auth users vs profiles:
-- SELECT
--   (SELECT COUNT(*) FROM auth.users) AS auth_users,
--   (SELECT COUNT(*) FROM profiles) AS profile_rows;
