-- =================================================================================
-- LIFE PULSE: CHAT AND MESSAGING RLS OVERHAUL
-- =================================================================================
-- Run this in the Supabase Dashboard -> SQL Editor
-- This ensures that chat messages are correctly scoped to the participants
-- and that realtime messaging is fully enabled.

-- 1. ENABLE RLS
ALTER TABLE public.chats ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

-- 2. CHATS POLICIES
DROP POLICY IF EXISTS "Users can read their chats" ON public.chats;
CREATE POLICY "Users can read their chats" ON public.chats 
  FOR SELECT USING (auth.uid() = user1_id OR auth.uid() = user2_id);

DROP POLICY IF EXISTS "Users can insert their chats" ON public.chats;
CREATE POLICY "Users can insert their chats" ON public.chats 
  FOR INSERT WITH CHECK (auth.uid() = user1_id OR auth.uid() = user2_id);

DROP POLICY IF EXISTS "Users can update their chats" ON public.chats;
CREATE POLICY "Users can update their chats" ON public.chats 
  FOR UPDATE USING (auth.uid() = user1_id OR auth.uid() = user2_id);

-- 3. MESSAGES POLICIES
DROP POLICY IF EXISTS "Users can read messages in their chats" ON public.messages;
CREATE POLICY "Users can read messages in their chats" ON public.messages 
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.chats c 
      WHERE c.id = chat_id 
      AND (c.user1_id = auth.uid() OR c.user2_id = auth.uid())
    )
  );

DROP POLICY IF EXISTS "Users can insert messages in their chats" ON public.messages;
CREATE POLICY "Users can insert messages in their chats" ON public.messages 
  FOR INSERT WITH CHECK (
    auth.uid() = sender_id AND 
    EXISTS (
      SELECT 1 FROM public.chats c 
      WHERE c.id = chat_id 
      AND (c.user1_id = auth.uid() OR c.user2_id = auth.uid())
    )
  );

DROP POLICY IF EXISTS "Users can update their own messages" ON public.messages;
CREATE POLICY "Users can update their own messages" ON public.messages 
  FOR UPDATE USING (auth.uid() = sender_id);

DROP POLICY IF EXISTS "Users can delete their own messages" ON public.messages;
CREATE POLICY "Users can delete their own messages" ON public.messages 
  FOR DELETE USING (auth.uid() = sender_id);

-- 4. ENABLE REALTIME
-- Drop and recreate the publication to ensure messages are included
DROP PUBLICATION IF EXISTS supabase_realtime;
CREATE PUBLICATION supabase_realtime FOR TABLE 
  public.follows, 
  public.profiles, 
  public.messages, 
  public.chats,
  public.notifications;
