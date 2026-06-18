-- =================================================================================
-- LIFE PULSE: CHAT AND MESSAGING RLS + REALTIME OVERHAUL
-- Based on CHAT_SYNC_FIX_README.md diagnosis
-- =================================================================================
-- Run this ENTIRE block in the Supabase Dashboard → SQL Editor in ONE click.
-- Do NOT split it into multiple executions.

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

-- 4. REBUILD REALTIME PUBLICATION (include ALL tables the app needs)
-- This fixes the root cause: supabase_schema_v2.sql previously dropped
-- the publication and recreated it WITHOUT public.chats, breaking chat sync.
DROP PUBLICATION IF EXISTS supabase_realtime;
CREATE PUBLICATION supabase_realtime FOR TABLE 
  public.follows, 
  public.profiles, 
  public.messages, 
  public.chats,        -- ← was missing from v2 schema, causing sync breakage
  public.notifications;

-- 5. SET REPLICA IDENTITY FULL (required so INSERT payloads carry all columns)
ALTER TABLE public.messages REPLICA IDENTITY FULL;
ALTER TABLE public.chats REPLICA IDENTITY FULL;

-- 6. VERIFY — run this SELECT separately to confirm all 5 tables are present:
-- SELECT schemaname, tablename
-- FROM pg_publication_tables
-- WHERE pubname = 'supabase_realtime'
-- ORDER BY tablename;
-- Expected: chats, follows, messages, notifications, profiles
