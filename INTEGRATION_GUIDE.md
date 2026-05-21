# LifePulse Social System — Integration Guide

## What's in this update

| File | What it does |
|---|---|
| `supabase_schema_v2.sql` | Complete DB schema — run this once in Supabase SQL Editor |
| `login_screen.dart` | Full sign-up form: full name, username (live check), email, password + confirm, mobile (optional) |
| `follow_service.dart` | Replaces `friend_service.dart` — Instagram-style follow/unfollow, counts, search |
| `profile_screen.dart` | Live followers/following counters, tappable lists, follow button |
| `notifications_screen.dart` | Follow requests (accept/reject) + app notifications from DB |
| `dm_chat_screen.dart` | Username search bar to start chats, 1-on-1 messaging |
| `people_suggestion_section.dart` | Horizontal suggestion cards with follow buttons |

---

## Step 1 — Run the SQL

In your Supabase dashboard → **SQL Editor** → paste the entire `supabase_schema_v2.sql` and click **Run**.

> ⚠️ If you already have the old `friend_requests` / `friendships` tables in production, keep them. The new system uses the `follows` table exclusively. Drop the old tables only when you're done migrating.

---

## Step 2 — Copy files into your project

```
lib/
  screens/
    login_screen.dart          ← replace existing
    profile_screen.dart        ← replace existing
    notifications_screen.dart  ← replace existing
    dm_chat_screen.dart        ← replace existing
  services/
    follow_service.dart        ← ADD (replaces friend_service.dart references)
  widgets/
    people_suggestion_section.dart  ← replace existing
```

---

## Step 3 — Update import paths

Each file has a comment at the top like `// adjust import path`. Fix these to match your project structure. For example:

```dart
import '../services/follow_service.dart';  // if it's in lib/services/
```

---

## Step 4 — Update `chat_service.dart`

The `getMessages` method is called in `dm_chat_screen.dart`. Add it to your existing `ChatService` if it's not already there:

```dart
Future<List<ChatMessage>> getMessages(String chatId) async {
  final data = await _supabase
      .from('messages')
      .select()
      .eq('chat_id', chatId)
      .order('created_at', ascending: true);
  return (data as List)
      .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
      .toList();
}
```

---

## Step 5 — Update `app.dart` / `main.dart` routing

Replace `FriendProvider` references with `FollowService` (which is not a ChangeNotifier — call it directly from screens). If you want a provider, wrap `FollowService` similarly to how `FriendProvider` was written.

---

## How the features work

### Username — locked after sign-up
- DB trigger `trg_lock_username` prevents any UPDATE to `username` column.
- SQL function `check_username_available('johndoe')` returns `true`/`false` — called live from the sign-up form as the user types (debounced 600ms).

### Follow requests
- User A taps **Follow** on User B's profile → row inserted in `follows` with `status = 'pending'`.
- User B sees the request in **Notifications** → taps **Accept** → `status` updated to `'accepted'`.
- DB trigger automatically: increments `followers_count` on B and `following_count` on A, creates a `chats` row, and inserts a `follow_accepted` notification for A.
- Rejecting or unfollowing deletes the row; trigger decrements counts if it was accepted.

### Followers / Following counts
- Stored in `profiles.followers_count` and `profiles.following_count`.
- Maintained entirely by DB triggers — never manually updated from Flutter.
- Live via Supabase Realtime (`subscribeToProfile`).

### Followers / Following lists
- Tap the counter on any profile → bottom sheet loads list via `get_followers(userId)` / `get_following(userId)` SQL functions.
- Each list item is tappable → opens that user's `ProfileScreen`.

### Chat search
- Tap the 🔍 icon in Messages → type a username.
- Calls `search_users_by_username(query, currentUserId)` — returns matching users with their follow status.
- If a chat room exists (both accepted each other's follow), opens the chat directly.
- If not connected yet, shows a hint to follow them first.

### People suggestions
- Calls `get_suggestions(currentUserId)` — returns users not yet followed, sorted by popularity.
- Horizontal scroll cards with instant Follow / Requested / Following states.

---

## Supabase RLS summary

| Table | Who can read | Who can write |
|---|---|---|
| profiles | Anyone | Owner only (no username change) |
| follows | follower or following | Insert: follower only; Update (accept/reject): following_id only; Delete: either party |
| chats | participants only | participants only |
| messages | chat participants | sender only |
| notifications | recipient only | anyone (trigger inserts) |
