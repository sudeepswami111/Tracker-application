# 🟣 Hardcoded Values & Static Data

All items below are static strings, numbers, or mock data baked directly into the code. They look real in the UI but never change — not tied to the actual logged-in user, live sensor data, or Supabase.

---

## 1. Settings Screen — Email Shows "alex@example.com"

**File:** `lib/screens/settings_screen.dart:78`

**Problem:** Hardcoded placeholder email. Every user on every device sees "alex@example.com".

```dart
// Current (WRONG):
Text('alex@example.com', ...)

// Fix — read from Supabase auth:
Text(
  Supabase.instance.client.auth.currentUser?.email ?? 'No email',
  style: theme.textTheme.bodySmall?.copyWith(
    color: theme.colorScheme.onSurfaceVariant,
  ),
),
```

No new imports needed — `supabase_flutter` is already imported in `settings_screen.dart`.

---

## 2. Settings Screen — HealthKit, Steps Goal, Calorie Budget, Pomodoro Not Persisted

**File:** `lib/screens/settings_screen.dart:19` — `// Mock State` comment

**Problem:** These 4 values are local `_SettingsScreenState` variables. They reset to defaults every time the app restarts. The user's customizations are never saved.

```dart
// Current (WRONG — local state only):
bool _healthKitConnected = true;
bool _masterNotifications = true;
bool _workoutReminders = true;
bool _studyReminders = false;
double _dailyStepsGoal = 10000;
int _pomodoroDuration = 25;
```

**Fix:** Move these to `AppProvider` (already uses SharedPreferences) and add persistence:

```dart
// In AppProvider — add these fields + prefs keys:
bool healthConnectEnabled = true;
bool masterNotifications = true;
bool workoutReminders = true;
bool studyReminders = false;
double dailyStepsGoal = 10000;
int pomodoroDuration = 25;

// In _loadData():
healthConnectEnabled = prefs.getBool('healthConnectEnabled') ?? true;
masterNotifications  = prefs.getBool('masterNotifications') ?? true;
workoutReminders     = prefs.getBool('workoutReminders') ?? true;
studyReminders       = prefs.getBool('studyReminders') ?? false;
dailyStepsGoal       = prefs.getDouble('dailyStepsGoal') ?? 10000;
pomodoroDuration     = prefs.getInt('pomodoroDuration') ?? 25;

// In _saveData():
prefs.setBool('healthConnectEnabled', healthConnectEnabled);
prefs.setBool('masterNotifications',  masterNotifications);
prefs.setBool('workoutReminders',     workoutReminders);
prefs.setBool('studyReminders',       studyReminders);
prefs.setDouble('dailyStepsGoal',     dailyStepsGoal);
prefs.setInt('pomodoroDuration',      pomodoroDuration);

// Add setters:
void setDailyStepsGoal(double v) { dailyStepsGoal = v; _saveData(); notifyListeners(); }
void setPomodoroMin(int v) { pomodoroDuration = v; _saveData(); notifyListeners(); }
void toggleWorkoutReminders(bool v) { workoutReminders = v; _saveData(); notifyListeners(); }
// etc.
```

In `settings_screen.dart`, replace local `setState` calls with `context.read<AppProvider>().setXxx()`:
```dart
// Example for steps slider:
Slider.adaptive(
  value: app.dailyStepsGoal,
  onChanged: (v) => context.read<AppProvider>().setDailyStepsGoal(v),
  ...
),
```

---

## 3. Profile Screen — Fitness Streak Best Hardcoded to 42

**File:** `lib/screens/profile_screen.dart:625`

**Problem:** `_streakBadgeCard('Fitness', app.longestStreak, 42, ...)` — the second argument (`best`) is hardcoded `42`.

**Problem root cause:** `longestStreak` in `AppProvider` is declared as `final int longestStreak = 0;` — it never gets updated.

**Fix — Part A:** Make `longestStreak` mutable and update it whenever `currentStreak` exceeds it:

```dart
// In AppProvider — change:
final int longestStreak = 0;
// To:
int longestStreak = 0;

// In updateStreak() — after incrementing currentStreak:
if (currentStreak > longestStreak) {
  longestStreak = currentStreak;
  prefs.setInt('longestStreak', longestStreak);
}

// In _loadData():
longestStreak = prefs.getInt('longestStreak') ?? 0;
```

**Fix — Part B:** Remove the hardcoded 42:
```dart
// Replace:
_streakBadgeCard('Fitness', app.longestStreak, 42, AppColors.pulseRed, isDark),

// With:
_streakBadgeCard('Fitness', app.currentStreak, app.longestStreak, AppColors.pulseRed, isDark),
```

---

## 4. Profile Screen — Nutrition Streak "7 / 14 days" Hardcoded

**File:** `lib/screens/profile_screen.dart:641`

**Problem:** `_streakBadgeCard('Nutrition', 7, 14, AppColors.solarAmber, isDark)` — both numbers are static ints. No nutrition streak logic exists.

**Fix Option A (minimal):** Track a simple "did user log any nutrition today" streak, similar to how fitness streak works. Add `nutritionStreak` and `longestNutritionStreak` to `AppProvider`:

```dart
// In AppProvider:
int nutritionStreak = 0;
int longestNutritionStreak = 0;

void recordNutritionLog() {
  // Call this whenever user logs food/calories
  updateStreak(); // reuse the same gap logic or create separate method
}
```

**Fix Option B (skip for now):** Hide the Nutrition streak card until the feature is built:
```dart
// Replace with a "Coming Soon" card:
_streakBadgeCard('Nutrition', 0, 0, AppColors.solarAmber, isDark),
// OR remove this card entirely from the ListView
```

---

## 5. Profile Screen — "Workouts: 112" and "PR Badges: 4" Hardcoded

**File:** `lib/screens/profile_screen.dart:711`

**Problem:** Fitness accordion shows static string `'112'` for workouts and `'4'` for PR badges.

**Fix:** These should come from Supabase. `_runsCount` is already fetched from `running_activities` — use it:

```dart
// Replace:
'Workouts': '112',
'PR Badges': '4',

// With:
'Workouts': '$_runsCount',
'PR Badges': '–',  // leave as dash until a PR-detection system is built
```

For PR detection: a PR badge is earned when a new run has a better pace/distance than all previous runs. This can be a future feature — for now replace the hardcoded `4` with `–` or `0`.

---

## 6. Profile Screen — Connected Devices "Mi Band 5 / Smart Scale X" Hardcoded

**File:** `lib/screens/profile_screen.dart:750`

**Problem:** `_buildDeviceRow('Mi Band 5', ...)` and `_buildDeviceRow('Smart Scale X', ...)` are static strings. The shown device name, battery, and connected status don't reflect the real paired device.

**Fix:** Read from `WatchMetricsProvider` which has the actual connected device info:

```dart
// In _buildDeviceRow section — replace hardcoded rows with:
Consumer<WatchMetricsProvider>(
  builder: (context, watch, _) {
    if (watch.isConnected) {
      return _buildDeviceRow(
        watch.deviceName.isNotEmpty ? watch.deviceName : 'Smartwatch',
        LucideIcons.watch,
        watch.battery,
        true,
        isDark,
      );
    }
    return _buildDeviceRow(
      'No device paired',
      LucideIcons.watch,
      0,
      false,
      isDark,
    );
  },
),
```

Check `WatchMetricsProvider` for the `deviceName` field — add it if it doesn't exist:
```dart
// In WatchMetricsProvider:
String _deviceName = '';
String get deviceName => _deviceName;
// Set it when a device connects in _handleConnectionChange()
```

Remove the hardcoded `Smart Scale X` row entirely (or keep it as "Scale (coming soon)" with `connected: false`).

---

## 7. Dashboard Screen — Sleep Score Hardcoded to "85"

**File:** `lib/screens/dashboard_screen.dart` — `_buildHealthStats()`

**Problem:** Sleep score is hardcoded to `'85'` even when the watch is connected. `WatchMetricsProvider` already has `sleepHours` data.

**Fix:** Display `sleepHours` from the watch provider instead:
```dart
// Replace:
value: isConnected ? '85' : '---',

// With:
value: isConnected
    ? watchProvider.sleepHours > 0
        ? '${watchProvider.sleepHours.toStringAsFixed(1)}h'
        : '---'
    : '---',
```

> Note: The label should also change from "Sleep Score" to "Sleep" since `sleepHours` is a duration, not a 0–100 score.

---

## 8. Dashboard Screen — Community Teaser Uses Fake Avatar

**File:** `lib/screens/dashboard_screen.dart:417`, `lib/screens/community_screen.dart:407`

**Problem:** `NetworkImage('https://i.pravatar.cc/150?img=33')` — a placeholder avatar service. Not a real user.

**Fix:** The community teaser should show the most recent real post from Supabase. Once `CommunityService` is built (see `02_MISSING_FEATURES_README.md`):

```dart
// Replace the hardcoded teaser container with:
FutureBuilder(
  future: CommunityService().getPosts(),
  builder: (context, snap) {
    final posts = (snap.data as List?) ?? [];
    if (posts.isEmpty) return const SizedBox.shrink();
    final latest = posts.first;
    final authorAvatar = latest['author']?['avatar_url'] as String?;
    final authorName = latest['author']?['full_name'] as String? ?? 'Someone';
    final content = latest['content'] as String? ?? '';
    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundImage: authorAvatar != null ? NetworkImage(authorAvatar) : null,
          child: authorAvatar == null ? Text(authorName[0]) : null,
        ),
        const SizedBox(width: 8),
        Expanded(child: Text('$authorName: $content', maxLines: 1, overflow: TextOverflow.ellipsis)),
      ],
    );
  },
),
```

---

## 9. Running Screen — Package Name "com.example.lifepulse"

**File:** `lib/screens/running_screen.dart:468, 1487`

**Problem:** `userAgentPackageName: 'com.example.lifepulse'` — placeholder bundle ID used for the flutter_map tile server User-Agent header. Some tile servers block or rate-limit requests from `com.example.*` domains.

**Fix:** Replace with your actual Android bundle ID from `android/app/build.gradle`:
```dart
// Replace both occurrences of:
userAgentPackageName: 'com.example.lifepulse',

// With your real bundle ID, e.g.:
userAgentPackageName: 'com.sudeep.lifepulse',
// or whatever your applicationId is in android/app/build.gradle
```

Also update `ios/Runner/Info.plist` `CFBundleIdentifier` to match.

---

## 📁 Files to Touch

| File | Change |
|---|---|
| `lib/screens/settings_screen.dart` | Email from Supabase auth, settings persisted via AppProvider |
| `lib/providers/app_provider.dart` | Add settings fields, longestStreak persistence, nutritionStreak |
| `lib/screens/profile_screen.dart` | Fix longestStreak, remove hardcoded 42/7/14/112/4, wire WatchMetricsProvider for devices |
| `lib/screens/dashboard_screen.dart` | Fix sleep score to use watchProvider.sleepHours |
| `lib/screens/running_screen.dart` | Fix com.example package name (2 places) |
| `lib/providers/watch_metrics_provider.dart` | Add `deviceName` field if missing |

---

## ✅ Verification Checklist

- [ ] Settings screen shows real logged-in email, not "alex@example.com"
- [ ] Changing steps goal and closing + reopening the app → goal is still set
- [ ] Changing pomodoro duration and restarting → duration persists
- [ ] Profile streak "Best" value increases when a new streak record is set
- [ ] Profile Fitness "Workouts" count matches number of runs in Supabase
- [ ] Profile devices section shows the real connected device name (or "No device paired")
- [ ] Dashboard sleep pill shows `sleepHours` from watch when connected
- [ ] Community teaser shows a real post after first post is created
- [ ] Running screen map tiles load without "com.example" in the UA header
