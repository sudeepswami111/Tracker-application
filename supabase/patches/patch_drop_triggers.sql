-- ============================================================
-- FIX: Drop the failing message notification trigger
-- ============================================================
-- The Flutter app now handles sending push notifications securely in the 
-- frontend Dart code. This trigger was causing message inserts to fail 
-- due to a UUID vs TEXT type mismatch on the reference_id column.
-- 
-- Run this block in your Supabase SQL Editor.

DROP TRIGGER IF EXISTS on_new_message ON public.messages;
DROP FUNCTION IF EXISTS public.notify_new_message();
