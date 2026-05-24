-- =================================================================================
-- CHALLENGE SECTION — SUPABASE SQL SCHEMA
-- Run this in Supabase Dashboard -> SQL Editor
-- =================================================================================

-- =================================================================================
-- 1. CHALLENGES TABLE
-- =================================================================================

CREATE TABLE IF NOT EXISTS public.challenges (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  goal_type TEXT NOT NULL DEFAULT 'Distance'
    CHECK (goal_type IN ('Distance', 'Steps', 'Workouts', 'Study', 'Calories')),
  target_value NUMERIC NOT NULL DEFAULT 100,
  difficulty TEXT NOT NULL DEFAULT 'Medium',
  tier TEXT NOT NULL DEFAULT 'Silver',
  category TEXT,            -- 'Running & Cardio', 'Fitness & Strength', 'Study & Focus'
  stakes TEXT,              -- Optional wager text
  start_date DATE,
  end_date DATE,
  created_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  is_public BOOLEAN DEFAULT TRUE,
  participants_count INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =================================================================================
-- 2. CHALLENGE PARTICIPANTS TABLE (tracks users & their progress)
-- =================================================================================

CREATE TABLE IF NOT EXISTS public.challenge_participants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  challenge_id UUID REFERENCES public.challenges(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  current_value NUMERIC DEFAULT 0,
  rank INT DEFAULT 1,
  joined_at TIMESTAMPTZ DEFAULT NOW(),
  completed_at TIMESTAMPTZ,
  UNIQUE(challenge_id, user_id)
);

-- =================================================================================
-- 3. ROW LEVEL SECURITY
-- =================================================================================

ALTER TABLE public.challenges ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.challenge_participants ENABLE ROW LEVEL SECURITY;

-- Challenges Policies
DROP POLICY IF EXISTS "Anyone can read public challenges" ON public.challenges;
CREATE POLICY "Anyone can read public challenges"
  ON public.challenges FOR SELECT TO authenticated
  USING (is_public = true OR created_by = auth.uid());

DROP POLICY IF EXISTS "Users can create challenges" ON public.challenges;
CREATE POLICY "Users can create challenges"
  ON public.challenges FOR INSERT TO authenticated
  WITH CHECK (created_by = auth.uid());

DROP POLICY IF EXISTS "Creators can update own challenges" ON public.challenges;
CREATE POLICY "Creators can update own challenges"
  ON public.challenges FOR UPDATE TO authenticated
  USING (created_by = auth.uid());

-- Participants Policies
DROP POLICY IF EXISTS "Users can read all participants" ON public.challenge_participants;
CREATE POLICY "Users can read all participants"
  ON public.challenge_participants FOR SELECT TO authenticated
  USING (true);

DROP POLICY IF EXISTS "Users can join challenges" ON public.challenge_participants;
CREATE POLICY "Users can join challenges"
  ON public.challenge_participants FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can update own progress" ON public.challenge_participants;
CREATE POLICY "Users can update own progress"
  ON public.challenge_participants FOR UPDATE TO authenticated
  USING (user_id = auth.uid());

-- =================================================================================
-- 4. RPC FUNCTION: Increment Participants Count (bypasses RLS for count update)
-- =================================================================================

CREATE OR REPLACE FUNCTION public.increment_participants(cid UUID)
RETURNS VOID
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql AS $$
BEGIN
  UPDATE public.challenges SET participants_count = participants_count + 1 WHERE id = cid;
END;
$$;

-- =================================================================================
-- 5. SEED DISCOVER CHALLENGES (Pre-populated public challenges)
-- =================================================================================

INSERT INTO public.challenges (title, goal_type, target_value, difficulty, tier, category, is_public, participants_count)
VALUES
  ('Summer Shred', 'Distance', 100.0, 'Medium', 'Silver', 'Running & Cardio', TRUE, 1200),
  ('Marathon Prep', 'Distance', 500.0, 'Hard', 'Gold', 'Running & Cardio', TRUE, 4500),
  ('Iron Man Prep Month', 'Workouts', 1000.0, 'Extreme', 'Diamond', 'Fitness & Strength', TRUE, 800),
  ('Daily Pushups', 'Workouts', 30.0, 'Easy', 'Bronze', 'Fitness & Strength', TRUE, 12000),
  ('Zen Month', 'Study', 30.0, 'Easy', 'Bronze', 'Study & Focus', TRUE, 3400),
  ('Deep Work Sprint', 'Study', 60.0, 'Medium', 'Silver', 'Study & Focus', TRUE, 5200)
ON CONFLICT DO NOTHING;

-- =================================================================================
-- 6. ENABLE REALTIME FOR CHALLENGE PARTICIPANTS (for live leaderboard updates)
-- =================================================================================

-- Add challenge_participants to the realtime publication if not already there
DO $$
BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE public.challenge_participants;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;
