-- ============================================================
-- 👥 PEOPLE YOU MAY KNOW — Supabase SQL Setup
-- ============================================================
-- Run this in your Supabase SQL Editor (Dashboard → SQL Editor)
-- ============================================================

-- ─── 1. CHECK: Ensure required tables exist ──────────────────
-- These should already exist. If not, create them:

-- profiles table (should already exist from auth setup)
-- friend_requests table (should already exist)
-- friendships table (should already exist)

-- ─── 2. RLS POLICIES — Allow reading profiles ───────────────
-- This is the most common reason suggestions don't load!
-- By default, Supabase RLS blocks ALL reads unless you add a policy.

-- Enable RLS on profiles (if not already)
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Allow any authenticated user to READ all profiles
-- (needed for People You May Know to work)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'profiles' 
    AND policyname = 'Users can view all profiles'
  ) THEN
    CREATE POLICY "Users can view all profiles"
      ON profiles FOR SELECT
      TO authenticated
      USING (true);
  END IF;
END
$$;

-- Allow users to update their OWN profile only
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'profiles' 
    AND policyname = 'Users can update own profile'
  ) THEN
    CREATE POLICY "Users can update own profile"
      ON profiles FOR UPDATE
      TO authenticated
      USING (auth.uid() = id);
  END IF;
END
$$;

-- ─── 3. RLS POLICIES — friend_requests ──────────────────────

ALTER TABLE friend_requests ENABLE ROW LEVEL SECURITY;

-- Users can read requests they sent or received
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'friend_requests' 
    AND policyname = 'Users can view own friend requests'
  ) THEN
    CREATE POLICY "Users can view own friend requests"
      ON friend_requests FOR SELECT
      TO authenticated
      USING (auth.uid() = sender_id OR auth.uid() = receiver_id);
  END IF;
END
$$;

-- Users can send friend requests (INSERT)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'friend_requests' 
    AND policyname = 'Users can send friend requests'
  ) THEN
    CREATE POLICY "Users can send friend requests"
      ON friend_requests FOR INSERT
      TO authenticated
      WITH CHECK (auth.uid() = sender_id);
  END IF;
END
$$;

-- Users can update requests they received (accept/reject)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'friend_requests' 
    AND policyname = 'Users can update received requests'
  ) THEN
    CREATE POLICY "Users can update received requests"
      ON friend_requests FOR UPDATE
      TO authenticated
      USING (auth.uid() = receiver_id OR auth.uid() = sender_id);
  END IF;
END
$$;

-- ─── 4. RLS POLICIES — friendships ──────────────────────────

ALTER TABLE friendships ENABLE ROW LEVEL SECURITY;

-- Users can view their own friendships
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'friendships' 
    AND policyname = 'Users can view own friendships'
  ) THEN
    CREATE POLICY "Users can view own friendships"
      ON friendships FOR SELECT
      TO authenticated
      USING (auth.uid() = user1_id OR auth.uid() = user2_id);
  END IF;
END
$$;

-- Users can create friendships (when accepting a request)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'friendships' 
    AND policyname = 'Users can create friendships'
  ) THEN
    CREATE POLICY "Users can create friendships"
      ON friendships FOR INSERT
      TO authenticated
      WITH CHECK (auth.uid() = user1_id OR auth.uid() = user2_id);
  END IF;
END
$$;

-- ─── 5. VERIFY TABLES HAVE CORRECT COLUMNS ─────────────────
-- Run these SELECT queries to verify your tables:

-- SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'profiles';
-- SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'friend_requests';
-- SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'friendships';

-- ─── 6. CHECK IF THERE ARE OTHER USERS ──────────────────────
-- If you're the only user, there are no suggestions to show!
-- Run this to check:

-- SELECT id, full_name, username FROM profiles;

-- If only 1 row exists, create a test user by signing up
-- with a different email in your app.
