-- ==============================================================================
-- Backend RPC for Chat Home Screen
-- ==============================================================================
-- This function efficiently retrieves all chat rooms for a user along with:
-- 1. Friend's details
-- 2. The exact last message and its timestamp
-- 3. The accurate unread count of messages sent by the friend
--
-- Run this in your Supabase SQL Editor.

CREATE OR REPLACE FUNCTION public.get_my_chat_rooms(p_user_id UUID)
RETURNS TABLE (
  chat_id UUID,
  friend_id UUID,
  friend_name TEXT,
  friend_username TEXT,
  friend_avatar TEXT,
  last_message TEXT,
  last_message_time TIMESTAMP WITH TIME ZONE,
  unread_count BIGINT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    c.id AS chat_id,
    p.id AS friend_id,
    p.full_name AS friend_name,
    p.username AS friend_username,
    p.avatar_url AS friend_avatar,
    m.message AS last_message,
    m.created_at AS last_message_time,
    (
      SELECT COUNT(*) 
      FROM public.messages m2 
      WHERE m2.chat_id = c.id 
        AND m2.is_read = false 
        AND m2.sender_id != p_user_id
    ) AS unread_count
  FROM public.chats c
  -- Join the profile of the *other* person in the chat
  JOIN public.profiles p 
    ON (p.id = c.user1_id OR p.id = c.user2_id) AND p.id != p_user_id
  -- Fetch the single most recent message for the chat
  LEFT JOIN LATERAL (
    SELECT message, created_at
    FROM public.messages m
    WHERE m.chat_id = c.id
    ORDER BY created_at DESC
    LIMIT 1
  ) m ON true
  WHERE c.user1_id = p_user_id OR c.user2_id = p_user_id
  -- Sort by most recently active chat first, falling back to chat creation time
  ORDER BY m.created_at DESC NULLS LAST, c.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
