# 🔔 Notifications Section — Full Audit & Integration Guide

## Current State Summary

| Layer | Status |
|---|---|
| Screen UI (tiles, sections, empty state) | ✅ Well built |
| Follow request accept / reject | ✅ Works |
| Mark all read (Supabase) | ✅ Works |
| Mark single read (optimistic) | ✅ Works |
| Realtime — follow requests | ✅ Subscribed via `FollowService` |
| **Realtime — notifications table** | ❌ Not subscribed — new notifications don't appear without manual pull-to-refresh |
| **Bell badge count** | ❌ Shows generic red dot — never shows actual unread count |
| **Bell dot clears too early** | ❌ `markNotificationsRead()` fires *before* entering the screen — dot disappears before user actually reads |
| **`AppProvider.notifications` vs Supabase notifications table** | ❌ Two separate systems — local notifications (achievements, water, steps) never reach the Supabase table |
| **Notification types: community_post, post_like, challenge, run_complete** | ❌ Never inserted into Supabase `notifications` table from any screen |
| **Swipe to dismiss** | ❌ Missing |
| **Delete all** | ❌ Missing |
| **`message` type tap** → opens DM chat | ❌ Falls into `default` nav — does nothing |
| **`challenge` type tap** → opens ChallengeScreen | ❌ Goes to community tab (wrong screen) |
| **`run_complete`, `achievement`, `streak` types** | ❌ Missing icon/color/tap handling |
| **Supabase `notifications` table** | ⚠️ Assumed to exist but no CREATE TABLE SQL provided |
| **Unread count on app icon badge** | ❌ Missing |
| **`NotificationService` (local push)** | ⚠️ `scheduleSmartNudges()` is never called from anywhere |
| **Follow accept → DM redirect** | ⚠️ SnackBar fires but user must manually navigate to chat |

---

## 🔴 BROKEN — Wrong Behavior Right Now

### B1. Bell Badge Clears Before User Reads Anything

**File:** `lib/app.dart` — bell `onPressed`

**Problem:** The very first line of the bell `onPressed` calls `app.markNotificationsRead()`, which sets `hasUnreadNotifications = false` and removes the red dot *immediately*, before the user has seen a single notification.

```dart
// Current (WRONG):
onPressed: () {
  app.markNotificationsRead();  // ← clears dot BEFORE screen opens
  Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
},
```

**Fix:** Remove the premature clear. Let `NotificationsScreen` clear the dot when it finishes loading:

```dart
// In app.dart — just navigate, don't pre-clear:
onPressed: () {
  Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
},

// In NotificationsScreen — after _loadNotifications() completes, update provider:
Future<void> _loadNotifications() async {
  // ... existing fetch code ...
  if (mounted) {
    setState(() => _notifications = List<Map<String, dynamic>>.from(res as List));
    // Now clear the badge — user is actually on the screen
    context.read<AppProvider>().markNotificationsRead();
  }
}
```

---

### B2. Bell Badge Shows Dot Only — Never Shows Unread Count

**File:** `lib/app.dart` — bell Stack widget

**Problem:** The red dot is 8×8px with no number. When the user has 12 unread notifications, they see the same dot as when they have 1.

**Fix:** Show the count (capped at 99):

```dart
// Replace the dot Container with a count badge:
if (app.hasUnreadNotifications)
  Positioned(
    right: 6,
    top: 6,
    child: Container(
      padding: const EdgeInsets.all(2),
      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
      decoration: const BoxDecoration(
        color: AppColors.coral,
        shape: BoxShape.circle,
      ),
      child: Text(
        app.unreadNotificationCount > 99 ? '99+' : '${app.unreadNotificationCount}',
        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
    ),
  ),
```

Add `unreadNotificationCount` getter to `AppProvider`:
```dart
// In AppProvider:
int get unreadNotificationCount {
  // Primary source: Supabase-backed count (set after _loadNotifications)
  return _supabaseUnreadCount;
}
int _supabaseUnreadCount = 0;

void setUnreadCount(int count) {
  _supabaseUnreadCount = count;
  hasUnreadNotifications = count > 0;
  notifyListeners();
}
```

In `NotificationsScreen._loadNotifications()`, after fetching, update the count:
```dart
final unreadCount = (res as List).where((n) => !(n['is_read'] as bool? ?? false)).length;
if (mounted) context.read<AppProvider>().setUnreadCount(unreadCount);
```

---

### B3. Realtime Subscription Only Watches `follows` Table — Not `notifications` Table

**File:** `lib/screens/notifications_screen.dart` — `_subscribeRealtime()`

**Problem:**
```dart
void _subscribeRealtime() {
  _channel = _followService.subscribeToIncomingRequests(
    onAnyChange: _loadRequests,   // ← only reloads follow requests
  );
  // ← notifications table has NO realtime subscription
}
```

When someone likes your post, accepts your follow, or sends a message, a row is inserted into the `notifications` table — but the screen never reacts to it. The user has to pull-to-refresh manually.

**Fix:** Subscribe to the `notifications` table as well:

```dart
RealtimeChannel? _channel;
RealtimeChannel? _notifChannel;  // ADD THIS

void _subscribeRealtime() {
  // Existing: follow requests
  _channel = _followService.subscribeToIncomingRequests(
    onAnyChange: _loadRequests,
  );

  // NEW: notifications table realtime
  final uid = _supabase.auth.currentUser?.id;
  if (uid == null) return;

  _notifChannel = _supabase
      .channel('notifs-$uid')
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'notifications',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'user_id',
          value: uid,
        ),
        callback: (payload) {
          // Optimistically prepend new notification
          final newRow = payload.newRecord;
          if (mounted) {
            setState(() => _notifications.insert(0, newRow));
            context.read<AppProvider>().setUnreadCount(
              _notifications.where((n) => !(n['is_read'] as bool? ?? false)).length,
            );
          }
        },
      )
      .subscribe();
}

@override
void dispose() {
  _channel?.unsubscribe();
  _notifChannel?.unsubscribe();  // ADD THIS
  super.dispose();
}
```

---

### B4. `message` Type Tap Does Nothing

**File:** `lib/screens/notifications_screen.dart` — `onTap` handlers (lines 188–212 and 227–235)

**Problem:** The tap handler only routes `follow_*` and `community_post`/`challenge` types. `message` type falls into no branch — nothing happens.

**Fix:** Add `message` handling in both the unread and read tap handlers:

```dart
// Add this branch in BOTH onTap handlers:
} else if (type == 'message') {
  final chatId = notif['reference_id'] as String?;
  if (chatId != null) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => DmChatScreen(chatId: chatId),
    ));
  }
}
```

Add import: `import 'dm_chat_screen.dart';`

---

### B5. `challenge` Type Tap Goes to Community Tab (Wrong Screen)

**File:** `lib/screens/notifications_screen.dart` — `onTap` handler

**Problem:**
```dart
} else if (type == 'community_post' || type == 'post_like' || type == 'challenge') {
  context.read<AppProvider>().setTabIndex(3); // Community tab — WRONG for challenge
  Navigator.pop(context);
}
```

A challenge notification should open `ChallengeScreen`, not the Community tab.

**Fix:** Split the routing:
```dart
} else if (type == 'community_post' || type == 'post_like') {
  context.read<AppProvider>().setTabIndex(3); // Community tab
  Navigator.pop(context);
} else if (type == 'challenge' || type == 'challenge_complete') {
  Navigator.push(context, MaterialPageRoute(
    builder: (_) => const ChallengeScreen(),
  ));
}
```

Add import: `import 'challenge_screen.dart';`

---

### B6. Two Notification Systems That Don't Talk to Each Other

**File:** `lib/providers/app_provider.dart` — `addNotification()` vs `lib/screens/notifications_screen.dart` — `_loadNotifications()`

**Problem:**
- `AppProvider.addNotification()` adds to an in-memory `List<Map>` that is **local only** — achievements, water goal, steps goal all go here
- `NotificationsScreen._loadNotifications()` reads from the **Supabase** `notifications` table
- These are two completely separate systems. Local notifications from achievements never appear in the Notifications screen. The Notifications screen never shows the "Hydration Hero!" or "Streak saved!" local notifications.

**Fix:** Replace `AppProvider.addNotification()` to also insert into Supabase:

```dart
// In AppProvider:
Future<void> addNotification(String title, String body, {String type = 'achievement'}) async {
  final uid = Supabase.instance.client.auth.currentUser?.id;
  if (uid == null) return;

  // Insert to Supabase so it appears in NotificationsScreen
  try {
    await Supabase.instance.client.from('notifications').insert({
      'user_id': uid,
      'type': type,
      'title': title,
      'body': body,
      'is_read': false,
    });
  } catch (e) {
    debugPrint('addNotification Supabase error: $e');
  }

  // Keep local copy for immediate UI feedback (badge update)
  hasUnreadNotifications = true;
  _supabaseUnreadCount++;
  notifyListeners();
}
```

Update existing callers to use the new signature (remove `icon` and `color` params since those are derived from `type` in `_NotifTile`):
```dart
// Old:
addNotification('Hydration Hero! 💧', '...', LucideIcons.droplets, const Color(0xFF00E5CC), type: 'Reminders');

// New:
addNotification('Hydration Hero! 💧', 'You reached your daily water goal!', type: 'achievement');
```

---

## 🟡 MISSING — Not Built Yet

### M1. Supabase `notifications` Table May Not Exist

Run this in Supabase SQL Editor if the table doesn't exist:

```sql
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

CREATE INDEX notifications_user_id_idx ON public.notifications(user_id);
CREATE INDEX notifications_is_read_idx ON public.notifications(user_id, is_read);

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can read own notifications"
  ON public.notifications FOR SELECT TO authenticated USING (auth.uid() = user_id);
CREATE POLICY "Users can update own notifications"
  ON public.notifications FOR UPDATE TO authenticated USING (auth.uid() = user_id);
CREATE POLICY "Service can insert notifications"
  ON public.notifications FOR INSERT TO authenticated WITH CHECK (true);
```

---

### M2. Supabase DB Triggers That Auto-Insert Notifications

These events should automatically create a notification row via PostgreSQL triggers — so no Flutter code is needed for each case:

```sql
-- Trigger 1: New follow request → notify the target user
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

-- Trigger 2: Follow accepted → notify the requester
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

-- Trigger 3: New message → notify the receiver
CREATE OR REPLACE FUNCTION public.notify_new_message()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_receiver UUID;
  v_sender_name TEXT;
BEGIN
  -- Find the other participant in the chat
  SELECT participant_id INTO v_receiver
  FROM public.chat_participants
  WHERE chat_id = NEW.chat_id AND participant_id != NEW.sender_id
  LIMIT 1;

  SELECT COALESCE(full_name, username) INTO v_sender_name
  FROM public.profiles WHERE id = NEW.sender_id;

  IF v_receiver IS NOT NULL THEN
    INSERT INTO public.notifications(user_id, actor_id, type, title, body, reference_id)
    VALUES (
      v_receiver,
      NEW.sender_id,
      'message',
      v_sender_name,
      LEFT(NEW.content, 80),
      NEW.chat_id::TEXT
    );
  END IF;
  RETURN NEW;
END; $$;

DROP TRIGGER IF EXISTS on_new_message ON public.messages;
CREATE TRIGGER on_new_message
  AFTER INSERT ON public.messages
  FOR EACH ROW EXECUTE PROCEDURE public.notify_new_message();
```

> ⚠️ **Note for Antigravity:** The message trigger fires for EVERY message, which means the user gets spammed if they're actively chatting. Add a check: only insert if the receiver hasn't read the chat in the last 60 seconds (check `last_read_at` on `chat_participants`). Or suppress it when the receiver's app is in foreground — this is advanced, so a simpler fix is to deduplicate: don't insert if there's already an unread `message` notification from the same sender in the last 5 minutes.

---

### M3. Missing `_NotifTile` Icon + Color + Tap for New Types

**File:** `lib/screens/notifications_screen.dart` — `_NotifTile._icon()` and `_NotifTile._color()`

Current types handled: `follow_request`, `follow_accepted`, `new_follower`, `message`, `challenge`. 

Missing types that will arrive from the new DB triggers and `addNotification()` calls:

```dart
// In _NotifTile._icon():
IconData _icon() {
  switch (data['type'] as String?) {
    case 'follow_request':       return LucideIcons.userPlus;
    case 'follow_accepted':      return LucideIcons.userCheck;
    case 'new_follower':         return LucideIcons.users;
    case 'message':              return LucideIcons.messageCircle;
    case 'challenge':
    case 'challenge_complete':   return LucideIcons.trophy;
    case 'post_like':            return LucideIcons.heart;          // ADD
    case 'community_post':       return LucideIcons.fileText;       // ADD
    case 'run_complete':         return LucideIcons.mapPin;         // ADD
    case 'achievement':          return LucideIcons.medal;          // ADD
    case 'streak':               return LucideIcons.flame;          // ADD
    case 'goal_reached':         return LucideIcons.target;         // ADD
    default:                     return LucideIcons.bell;
  }
}

// In _NotifTile._color():
Color _color() {
  switch (data['type'] as String?) {
    case 'follow_request':
    case 'follow_accepted':
    case 'new_follower':    return AppColors.irisViolet;
    case 'message':         return AppColors.voltCyan;
    case 'challenge':
    case 'challenge_complete': return AppColors.solarAmber;
    case 'post_like':       return AppColors.pulseRed;       // ADD
    case 'community_post':  return AppColors.primary;        // ADD
    case 'run_complete':    return AppColors.green;          // ADD
    case 'achievement':     return AppColors.solarAmber;     // ADD
    case 'streak':          return AppColors.solarAmber;     // ADD
    case 'goal_reached':    return AppColors.voltCyan;       // ADD
    default:                return AppColors.primary;
  }
}
```

Also add tap routing for the new types in both `onTap` handlers:
```dart
} else if (type == 'run_complete') {
  Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen()));
} else if (type == 'achievement' || type == 'goal_reached' || type == 'streak') {
  Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
} else if (type == 'post_like' || type == 'community_post') {
  context.read<AppProvider>().setTabIndex(3);
  Navigator.pop(context);
}
```

---

### M4. Swipe-to-Dismiss on Notification Tiles

**File:** `lib/screens/notifications_screen.dart` — `_NotifTile`

**Missing:** No way to dismiss individual notifications without opening them.

**Fix:** Wrap the tile in `Dismissible`:

```dart
// In both SliverChildBuilderDelegate itemBuilder — wrap _NotifTile:
Dismissible(
  key: ValueKey(data['id']),
  direction: DismissDirection.endToStart,
  background: Container(
    alignment: Alignment.centerRight,
    padding: const EdgeInsets.only(right: 20),
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
    decoration: BoxDecoration(
      color: AppColors.pulseRed.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(16),
    ),
    child: const Icon(LucideIcons.trash2, color: AppColors.pulseRed),
  ),
  onDismissed: (_) async {
    final id = data['id'] as String;
    setState(() => _notifications.removeWhere((n) => n['id'] == id));
    await _supabase.from('notifications').delete().eq('id', id);
  },
  child: _NotifTile(...),
),
```

---

### M5. Delete All / Clear Notifications Button

**File:** `lib/screens/notifications_screen.dart` — `AppBar actions`

**Missing:** No way to clear all read notifications at once.

**Fix:** Add a "Clear read" button to the AppBar:

```dart
// In AppBar actions — add alongside existing "Mark all read":
if (read.isNotEmpty)
  TextButton(
    onPressed: () async {
      final uid = _supabase.auth.currentUser?.id;
      if (uid == null) return;
      await _supabase
          .from('notifications')
          .delete()
          .eq('user_id', uid)
          .eq('is_read', true);
      setState(() => _notifications.removeWhere((n) => n['is_read'] as bool? ?? false));
    },
    child: Text(
      'Clear read',
      style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
    ),
  ),
```

---

### M6. `NotificationService.scheduleSmartNudges()` Is Never Called

**File:** `lib/services/notification_service.dart`

**Problem:** `scheduleSmartNudges()` exists with logic for 3 nudges (water at 14:00, sleep at 22:00, steps at 12:00) but is never called anywhere.

**Fix — Call from `AppProvider.startLiveSimulation()`:**

```dart
// In AppProvider.startLiveSimulation() — inside the Timer.periodic:
_liveTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
  if (heartRate == 0) heartRate = 60;
  final rng = Random();
  heartRate = (heartRate + rng.nextInt(7) - 3).clamp(55, 100);
  notifyListeners();
  _saveData();

  // Smart nudges — checks hour internally, fires at most once/day per nudge
  await NotificationService.scheduleSmartNudges(this);   // ← ADD THIS
});
```

Also wire the `scheduleSmartNudges` nudges to also insert into the Supabase `notifications` table (so they appear in-app as well as push notifications):

```dart
// In NotificationService.scheduleSmartNudges() — after each _notificationsPlugin.show():
await Supabase.instance.client.from('notifications').insert({
  'user_id': uid,
  'type': 'goal_reached',
  'title': "Don't forget to hydrate! 💧",
  'body': "You've only had ${app.waterGlasses} glasses — drink up!",
  'is_read': false,
});
```

---

## 🔗 INTEGRATION — Cross-Screen Wiring

### I1. Running Screen → Insert `run_complete` Notification

**File:** `lib/screens/running_screen.dart` — `_saveRun()` or `_endRun()`

After saving a run to Supabase, insert a notification:

```dart
// After successful run save:
await Supabase.instance.client.from('notifications').insert({
  'user_id': uid,
  'type': 'run_complete',
  'title': 'Run Completed! 🏃',
  'body': 'You ran ${_distance.toStringAsFixed(2)} km in ${_formatDuration(_elapsedSeconds)}',
  'is_read': false,
});
// Also trigger local push:
await NotificationService.showNotification('Run Completed! 🏃', 'You ran ${_distance.toStringAsFixed(2)} km');
```

---

### I2. Challenge Screen → Insert `challenge_complete` Notification

**File:** `lib/services/challenge_service.dart` — `updateProgress()`

When a challenge's `current_value` reaches `target_value`, mark complete and notify:

```dart
// After updating progress, check completion:
if (newValue >= (challenge['target_value'] as num).toDouble()) {
  await _client.from('challenge_participants')
      .update({'completed_at': DateTime.now().toIso8601String()})
      .eq('challenge_id', challengeId)
      .eq('user_id', uid);

  await _client.from('notifications').insert({
    'user_id': uid,
    'type': 'challenge_complete',
    'title': 'Challenge Completed! 🏆',
    'body': 'You completed "${challenge['title']}" — check your rank!',
    'reference_id': challengeId,
    'is_read': false,
  });
}
```

---

### I3. Community Screen → Insert `post_like` Notification

**File:** `lib/services/community_service.dart` — `likePost()`

When a user likes a post, notify the post author:

```dart
Future<void> likePost(String postId, String postAuthorId) async {
  final uid = _client.auth.currentUser?.id;
  if (uid == null || uid == postAuthorId) return; // don't notify self-likes

  await _client.rpc('increment_likes', params: {'post_id': postId});

  // Notify the post author
  await _client.from('notifications').insert({
    'user_id': postAuthorId,
    'actor_id': uid,
    'type': 'post_like',
    'title': 'Someone liked your post ❤️',
    'body': 'Check out the reactions on your post',
    'reference_id': postId,
    'is_read': false,
  });
}
```

---

### I4. Study Screen → Insert `achievement` Notification on Streak Milestone

**File:** `lib/screens/study_screen.dart` — when study session completes

```dart
// After study session recorded — check for streak milestone:
final studyStreak = context.read<AppProvider>().studyStreak;
if (studyStreak > 0 && studyStreak % 7 == 0) {
  await context.read<AppProvider>().addNotification(
    '📚 $studyStreak-Day Study Streak!',
    'You\'ve studied for $studyStreak days in a row. Keep it up!',
    type: 'streak',
  );
}
```

---

### I5. AppProvider → `addNotification()` for Existing Achievement Events

**File:** `lib/providers/app_provider.dart` — existing achievement/goal logic

Update the existing `addNotification()` calls to use the new Supabase-backed version:

```dart
// Water goal (line 691) — already calls addNotification, just update signature:
addNotification(
  'Hydration Hero! 💧',
  'You reached your daily water goal of $waterGlassGoal glasses!',
  type: 'achievement',
);

// Streak milestone — add after updateStreak() increments currentStreak:
if (currentStreak > 0 && currentStreak % 7 == 0) {
  addNotification(
    '🔥 ${currentStreak}-Day Streak!',
    'You\'ve been active for $currentStreak days in a row!',
    type: 'streak',
  );
}
```

---

### I6. Follow Accept → Auto-Navigate to DM Chat

**File:** `lib/screens/notifications_screen.dart` — `_accept()`

After accepting a follow request, a chat room is created (via the `accept_follow_request` RPC). Show a SnackBar with a "Say Hi →" action that navigates to the new chat:

```dart
Future<void> _accept(String followId, String name) async {
  HapticFeedback.mediumImpact();
  final ok = await _followService.acceptFollowRequest(followId);
  if (!mounted) return;
  if (ok) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('You accepted $name\'s follow request! 🎉'),
      backgroundColor: AppColors.irisViolet,
      behavior: SnackBarBehavior.floating,
      action: SnackBarAction(
        label: 'Say Hi →',
        textColor: Colors.white,
        onPressed: () async {
          // Find the new chat created by the RPC
          final uid = _supabase.auth.currentUser?.id;
          final chats = await _supabase
              .from('chat_participants')
              .select('chat_id')
              .eq('participant_id', uid!)
              .order('created_at', ascending: false)
              .limit(1);
          if (chats.isNotEmpty && mounted) {
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => DmChatScreen(chatId: chats.first['chat_id'] as String),
            ));
          }
        },
      ),
    ));
    _loadRequests();
  }
}
```

---

### I7. AppShell — Load Unread Count on App Start

**File:** `lib/app.dart` — `_AppShellState.initState()`

Currently the bell dot state comes from `AppProvider.hasUnreadNotifications` which defaults to `true` (hardcoded). The real count should be loaded from Supabase on startup:

```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    Permission.notification.request();
    context.read<AppProvider>().syncProfileWithSupabase();
    _loadInitialUnreadCount();  // ADD THIS
  });
}

Future<void> _loadInitialUnreadCount() async {
  final uid = Supabase.instance.client.auth.currentUser?.id;
  if (uid == null) return;
  try {
    final res = await Supabase.instance.client
        .from('notifications')
        .select('id')
        .eq('user_id', uid)
        .eq('is_read', false);
    if (mounted) {
      context.read<AppProvider>().setUnreadCount((res as List).length);
    }
  } catch (_) {}
}
```

---

## 📁 Files to Create / Modify

| File | Action |
|---|---|
| Supabase SQL Editor | Create `notifications` table + RLS + 3 DB triggers (follow_request, follow_accepted, new_message) |
| `lib/app.dart` | Fix bell badge count, remove premature `markNotificationsRead()`, add `_loadInitialUnreadCount()` |
| `lib/providers/app_provider.dart` | Add `unreadNotificationCount`, `setUnreadCount()`, update `addNotification()` to write to Supabase, wire `scheduleSmartNudges()` |
| `lib/screens/notifications_screen.dart` | Add notifications realtime channel, swipe-to-dismiss, delete-read button, fix `challenge` tap routing, fix `message` tap, add missing icon/color/tap for 6 new types, call `setUnreadCount` after load |
| `lib/screens/running_screen.dart` | Insert `run_complete` notification after run save |
| `lib/services/challenge_service.dart` | Insert `challenge_complete` notification when progress hits target |
| `lib/services/community_service.dart` | Insert `post_like` notification in `likePost()` |
| `lib/screens/study_screen.dart` | Insert `streak` notification on study streak milestones |

---

## ✅ Verification Checklist

**Broken fixes:**
- [ ] Bell badge shows number (e.g. "3"), not just a dot
- [ ] Badge number decrements when notifications are read
- [ ] Bell dot stays visible when navigating TO the screen, disappears only after page loads
- [ ] Tapping a `message` notification → opens the DM chat for that conversation
- [ ] Tapping a `challenge` notification → opens ChallengeScreen, not Community tab
- [ ] New notifications appear in real-time without pull-to-refresh

**Missing features:**
- [ ] Supabase `notifications` table exists with correct columns
- [ ] Sending a follow request → target user instantly sees it in Notifications (realtime)
- [ ] Accepting a follow → requester gets a `follow_accepted` notification (realtime)
- [ ] Swipe left on a notification → dismisses + deletes from Supabase
- [ ] "Clear read" button removes all read notifications
- [ ] Completing a run → `run_complete` notification appears
- [ ] Completing a challenge → `challenge_complete` notification appears
- [ ] Liking a post → post author gets `post_like` notification
- [ ] Water goal reached → `achievement` notification appears in notification center (not just a local dialog)
- [ ] Study streak milestone → `streak` notification appears

**Integration:**
- [ ] App starts → bell badge shows correct unread count from Supabase (not always `true`)
- [ ] Accept follow → SnackBar with "Say Hi →" action navigates to new chat
- [ ] `scheduleSmartNudges()` fires at 12:00, 14:00, 22:00 with correct conditions
