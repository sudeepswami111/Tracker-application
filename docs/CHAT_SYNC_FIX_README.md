# 💬 Chat Messages Not Sending/Syncing — Root Cause & Fix

## What's Actually Wrong (Found in Your SQL Files, Not the Flutter Code)

Your Flutter chat code (`chat_service.dart`, `dm_chat_screen.dart`) is **correctly written**. `sendDM()` inserts into `messages`, the realtime channel listens for inserts, `getMyChats()` joins `profiles` correctly. This is not a Flutter bug.

The bug is in your **Supabase SQL files** — you have two schema files that conflict with each other:

| File | What it does to realtime |
|---|---|
| `supabase_schema.sql` (v1) | `ALTER PUBLICATION supabase_realtime ADD TABLE public.chats;` `ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;` |
| `supabase_schema_v2.sql` (v2) | `DROP PUBLICATION IF EXISTS supabase_realtime;` then recreates it `FOR TABLE public.follows, public.profiles, public.messages, public.notifications;` — **`chats` is missing!** |

### Why this breaks messaging:

If `supabase_schema_v2.sql` was run **after** `supabase_schema.sql` (which makes sense, since it's "v2"), the `DROP PUBLICATION` statement **deleted the entire realtime publication and rebuilt it without `public.chats`**. This means:

1. **Realtime updates for the `chats` table are completely broken** — when a new chat room is created (after a follow is accepted), nothing notifies the DM list screen to refresh
2. **If v2 ran with ANY error partway through** (a very common occurrence when re-running SQL scripts), the publication might have been dropped and **never successfully recreated**, meaning **`messages` realtime might also be silently broken** depending on exactly where the script failed
3. Even if `messages` *is* still in the publication, you cannot have "half" a publication setup reliably — this needs to be re-run cleanly to guarantee both tables are present

This explains exactly your symptom: **messages don't appear for the other person without a manual app restart/refresh**, because the realtime `INSERT` event for `messages` (and the `chats` creation event) may not be reliably reaching the Supabase Realtime channel.

---

## The Fix — Run This in Supabase SQL Editor (in this exact order)

### Step 1 — Verify what's currently in your realtime publication

Run this first to see the actual current state:

```sql
SELECT schemaname, tablename
FROM pg_publication_tables
WHERE pubname = 'supabase_realtime'
ORDER BY tablename;
```

Look at the result. If `chats` and `messages` are **both** missing or only one is present, that confirms the diagnosis above.

---

### Step 2 — Rebuild the realtime publication cleanly with ALL required tables

```sql
-- Drop and recreate cleanly with EVERY table your app needs in realtime
DROP PUBLICATION IF EXISTS supabase_realtime;

CREATE PUBLICATION supabase_realtime FOR TABLE
  public.follows,
  public.profiles,
  public.chats,        -- ← THIS WAS MISSING — required for new chat creation to sync
  public.messages,
  public.notifications;
```

> ⚠️ **Important:** Run this as ONE single statement block, not split across multiple "Run" clicks in the SQL editor. If the editor times out or you navigate away mid-execution, the publication can end up in a half-created state again.

---

### Step 3 — Verify `REPLICA IDENTITY` is set correctly on `messages` and `chats`

Supabase Realtime needs `REPLICA IDENTITY` to know which columns to include in change payloads. Without this, INSERT events can still fire but may not carry the right data for proper filtering:

```sql
ALTER TABLE public.messages REPLICA IDENTITY FULL;
ALTER TABLE public.chats REPLICA IDENTITY FULL;
```

---

### Step 4 — Re-confirm the publication is correct

Run the same check query from Step 1 again:

```sql
SELECT schemaname, tablename
FROM pg_publication_tables
WHERE pubname = 'supabase_realtime'
ORDER BY tablename;
```

**Expected result — exactly these 5 rows:**
```
chats
follows
messages
notifications
profiles
```

If you see all 5, realtime is correctly configured.

---

### Step 5 — Double check RLS policies are exactly as in v2 (not overwritten by v1 running after v2)

Run this to see all currently active SELECT/INSERT policies on `messages` and `chats`:

```sql
SELECT tablename, policyname, cmd, qual, with_check
FROM pg_policies
WHERE tablename IN ('messages', 'chats')
ORDER BY tablename, cmd;
```

**Expected policies (4 total):**
- `chats` SELECT: `Users can read their chats`
- `chats` INSERT: `Users can insert their chats`
- `messages` SELECT: `Users can read messages in their chats`
- `messages` INSERT: `Users can insert messages in their chats`

If you see **duplicate policy names** or **extra/conflicting policies** from the old `supabase_schema.sql` (which uses `friend_requests`/`friendships` instead of `follows`), they need to be dropped:

```sql
-- Run ONLY if you see old/duplicate policies referencing friend_requests or friendships:
DROP POLICY IF EXISTS "Users can read messages in their chats" ON public.messages;
DROP POLICY IF EXISTS "Users can insert messages in their chats" ON public.messages;
DROP POLICY IF EXISTS "Users can read their chats" ON public.chats;
DROP POLICY IF EXISTS "Users can insert their chats" ON public.chats;

-- Then re-run ONLY the v2 policy block:
CREATE POLICY "Users can read their chats" ON public.chats FOR SELECT USING (auth.uid() = user1_id OR auth.uid() = user2_id);
CREATE POLICY "Users can insert their chats" ON public.chats FOR INSERT WITH CHECK (auth.uid() = user1_id OR auth.uid() = user2_id);
CREATE POLICY "Users can read messages in their chats" ON public.messages FOR SELECT USING (
  EXISTS (SELECT 1 FROM public.chats c WHERE c.id = chat_id AND (c.user1_id = auth.uid() OR c.user2_id = auth.uid()))
);
CREATE POLICY "Users can insert messages in their chats" ON public.messages FOR INSERT WITH CHECK (
  auth.uid() = sender_id AND
  EXISTS (SELECT 1 FROM public.chats c WHERE c.id = chat_id AND (c.user1_id = auth.uid() OR c.user2_id = auth.uid()))
);
```

---

## Flutter-Side Hardening (Optional but Recommended)

Even with Supabase fixed, add these two small resilience improvements so messages still show up even if realtime has a brief hiccup:

### Add Optimistic Send (message appears instantly for the sender, doesn't wait for realtime)

**File:** `lib/screens/dm_chat_screen.dart` — `_send()`

```dart
Future<void> _send() async {
  final text = _inputCtrl.text.trim();
  if (text.isEmpty || _sending) return;
  HapticFeedback.lightImpact();

  final myId = _supabase.auth.currentUser?.id ?? '';
  final tempId = 'temp-${DateTime.now().millisecondsSinceEpoch}';

  // Optimistically add to the list immediately — don't wait for Supabase or realtime
  final optimisticMsg = ChatMessage(
    id: tempId,
    chatId: widget.chatId,
    senderId: myId,
    message: text,
    isRead: false,
    createdAt: DateTime.now(),
  );

  setState(() {
    _messages.add(optimisticMsg);
    _sending = true;
  });
  _inputCtrl.clear();
  _scrollToBottom();

  try {
    await _chatService.sendDM(widget.chatId, text);
    // Real message will arrive via realtime and _loadMessages() will replace the list,
    // naturally removing the temp message since it reloads from Supabase.
  } catch (e) {
    // Send failed — remove the optimistic message and show error
    if (mounted) {
      setState(() => _messages.removeWhere((m) => m.id == tempId));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message failed to send. Try again.')),
      );
    }
  } finally {
    if (mounted) setState(() => _sending = false);
  }
}
```

### Add a Periodic Fallback Refresh (in case realtime drops silently)

**File:** `lib/screens/dm_chat_screen.dart` — `initState()`

```dart
Timer? _fallbackPoll;

@override
void initState() {
  super.initState();
  _loadMessages();
  _subscribeRealtime();

  // Fallback: refresh every 5 seconds in case realtime silently disconnects
  _fallbackPoll = Timer.periodic(const Duration(seconds: 5), (_) => _loadMessages());
}

@override
void dispose() {
  _inputCtrl.dispose();
  _scrollCtrl.dispose();
  _channel?.unsubscribe();
  _sub?.cancel();
  _fallbackPoll?.cancel();   // ← ADD THIS
  super.dispose();
}
```

> This polling is lightweight (one `SELECT` every 5 seconds while the chat is open) and guarantees messages always sync even if realtime has issues — it's a safety net, not a replacement for the Step 1-5 Supabase fix above.

---

## 📁 Files / Places to Touch

| Location | Action |
|---|---|
| Supabase SQL Editor | Run Steps 1–5 above — rebuild publication, set REPLICA IDENTITY, verify/clean RLS policies |
| `lib/screens/dm_chat_screen.dart` | Add optimistic send in `_send()`, add fallback polling timer in `initState()`/`dispose()` |

**No changes needed** to `chat_service.dart`, `chat_models.dart`, or `follow_service.dart` — all already correct.

---

## ✅ Verification Steps

1. **Run the Step 1 query first** — confirm `chats` and/or `messages` are currently missing from `supabase_realtime`
2. **Run Steps 2–4** — rebuild the publication, confirm all 5 tables appear
3. **Run Step 5** — confirm no duplicate/conflicting RLS policies exist
4. **Test on 2 real devices (or 2 accounts):**
   - Device A and Device B both follow each other and accept
   - Device A sends "Hello" — it should appear instantly on Device A's screen (optimistic)
   - Device B's chat screen, if already open, should show "Hello" within 1-2 seconds (realtime)
   - Close and reopen Device B's app, open the chat — "Hello" should be there (confirms it was actually saved to Supabase, not just shown locally)
5. **Test the chat list refresh:** After Device A and Device B accept a follow request for the first time, both should see the new conversation appear in their Messages list without needing to force-close the app

---

## ⚠️ Notes for Antigravity

1. **This is the most common Supabase gotcha** — anytime you `DROP PUBLICATION IF EXISTS supabase_realtime` and recreate it, you MUST include every table the app needs in realtime, in that same statement. Forgetting even one table (like `chats` here) silently breaks that table's realtime without any error message anywhere in the app or Supabase logs.

2. **Going forward, never use `DROP PUBLICATION` + `CREATE PUBLICATION` in new schema files.** Use `ALTER PUBLICATION supabase_realtime ADD TABLE public.new_table;` instead — this is additive and won't ever wipe out previously configured tables.

3. **If after these fixes messages still don't sync,** check the Supabase Dashboard → Database → Replication tab and confirm the `supabase_realtime` publication shows `chats` and `messages` with toggles ON. Occasionally the dashboard UI and raw SQL state can drift, and toggling it off/on there resolves it.
