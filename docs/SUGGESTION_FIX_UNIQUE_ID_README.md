# 🔍 Friend Suggestion Fix — Unique ID Based Discovery

## Root Cause (The Real Problem)

After reading the code, **the #1 reason your friend is invisible** is this:

In `lib/providers/auth_provider.dart`, `signUpWithEmail()` only does:

```dart
await _supabase.auth.signUp(email: email, password: password);
// ← STOPS HERE. Never creates a profiles row.
```

The user is created in **Supabase Auth** (the `auth.users` table) but **no row is inserted into the `public.profiles` table**. Every suggestion query, friend search, and chat lookup reads from `public.profiles` — so the new user is completely invisible to everyone.

This is the cause of Reason #4 from your diagnosis. All the other reasons are secondary.

---

## The Full Fix — 3 Parts

### Part 1 — Supabase: Auto-create profile on signup (Database Trigger)

This is the most reliable fix. Add a PostgreSQL trigger in Supabase so every new auth signup **automatically** inserts a row into `profiles`.

**Run this in your Supabase SQL Editor:**

```sql
-- 1. Function that fires on new auth user
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (
    id,
    full_name,
    username,
    avatar_url,
    created_at,
    updated_at
  )
  VALUES (
    NEW.id,                                          -- Supabase Auth UUID (unique per user)
    COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
    split_part(NEW.email, '@', 1),                   -- username = email prefix
    NULL,
    NOW(),
    NOW()
  )
  ON CONFLICT (id) DO NOTHING;                       -- safe to re-run, never duplicates
  RETURN NEW;
END;
$$;

-- 2. Attach trigger to auth.users table
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();
```

> After adding this trigger, **every future signup automatically gets a profiles row** with the Supabase Auth UUID as their unique ID. Existing users who signed up before this trigger will still be missing — fix them with Part 1B below.

**Part 1B — Backfill existing users who have no profile row:**

```sql
-- Insert profiles for all auth users who don't have one yet
INSERT INTO public.profiles (id, full_name, username, created_at, updated_at)
SELECT
  au.id,
  COALESCE(au.raw_user_meta_data->>'full_name', split_part(au.email, '@', 1)),
  split_part(au.email, '@', 1),
  NOW(),
  NOW()
FROM auth.users au
LEFT JOIN public.profiles p ON p.id = au.id
WHERE p.id IS NULL
ON CONFLICT (id) DO NOTHING;
```

Run this once after adding the trigger. This creates profile rows for Sudeep and any friends who already signed up.

---

### Part 2 — Supabase: Fix RLS so users can see each other

Even after profiles exist, Supabase Row Level Security (RLS) blocks all cross-user reads by default.

**Run this in your Supabase SQL Editor:**

```sql
-- Allow any logged-in user to read all profiles (needed for suggestions)
CREATE POLICY "Users can view all profiles"
ON public.profiles
FOR SELECT
TO authenticated
USING (true);

-- Allow users to update only their own profile
CREATE POLICY "Users can update their own profile"
ON public.profiles
FOR UPDATE
TO authenticated
USING (auth.uid() = id);

-- Allow the trigger to insert (service role already has access, but be explicit)
CREATE POLICY "Users can insert their own profile"
ON public.profiles
FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = id);
```

> If you already have conflicting policies, run `DROP POLICY IF EXISTS "policy_name" ON public.profiles;` first.

---

### Part 3 — Flutter: Fix `signUpWithEmail()` to also upsert profile

Even with the database trigger, add a Flutter-side upsert as a safety net (trigger can fail silently):

**In `lib/providers/auth_provider.dart`:**

```dart
Future<void> signUpWithEmail(String email, String password) async {
  try {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
    );

    // Safety net: upsert profile row in case DB trigger didn't fire
    final userId = response.user?.id;
    if (userId != null) {
      await _ensureProfileExists(userId, email);
    }
  } catch (e) {
    debugPrint("Error signing up with Email: $e");
    rethrow;
  }
}

// Also call this on sign-in (handles users who signed up before the trigger existed)
Future<void> signInWithEmail(String email, String password) async {
  try {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    final userId = response.user?.id;
    if (userId != null) {
      await _ensureProfileExists(userId, email);
    }
  } catch (e) {
    debugPrint("Error signing in with Email: $e");
    rethrow;
  }
}

// Upserts a minimal profile row — safe to call on every login
Future<void> _ensureProfileExists(String userId, String email) async {
  try {
    final username = email.split('@')[0];
    await _supabase.from('profiles').upsert(
      {
        'id': userId,                  // Supabase Auth UUID — THE unique ID
        'username': username,
        'full_name': username,
        'updated_at': DateTime.now().toIso8601String(),
      },
      onConflict: 'id',               // if row exists, update updated_at only
      ignoreDuplicates: false,
    );
    debugPrint('✅ Profile ensured for $userId');
  } catch (e) {
    debugPrint('⚠️ _ensureProfileExists error (non-fatal): $e');
    // Non-fatal — don't rethrow, let login proceed
  }
}
```

---

## How the Unique ID System Works

Every user in your app already has a **Supabase Auth UUID** — a unique ID like `f47ac10b-58cc-4372-a567-0e02b2c3d479`. This is assigned automatically by Supabase when a user signs up and **never changes**. It is used as the primary key (`id`) in `profiles`, `friendships`, `friend_requests`, and `chats`.

```
User signs up
    ↓
Supabase Auth creates: auth.users.id = "f47ac10b-..." (UUID, globally unique)
    ↓
DB Trigger fires → inserts profiles row with id = "f47ac10b-..."
    ↓
getSuggestions() queries profiles WHERE id NOT IN (excluded list)
    ↓
Your friend's profile appears in suggestions ✅
```

The UUID is the identity. The suggestion system already queries by this UUID. The only missing piece was that the `profiles` row was never being created.

---

## Part 4 — Flutter: Add Pull-to-Refresh on Dashboard Suggestions

Currently `loadSuggestions()` only runs once at app startup. Add a refresh so the user doesn't need to restart the app to see new users.

**In `lib/widgets/people_suggestion_section.dart`:**

```dart
// Wrap the horizontal list with RefreshIndicator, OR add a refresh icon button:
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    _SectionHeader(title: 'People You May Know', icon: Icons.people_rounded),
    GestureDetector(
      onTap: () => context.read<FriendProvider>().loadSuggestions(),
      child: Icon(Icons.refresh_rounded, size: 18, color: AppColors.textSecondary),
    ),
  ],
),
```

This lets Sudeep tap refresh without restarting the app after a friend signs up.

---

## 📋 Task Split

### ✅ Sudeep's job (Supabase SQL Editor — do this yourself, takes 2 minutes)

1. Open **Supabase Dashboard → SQL Editor**
2. Run **Part 1** SQL (trigger + function)
3. Run **Part 1B** SQL (backfill existing users)
4. Run **Part 2** SQL (RLS policies)
5. Test: go to **Table Editor → profiles** — you should now see rows for yourself and your friend

### 🛠️ Antigravity's job (Flutter code)

1. Update `signUpWithEmail()` in `auth_provider.dart` — add `_ensureProfileExists()` call
2. Update `signInWithEmail()` in `auth_provider.dart` — add `_ensureProfileExists()` call
3. Add `_ensureProfileExists()` private method
4. Add the refresh button to `PeopleSuggestionSection`

---

## 📁 Files to Touch

| File | Change |
|---|---|
| Supabase SQL Editor | Run trigger SQL + backfill SQL + RLS policy SQL |
| `lib/providers/auth_provider.dart` | Add `_ensureProfileExists()`, call it in `signUpWithEmail()` and `signInWithEmail()` |
| `lib/widgets/people_suggestion_section.dart` | Add refresh button next to section header |

**No changes needed** to `FriendService`, `FriendProvider`, or `getSuggestions()` — the query logic is correct. The problem is upstream (missing profile rows).

---

## ✅ Verification Steps (Do in this exact order)

1. Run all SQL scripts in Supabase → check **Table Editor → profiles** for rows
2. Hot-restart the Flutter app on your phone
3. Have your friend hot-restart on their phone
4. Your friend should appear in your "People You May Know" section
5. Tap **Follow** → friend sees it in their Notifications
6. Friend accepts → chat appears in both Messages screens
7. Sign up a brand new test account → their profile should appear in suggestions within seconds (no restart needed after refresh button is tapped)

---

## ⚠️ Important Notes for Antigravity

1. **The Supabase Auth UUID is already the unique ID** — do not create a separate ID system. `auth.users.id` = `profiles.id` is the design. Every table (`friend_requests`, `friendships`, `chats`) already uses this UUID as the foreign key.

2. **The DB trigger is the permanent fix** — the Flutter `_ensureProfileExists()` is a safety net only. Both should be implemented.

3. **`ON CONFLICT (id) DO NOTHING`** in the trigger means it is completely safe to re-run. It will never create duplicate profiles.

4. **The backfill SQL (Part 1B) should be run exactly once.** After that, the trigger handles all future signups automatically.
