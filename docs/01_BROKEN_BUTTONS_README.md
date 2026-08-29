# 🔴 Broken Buttons & Dead Taps

All buttons/taps below render correctly in the UI but have **empty handlers** (`onTap: () {}` or `onPressed: () {}`). Nothing happens when the user taps them.

---

## 1. Settings Screen — Sign Out Button

**File:** `lib/screens/settings_screen.dart` — bottom of `build()`

**Problem:** Only fires `HapticFeedback.heavyImpact()`. Never calls `signOut()`.

**Fix:**
```dart
// Replace:
onPressed: () {
  HapticFeedback.heavyImpact();
},

// With:
onPressed: () {
  HapticFeedback.heavyImpact();
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Sign Out'),
      content: const Text('Are you sure you want to sign out?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(ctx);
            await context.read<AuthProvider>().signOut();
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.pulseRed),
          child: const Text('Sign Out', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
},
```

Add import if missing: `import '../providers/auth_provider.dart';`

---

## 2. Settings Screen — Account Row Tap (Edit Profile)

**File:** `lib/screens/settings_screen.dart:50`

**Problem:** `onTap` wraps the account card but comment says `// Edit profile sheet` — no actual action.

**Fix:** The `ProfileScreen` already has a working `_showEditProfile()` sheet. Reuse it or open `ProfileScreen` directly:
```dart
onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const ProfileScreen()),
  );
},
```

Add import: `import '../screens/profile_screen.dart';`

---

## 3. Settings Screen — Bluetooth Devices Row

**File:** `lib/screens/settings_screen.dart:247`

**Problem:** Chevron row is not tappable. `DeviceScannerSheet` already exists but is never called here.

**Fix:**
```dart
_settingsRow(
  LucideIcons.bluetooth,
  'Bluetooth Devices',
  GestureDetector(
    onTap: () {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const DeviceScannerSheet(),
      );
    },
    child: _chevronRow('1 connected'),
  ),
),
```

Add import: `import '../widgets/device_scanner_sheet.dart';`

---

## 4. Settings Screen — Data Permissions Row

**File:** `lib/screens/settings_screen.dart:253`

**Problem:** `onTap: () {}` — empty.

**Fix:** Open `PermissionRequestSheet` (already exists):
```dart
_settingsRow(
  LucideIcons.shieldCheck,
  'Data Permissions',
  GestureDetector(
    onTap: () {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const PermissionRequestSheet(),
      );
    },
    child: _chevronRow(''),
  ),
),
```

Add import: `import '../widgets/permission_request_sheet.dart';`

---

## 5. Settings Screen — Export My Data

**File:** `lib/screens/settings_screen.dart:260`

**Problem:** `onTap: () {}` — does nothing.

**Fix:** Build a simple JSON export from AppProvider data and share it using `share_plus`. Add `share_plus` to `pubspec.yaml` if not present:

```yaml
share_plus: ^10.0.0
```

```dart
onTap: () async {
  final app = context.read<AppProvider>();
  final data = {
    'exported_at': DateTime.now().toIso8601String(),
    'steps_today': context.read<StepTrackerProvider>().steps,
    'current_streak': app.currentStreak,
    'distance_km': app.distance,
    'study_minutes': app.totalStudyMinutes,
    'daily_plans': app.dailyPlans.map((p) => p.toJson()).toList(),
  };
  final jsonStr = const JsonEncoder.withIndent('  ').convert(data);
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/lifepulse_export.json');
  await file.writeAsString(jsonStr);
  await Share.shareXFiles([XFile(file.path)], text: 'My LifePulse Data Export');
},
```

Add imports:
```dart
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
```

---

## 6. Settings Screen — Delete Account

**File:** `lib/screens/settings_screen.dart:265`

**Problem:** `onTap: () {}` — does nothing.

**Fix:** Show a strong confirmation dialog, then delete from Supabase:
```dart
onTap: () {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Delete Account'),
      content: const Text(
        'This will permanently delete your account and all your data. This cannot be undone.',
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(ctx);
            try {
              final supabase = Supabase.instance.client;
              final uid = supabase.auth.currentUser?.id;
              if (uid != null) {
                await supabase.from('profiles').delete().eq('id', uid);
                // Note: full auth user deletion requires a Supabase Edge Function
                // For now, sign out and let the user know
              }
              await context.read<AuthProvider>().signOut();
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error deleting account: $e')),
              );
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.pulseRed),
          child: const Text('Delete', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
},
```

> ⚠️ **Note for Antigravity:** Full auth user deletion (`auth.users` row) requires a Supabase Edge Function with service-role key. Create a `delete-user` Edge Function and call it here. The client-side SDK cannot delete the auth user itself.

---

## 7. Settings Screen — Privacy Policy Row

**File:** `lib/screens/settings_screen.dart:283`

**Problem:** `onTap: () {}` — empty. `url_launcher` is already in `pubspec.yaml`.

**Fix:**
```dart
onTap: () async {
  const url = 'https://yourapp.com/privacy'; // ← Replace with real URL
  if (await canLaunchUrl(Uri.parse(url))) {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }
},
```

Add import: `import 'package:url_launcher/url_launcher.dart';`

---

## 8. Settings Screen — Rate App Row

**File:** `lib/screens/settings_screen.dart:281`

**Problem:** `onTap: () {}` — empty.

**Fix:**
```dart
onTap: () async {
  // Android Play Store
  const url = 'https://play.google.com/store/apps/details?id=com.yourapp.lifepulse';
  // iOS App Store: 'https://apps.apple.com/app/idXXXXXXXXX'
  if (await canLaunchUrl(Uri.parse(url))) {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }
},
```

---

## 9. Settings Screen — Accent Override Swatches

**File:** `lib/screens/settings_screen.dart` — `_accentSwatch()` helper

**Problem:** Swatches render but tap does nothing — not wired to `ThemeProvider`.

**Fix:** `ThemeProvider` needs an `accentColor` field. Add it, then wire the swatches:
```dart
// In ThemeProvider:
Color _accentColor = AppColors.voltCyan;
Color get accentColor => _accentColor;
void setAccentColor(Color color) {
  _accentColor = color;
  notifyListeners();
  // Persist to SharedPreferences
}

// In _accentSwatch() — replace Container with GestureDetector:
Widget _accentSwatch(Color color, bool isSelected) {
  return GestureDetector(
    onTap: () => context.read<ThemeProvider>().setAccentColor(color),
    child: Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: context.watch<ThemeProvider>().accentColor == color
            ? Border.all(color: Colors.white, width: 2)
            : null,
      ),
      child: context.watch<ThemeProvider>().accentColor == color
          ? const Icon(Icons.check, color: Colors.black, size: 14)
          : null,
    ),
  );
}
```

---

## 10. Community Screen — FAB (Create Post) + Search Button

**File:** `lib/screens/community_screen.dart:65, 114`

**Problem:** FAB `onPressed: () {}` and search icon `onTap: () {}`.

**Fix (FAB):** Create a `CreatePostSheet` widget or inline bottom sheet:
```dart
onPressed: () {
  HapticFeedback.mediumImpact();
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const CreatePostSheet(),
  );
},
```

**Fix (Search):**
```dart
onTap: () {
  showSearch(context: context, delegate: CommunitySearchDelegate());
},
```

> Antigravity: create `lib/widgets/create_post_sheet.dart` and `lib/widgets/community_search_delegate.dart` as new files.

---

## 11. Challenge Screen — FAB (Create Challenge)

**File:** `lib/screens/challenge_screen.dart:52`

**Problem:** `onPressed: () {}` — does nothing.

**Fix:**
```dart
onPressed: () {
  HapticFeedback.mediumImpact();
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const CreateChallengeSheet(),
  );
},
```

> Antigravity: create `lib/widgets/create_challenge_sheet.dart`.

---

## 12. Notifications Screen — Notification Item Tap

**File:** `lib/screens/notifications_screen.dart:202`

**Problem:** `onTap: () {}` on individual notification cards — nothing happens.

**Fix:** Navigate based on notification type:
```dart
onTap: () async {
  final type = notification['type'] as String? ?? '';
  // Mark as read
  await _supabase
      .from('notifications')
      .update({'read': true})
      .eq('id', notification['id']);
  setState(() => notification['read'] = true);

  // Navigate based on type
  if (!mounted) return;
  if (type == 'follow_request' || type == 'follow_accepted') {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => ProfileScreen(targetUserId: notification['actor_id'] as String?),
    ));
  } else if (type == 'community_post' || type == 'post_like') {
    context.read<AppProvider>().setTabIndex(3); // Community tab
    Navigator.pop(context);
  }
},
```

---

## 📁 Files to Touch

| File | Changes |
|---|---|
| `lib/screens/settings_screen.dart` | Sign out, account tap, bluetooth, permissions, export, delete, privacy, rate, accent swatches |
| `lib/screens/community_screen.dart` | FAB + search |
| `lib/screens/challenge_screen.dart` | FAB |
| `lib/screens/notifications_screen.dart` | Notification tap |
| `lib/widgets/create_post_sheet.dart` | **NEW FILE** |
| `lib/widgets/create_challenge_sheet.dart` | **NEW FILE** |
| `pubspec.yaml` | Add `share_plus` if not present |

---

## ✅ Verification Checklist

- [ ] Sign Out button → shows confirmation dialog → signs out and navigates to LoginScreen
- [ ] Account row tap → opens edit profile sheet
- [ ] Bluetooth Devices → opens DeviceScannerSheet
- [ ] Data Permissions → opens PermissionRequestSheet
- [ ] Export My Data → opens share sheet with JSON file
- [ ] Delete Account → shows warning dialog → deletes profile row → signs out
- [ ] Privacy Policy → opens URL in browser
- [ ] Rate App → opens app store page
- [ ] Accent swatches → tapping a swatch changes the selected indicator
- [ ] Community FAB → opens create post sheet
- [ ] Challenge FAB → opens create challenge sheet
- [ ] Notification tap → navigates to correct screen + marks as read
