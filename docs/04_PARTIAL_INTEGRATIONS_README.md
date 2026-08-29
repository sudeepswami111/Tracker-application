# 🟢 Partial / Incomplete Integrations

These features are partially built — the UI exists and some logic works, but a specific piece is missing that prevents the feature from fully functioning end-to-end.

---

## 1. Streak → Steps Integration (ProxyProvider Wiring Missing)

**File:** `lib/providers/step_tracker_provider.dart`, `lib/main.dart`

**Status:** `StepTrackerProvider` counts steps correctly. `AppProvider` has the `recordActivity()` / `updateStreak()` logic. But the two providers are **not connected** — walking never triggers a streak update.

**What's missing:** The `ChangeNotifierProxyProvider` wiring in `main.dart` and the threshold check in `step_tracker_provider.dart`.

**Fix — `lib/main.dart`:**

Find where `StepTrackerProvider` is declared in `MultiProvider` and replace it:
```dart
// Replace:
ChangeNotifierProvider(create: (_) => StepTrackerProvider()),

// With:
ChangeNotifierProxyProvider<AppProvider, StepTrackerProvider>(
  create: (_) => StepTrackerProvider(),
  update: (context, appProvider, stepTracker) {
    stepTracker?.setAppProvider(appProvider);
    return stepTracker ?? StepTrackerProvider();
  },
),
```

> ⚠️ `StepTrackerProvider` must be declared AFTER `AppProvider` in the `MultiProvider` list.

**Fix — `lib/providers/step_tracker_provider.dart`:**

```dart
// Add at top of class:
static const int _streakStepThreshold = 1000;
bool _streakRecordedToday = false;
AppProvider? _appProvider;

void setAppProvider(AppProvider appProvider) {
  _appProvider = appProvider;
}

// In onStepCount() — after _steps is updated, add:
if (!_streakRecordedToday &&
    _steps >= _streakStepThreshold &&
    _appProvider != null) {
  _streakRecordedToday = true;
  _appProvider!.recordActivity();
  if (kDebugMode) print('✅ Streak recorded via steps: $_steps steps');
}

// In the new-day detection branch (where _initialStepsForDay is reset), add:
_streakRecordedToday = false; // ← ADD THIS LINE
```

Add import at top of file: `import 'app_provider.dart';`

---

## 2. People Suggestion Section — Returns Empty (Supabase Not Set Up)

**File:** `lib/widgets/people_suggestion_section.dart`, Supabase dashboard

**Status:** `PeopleSuggestionSection` is placed on the dashboard and the widget renders. But `getSuggestions()` returns `[]` because:
- The `profiles` table has no RLS policy allowing cross-user reads
- New signups don't get a `profiles` row (DB trigger missing)

**What's missing:** The 3 SQL scripts from `SUGGESTION_FIX_UNIQUE_ID_README.md` haven't been run yet.

**Fix — Run in Supabase SQL Editor (in this order):**

**Script 1 — DB trigger (auto-creates profile on signup):**
```sql
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, username, created_at, updated_at)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
    split_part(NEW.email, '@', 1),
    NOW(), NOW()
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END; $$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();
```

**Script 2 — Backfill existing users:**
```sql
INSERT INTO public.profiles (id, full_name, username, created_at, updated_at)
SELECT au.id,
  COALESCE(au.raw_user_meta_data->>'full_name', split_part(au.email, '@', 1)),
  split_part(au.email, '@', 1), NOW(), NOW()
FROM auth.users au
LEFT JOIN public.profiles p ON p.id = au.id
WHERE p.id IS NULL
ON CONFLICT (id) DO NOTHING;
```

**Script 3 — RLS policies:**
```sql
CREATE POLICY "Users can view all profiles"
ON public.profiles FOR SELECT TO authenticated USING (true);

CREATE POLICY "Users can update their own profile"
ON public.profiles FOR UPDATE TO authenticated USING (auth.uid() = id);
```

After running these 3 scripts, hot-restart the app. Your friend's profile will appear in suggestions.

---

## 3. Daily Quote — Still Shows Hardcoded Single Quote

**File:** `lib/widgets/dashboard_fun_widgets.dart`

**Status:** `DailyQuoteSpark` widget is on the dashboard and the dialog opens correctly. But it still shows the same hardcoded quote every day: `"The only bad workout is the one that didn't happen."`

**What's missing:** The `_getTodaysQuote()` rotation logic and the quote list from `DAILY_QUOTE_FIX_README.md`.

**Fix:** Add this block **above** the `DailyQuoteSpark` class:

```dart
class _QuoteData {
  final String text;
  final String author;
  const _QuoteData(this.text, this.author);
}

const List<_QuoteData> _dailyQuotes = [
  _QuoteData("The only bad workout is the one that didn't happen.", "Unknown"),
  _QuoteData("Take care of your body. It's the only place you have to live.", "Jim Rohn"),
  _QuoteData("An early morning walk is a blessing for the whole day.", "Henry David Thoreau"),
  _QuoteData("Health is not about the weight you lose, but about the life you gain.", "Unknown"),
  _QuoteData("Movement is medicine for creating change in a person's physical, emotional, and mental states.", "Carol Welch"),
  _QuoteData("Your body can stand almost anything. It's your mind that you have to convince.", "Unknown"),
  _QuoteData("A one-hour workout is 4% of your day. No excuses.", "Unknown"),
  _QuoteData("Motivation is what gets you started. Habit is what keeps you going.", "Jim Ryun"),
  _QuoteData("If it doesn't challenge you, it doesn't change you.", "Fred DeVito"),
  _QuoteData("Push yourself because no one else is going to do it for you.", "Unknown"),
  _QuoteData("It's not about perfect. It's about effort.", "Jillian Michaels"),
  _QuoteData("Your health is an investment, not an expense.", "Unknown"),
  _QuoteData("Wake up with determination. Go to bed with satisfaction.", "Unknown"),
  _QuoteData("Don't count the days. Make the days count.", "Muhammad Ali"),
  _QuoteData("Energy and persistence conquer all things.", "Benjamin Franklin"),
  _QuoteData("What hurts today makes you stronger tomorrow.", "Jay Cutler"),
  _QuoteData("You don't have to be great to start, but you have to start to be great.", "Zig Ziglar"),
  _QuoteData("All progress takes place outside the comfort zone.", "Michael John Bobak"),
  _QuoteData("Once you see results, it becomes an addiction.", "Unknown"),
  _QuoteData("Strive for progress, not perfection.", "Unknown"),
  _QuoteData("You are one workout away from a good mood.", "Unknown"),
  _QuoteData("The pain you feel today will be the strength you feel tomorrow.", "Unknown"),
  _QuoteData("A healthy outside starts from the inside.", "Robert Urich"),
  _QuoteData("Every step is progress, no matter how small.", "Unknown"),
  _QuoteData("Do something today that your future self will thank you for.", "Sean Patrick Flanery"),
  _QuoteData("Strength does not come from physical capacity. It comes from an indomitable will.", "Mahatma Gandhi"),
  _QuoteData("The secret of getting ahead is getting started.", "Mark Twain"),
  _QuoteData("Take care of your body and your body will take care of you.", "Unknown"),
  _QuoteData("Your body is a reflection of your lifestyle.", "Unknown"),
  _QuoteData("Don't wish for it. Work for it.", "Unknown"),
];

_QuoteData _getTodaysQuote() {
  final now = DateTime.now();
  final dayOfYear = now.difference(DateTime(now.year)).inDays;
  return _dailyQuotes[dayOfYear % _dailyQuotes.length];
}
```

**Then in the dialog's `showDialog` body**, replace the hardcoded `Text('"The only bad workout..."')` with:
```dart
Builder(
  builder: (context) {
    final quote = _getTodaysQuote();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '"${quote.text}"',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '— ${quote.author}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  },
),
```

**Verify:** Change your phone date to tomorrow, reopen the dialog — different quote. Change back to today — original quote returns.

---

## 4. Running Screen — Share/Save Button at End of Run

**File:** `lib/screens/running_screen.dart:1518`

**Status:** The run summary screen shows after a run completes. A share button exists but `onPressed: () {}` — does nothing. The run IS saved to Supabase `running_activities` (this part works). Only the social sharing is missing.

**What's missing:** `share_plus` integration for the post-run share.

**Fix:**
```dart
onPressed: () async {
  final summary = 'Just completed a ${_distance.toStringAsFixed(2)} km run '
      'in ${_formatDuration(_elapsedSeconds)} at ${_avgPace} min/km on LifePulse! 🏃';
  await Share.share(summary);
},
```

Add `share_plus` to `pubspec.yaml`:
```yaml
share_plus: ^10.0.0
```

Add import: `import 'package:share_plus/share_plus.dart';`

---

## 5. Challenge Screen — Leaderboard Data Is Static

**File:** `lib/screens/challenge_screen.dart:181`

**Status:** `_showLeaderboard()` opens a `_LeaderboardSheet` bottom sheet — the sheet renders and looks good. But it shows static/hardcoded mock user rows instead of real data.

**What's missing:** A Supabase query for challenge participants ranked by progress.

**Fix — `_LeaderboardSheet`:** Replace the hardcoded list with a `FutureBuilder`:

```dart
// Supabase table needed: challenge_participants
// Fields: id, challenge_id, user_id, progress, joined_at
// JOIN with profiles for name + avatar

FutureBuilder<List>(
  future: Supabase.instance.client
      .from('challenge_participants')
      .select('progress, user:profiles!challenge_participants_user_id_fkey(full_name, avatar_url)')
      .eq('challenge_id', widget.challengeId)
      .order('progress', ascending: false)
      .limit(20),
  builder: (context, snap) {
    if (snap.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }
    final participants = (snap.data as List?) ?? [];
    if (participants.isEmpty) {
      return const Center(child: Text('No participants yet.'));
    }
    return ListView.builder(
      itemCount: participants.length,
      itemBuilder: (_, i) {
        final p = participants[i];
        final user = p['user'] as Map;
        return ListTile(
          leading: Text('#${i + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
          title: Text(user['full_name'] ?? 'Unknown'),
          trailing: Text('${p['progress']} pts',
              style: const TextStyle(color: AppColors.voltCyan, fontWeight: FontWeight.bold)),
        );
      },
    );
  },
),
```

**Supabase table needed:**
```sql
CREATE TABLE public.challenge_participants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  challenge_id UUID REFERENCES public.challenges(id) ON DELETE CASCADE,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  progress INT DEFAULT 0,
  joined_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(challenge_id, user_id)
);
```

---

## 6. Profile Screen — Avatar Upload Saves Locally (Not to Supabase Storage)

**File:** `lib/screens/profile_screen.dart` — `_pickImage()`, `lib/providers/app_provider.dart` — `updateProfileImagePath()`

**Status:** The user can tap their avatar and pick a photo from the gallery. The local file path is saved to `SharedPreferences`. The avatar updates visually on the current device. But:
- The `profiles.avatar_url` column in Supabase is never updated
- Other users viewing this profile (via `ProfileScreen(targetUserId: ...)`) see no avatar
- The avatar disappears if the user reinstalls the app

**What's missing:** Upload to Supabase Storage + update `profiles.avatar_url`.

**Fix — `_pickImage()` in `profile_screen.dart`:**

```dart
Future<void> _pickImage(AppProvider app) async {
  final picker = ImagePicker();
  final XFile? image = await picker.pickImage(
    source: ImageSource.gallery,
    imageQuality: 80,
    maxWidth: 400,
  );
  if (image == null || !mounted) return;

  try {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return;

    final bytes = await image.readAsBytes();
    final ext = image.path.split('.').last.toLowerCase();
    final storagePath = 'avatars/$uid.$ext';

    // 1. Upload to Supabase Storage
    await _supabase.storage
        .from('avatars')         // ← create this bucket in Supabase dashboard
        .uploadBinary(storagePath, bytes,
            fileOptions: FileOptions(upsert: true, contentType: 'image/$ext'));

    // 2. Get public URL
    final publicUrl = _supabase.storage
        .from('avatars')
        .getPublicUrl(storagePath);

    // 3. Update profiles table
    await _supabase
        .from('profiles')
        .update({'avatar_url': publicUrl})
        .eq('id', uid);

    // 4. Update local AppProvider (for header avatar)
    app.updateProfileImagePath(image.path);

    // 5. Reload profile to reflect change
    await _loadProfile();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile photo updated!')),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
    }
  }
}
```

**Supabase Storage setup (do once in Supabase dashboard):**
1. Go to **Storage → New Bucket**
2. Name: `avatars`
3. Public: ✅ Yes (so URLs are accessible without auth)
4. Add policy: `Allow authenticated users to upload` — `INSERT` where `auth.uid()::text = (storage.foldername(name))[1]`

---

## 📁 Files to Touch

| File | Change |
|---|---|
| `lib/main.dart` | Replace `ChangeNotifierProvider` with `ChangeNotifierProxyProvider` for StepTrackerProvider |
| `lib/providers/step_tracker_provider.dart` | Add `setAppProvider()`, `_streakRecordedToday`, threshold check in `onStepCount()` |
| `lib/widgets/dashboard_fun_widgets.dart` | Add `_QuoteData`, `_dailyQuotes`, `_getTodaysQuote()`, replace hardcoded text |
| `lib/screens/running_screen.dart` | Add `share_plus` share button after run completes |
| `lib/screens/challenge_screen.dart` | Wire `_LeaderboardSheet` to Supabase query |
| `lib/screens/profile_screen.dart` | Upload avatar to Supabase Storage, update `avatar_url` in profiles |
| Supabase SQL Editor | Run the 3 profile trigger scripts |
| Supabase Dashboard → Storage | Create `avatars` bucket with public policy |
| `pubspec.yaml` | Add `share_plus` if not present |

---

## ✅ Verification Checklist

**Streak fix:**
- [ ] Walk 1,000+ steps → streak badge updates from pending to active
- [ ] Next day opening → streak increments (e.g. 1 → 2)

**People suggestions:**
- [ ] Go to Supabase → Table Editor → `profiles` → rows exist for both users
- [ ] Dashboard shows friend in "People You May Know"
- [ ] Tap Follow → friend sees request in Notifications

**Daily quote:**
- [ ] Tap ⚡ → quote shows with author name
- [ ] Change phone date +1 day → different quote appears
- [ ] Change date back → original quote returns

**Run share:**
- [ ] Complete a run → share button opens native share sheet with run summary text

**Leaderboard:**
- [ ] Join a challenge → appear in leaderboard
- [ ] Leaderboard sorts by progress descending

**Avatar upload:**
- [ ] Pick avatar → it uploads to Supabase Storage
- [ ] View own profile on a second device/account → avatar visible
- [ ] Reinstall app → avatar still shows (from Supabase URL, not local path)
