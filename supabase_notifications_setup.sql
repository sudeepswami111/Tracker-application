-- ============================================================
-- NOTIFICATIONS TABLE + RLS + DB TRIGGERS
-- Run this in Supabase SQL Editor
-- ============================================================

-- 1. Create notifications table
CREATE TABLE IF NOT EXISTS public.notifications (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  actor_id     UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  type         TEXT NOT NULL,
  -- Types: follow_request | follow_accepted | new_follower | message |
  --        post_like | community_post | challenge | challenge_complete |
  --        run_complete | achievement | streak | goal_reached
  title        TEXT,
  body         TEXT,
  reference_id TEXT,     -- chat_id, post_id, challenge_id, run_id etc.
  is_read      BOOLEAN NOT NULL DEFAULT FALSE,
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS notifications_user_id_idx ON public.notifications(user_id);
CREATE INDEX IF NOT EXISTS notifications_is_read_idx ON public.notifications(user_id, is_read);

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can read own notifications"    ON public.notifications;
DROP POLICY IF EXISTS "Users can update own notifications"  ON public.notifications;
DROP POLICY IF EXISTS "Service can insert notifications"    ON public.notifications;
DROP POLICY IF EXISTS "Users can delete own notifications"  ON public.notifications;

CREATE POLICY "Users can read own notifications"
  ON public.notifications FOR SELECT TO authenticated USING (auth.uid() = user_id);
CREATE POLICY "Users can update own notifications"
  ON public.notifications FOR UPDATE TO authenticated USING (auth.uid() = user_id);
CREATE POLICY "Service can insert notifications"
  ON public.notifications FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Users can delete own notifications"
  ON public.notifications FOR DELETE TO authenticated USING (auth.uid() = user_id);


-- ============================================================
-- 2. DB TRIGGER: New follow request → notify the target user
-- ============================================================
CREATE OR REPLACE FUNCTION public.notify_follow_request()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF NEW.status = 'pending' THEN
    INSERT INTO public.notifications(user_id, actor_id, type, title, body)
    VALUES (
      NEW.following_id,
      NEW.follower_id,
      'follow_request',
      'New Follow Request',
      (SELECT COALESCE(full_name, username) FROM public.profiles WHERE id = NEW.follower_id) || ' wants to follow you'
    );
  END IF;
  RETURN NEW;
END; $$;

DROP TRIGGER IF EXISTS on_follow_request ON public.follows;
CREATE TRIGGER on_follow_request
  AFTER INSERT ON public.follows
  FOR EACH ROW EXECUTE PROCEDURE public.notify_follow_request();

-- ============================================================
-- 3. DB TRIGGER: Follow accepted → notify the requester
-- ============================================================
CREATE OR REPLACE FUNCTION public.notify_follow_accepted()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF OLD.status = 'pending' AND NEW.status = 'accepted' THEN
    INSERT INTO public.notifications(user_id, actor_id, type, title, body)
    VALUES (
      NEW.follower_id,
      NEW.following_id,
      'follow_accepted',
      'Follow Accepted 🎉',
      (SELECT COALESCE(full_name, username) FROM public.profiles WHERE id = NEW.following_id) || ' accepted your follow request'
    );
  END IF;
  RETURN NEW;
END; $$;

DROP TRIGGER IF EXISTS on_follow_accepted ON public.follows;
CREATE TRIGGER on_follow_accepted
  AFTER UPDATE ON public.follows
  FOR EACH ROW EXECUTE PROCEDURE public.notify_follow_accepted();

-- ============================================================
-- 4. DB TRIGGER: New message → notify the receiver
--    (De-duplicated: only one unread notification per sender every 5 mins)
-- ============================================================
CREATE OR REPLACE FUNCTION public.notify_new_message()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_receiver UUID;
  v_sender_name TEXT;
  v_recent_count INTEGER;
BEGIN
  -- Find the other participant in the chat
  SELECT 
    CASE 
      WHEN user1_id = NEW.sender_id THEN user2_id 
      ELSE user1_id 
    END INTO v_receiver
  FROM public.chats
  WHERE id = NEW.chat_id
  LIMIT 1;

  SELECT COALESCE(full_name, username) INTO v_sender_name
  FROM public.profiles WHERE id = NEW.sender_id;

  IF v_receiver IS NOT NULL THEN
    -- Deduplicate: only insert if no unread message notification from same sender in last 5 minutes
    SELECT COUNT(*) INTO v_recent_count
    FROM public.notifications
    WHERE user_id = v_receiver
      AND actor_id = NEW.sender_id
      AND type = 'message'
      AND is_read = false
      AND created_at > NOW() - INTERVAL '5 minutes';

    IF v_recent_count = 0 THEN
      INSERT INTO public.notifications(user_id, actor_id, type, title, body, reference_id)
      VALUES (
        v_receiver,
        NEW.sender_id,
        'message',
        v_sender_name,
        LEFT(NEW.message, 80),
        NEW.chat_id
      );
    END IF;
  END IF;
  RETURN NEW;
END; $$;

DROP TRIGGER IF EXISTS on_new_message ON public.messages;
CREATE TRIGGER on_new_message
  AFTER INSERT ON public.messages
  FOR EACH ROW EXECUTE PROCEDURE public.notify_new_message();
