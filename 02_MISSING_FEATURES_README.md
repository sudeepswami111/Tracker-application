# 🟡 Missing Features & Empty Screens

These features were planned (or mock data was removed) but the real implementation was never added. The screen exists but shows nothing, or the button exists but the sheet/logic behind it was never built.

---

## 1. Community Screen — Posts Feed (Empty)

**File:** `lib/screens/community_screen.dart:244`

**Problem:** `childCount: 0` — dummy posts removed, no Supabase query added. The feed is visually present but completely empty.

### What to build

**Supabase table required:** `community_posts`
```sql
CREATE TABLE public.community_posts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  image_url TEXT,
  activity_type TEXT,
  likes_count INT DEFAULT 0,
  comments_count INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS
ALTER TABLE public.community_posts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can read posts" ON public.community_posts FOR SELECT TO authenticated USING (true);
CREATE POLICY "Users can insert own posts" ON public.community_posts FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can delete own posts" ON public.community_posts FOR DELETE TO authenticated USING (auth.uid() = user_id);
```

**Flutter — Add a `CommunityService`** in `lib/services/community_service.dart`:
```dart
class CommunityService {
  final _client = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getPosts({String? filter}) async {
    var query = _client
        .from('community_posts')
        .select('*, author:profiles!community_posts_user_id_fkey(id, full_name, avatar_url)')
        .order('created_at', ascending: false)
        .limit(30);

    if (filter != null && filter != 'All') {
      query = query.eq('activity_type', filter);
    }

    return (await query) as List<Map<String, dynamic>>;
  }

  Future<void> likePost(String postId) async {
    await _client.rpc('increment_likes', params: {'post_id': postId});
  }
}
```

**Flutter — Update `CommunityScreen`** to use a `FutureBuilder` or `StreamBuilder`:
```dart
// Replace childCount: 0 with:
FutureBuilder<List<Map<String, dynamic>>>(
  future: _communityService.getPosts(filter: _activeFilter == 'All' ? null : _activeFilter),
  builder: (context, snap) {
    if (snap.connectionState == ConnectionState.waiting) {
      return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
    }
    final posts = snap.data ?? [];
    if (posts.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(child: Text('No posts yet. Be the first!',
            style: TextStyle(color: AppColors.textSecondary))),
      );
    }
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => _PostCard(post: posts[index]),
        childCount: posts.length,
      ),
    );
  },
),
```

> Also build `_PostCard` widget showing: avatar, name, content, activity type tag, like count, like button, timestamp.

---

## 2. Community Screen — Challenges Strip (Empty)

**File:** `lib/screens/community_screen.dart:225`

**Problem:** `children: []` — challenges removed, no live data.

### What to build

**Supabase table required:** `challenges`
```sql
CREATE TABLE public.challenges (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  description TEXT,
  activity_type TEXT,
  target_value INT,
  target_unit TEXT,
  start_date DATE,
  end_date DATE,
  participants_count INT DEFAULT 0,
  created_by UUID REFERENCES public.profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

**Flutter:** Fetch and render as horizontal scroll cards:
```dart
// Replace children: [] with a FutureBuilder fetching active challenges
FutureBuilder<List>(
  future: Supabase.instance.client
      .from('challenges')
      .select()
      .gte('end_date', DateTime.now().toIso8601String())
      .limit(10),
  builder: (context, snap) {
    final challenges = (snap.data as List?) ?? [];
    if (challenges.isEmpty) return const SizedBox.shrink();
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: challenges.length,
      itemBuilder: (_, i) => _ChallengeChip(challenge: challenges[i]),
    );
  },
),
```

---

## 3. History Screen — Activity List (Empty)

**File:** `lib/screens/history_screen.dart:20`

**Problem:** `_activities = []` — mock removed, no real data source wired.

### What to build

History should pull from **3 Supabase tables** and merge them:

| Source | Table | Key fields |
|---|---|---|
| Runs | `running_activities` | `user_id`, `distance_km`, `duration_seconds`, `activity_type`, `created_at` |
| Study sessions | `study_sessions` (if exists) | `user_id`, `duration_minutes`, `created_at` |
| Manual plans | `daily_plans` (if stored in Supabase) | `user_id`, `title`, `type`, `kcal`, `created_at` |

**Flutter — Add `HistoryService`** in `lib/services/history_service.dart`:
```dart
class HistoryService {
  final _client = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getHistory() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return [];

    final runs = await _client
        .from('running_activities')
        .select()
        .eq('user_id', uid)
        .order('created_at', ascending: false)
        .limit(50);

    return (runs as List).map((r) => {
      ...r as Map<String, dynamic>,
      '_source': 'run',
    }).toList();
    // TODO: merge study_sessions and daily_plans similarly
  }
}
```

**Flutter — Wire into `HistoryScreen`:**
```dart
@override
void initState() {
  super.initState();
  _loadHistory();
}

Future<void> _loadHistory() async {
  final data = await HistoryService().getHistory();
  if (mounted) setState(() => _activities = data);
}
```

---

## 4. History Screen — Export / Share / Filter Buttons

**File:** `lib/screens/history_screen.dart:129, 178, 323`

**Problem:** Three `onPressed: () {}` buttons — export button, share button, filter/sort button are all dead.

### What to build

**Export button (line 129):**
```dart
onPressed: () async {
  final csv = _activities.map((a) =>
    '${a['created_at']},${a['_source']},${a['distance_km'] ?? ''},${a['duration_seconds'] ?? ''}'
  ).join('\n');
  final header = 'date,type,distance_km,duration_seconds\n';
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/history_export.csv');
  await file.writeAsString(header + csv);
  await Share.shareXFiles([XFile(file.path)], text: 'My Activity History');
},
```

**Filter/Sort button (line 323):** Open a `showModalBottomSheet` with sort options (by date, by type, by distance).

---

## 5. Study Screen — Task Persistence (Lost on Restart)

**File:** `lib/screens/study_screen.dart:26`

**Problem:** `_tasks = []` — mock removed. Tasks added during a session vanish when the app restarts. No persistence layer.

### Option A — Hive (local, fast, no backend needed)

```dart
// In initState:
final box = await Hive.openBox('study_tasks');
setState(() => _tasks = box.values.cast<Map>().toList());

// On add task:
box.add(newTask);

// On delete task:
box.deleteAt(index);
```

Add to `pubspec.yaml` if not present: `hive_flutter: ^1.1.0`

### Option B — Supabase (syncs across devices)

```sql
CREATE TABLE public.study_tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  is_completed BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

```dart
// Load on initState:
final tasks = await Supabase.instance.client
    .from('study_tasks')
    .select()
    .eq('user_id', uid)
    .order('created_at');
setState(() => _tasks = tasks as List<Map<String, dynamic>>);
```

> **Recommendation:** Use Hive for fast offline-first experience. Supabase sync can be added later.

---

## 6. Study Screen — Session History / Stats Chart (Empty)

**File:** `lib/screens/study_screen.dart:701`

**Problem:** `avgHeight = 0.0` — chart renders but all bars are zero height because no real session data is being passed in.

### What to build

Store completed study sessions and pass them to the chart:
```dart
// When a Pomodoro completes, record it:
final session = {
  'duration_minutes': _pomodoroMinutes,
  'date': DateTime.now().toIso8601String(),
  'completed_at': DateTime.now().millisecondsSinceEpoch,
};
// Save to Hive or Supabase study_sessions table
// Then recalculate avgHeight from last 7 days of sessions
```

---

## 7. Profile Screen — Share Profile Button

**File:** `lib/screens/profile_screen.dart:836`

**Problem:** `onLongPress` comment says "Trigger share intent logic here" — not implemented.

### What to build

```dart
onLongPress: () async {
  HapticFeedback.mediumImpact();
  final profileUrl = 'https://yourapp.com/profile/$_userId';
  await Share.share(
    'Check out my LifePulse profile! $profileUrl',
    subject: 'My LifePulse Profile',
  );
},
```

Add `share_plus` to `pubspec.yaml` if not present.

---

## 8. Profile Screen — Social Pills (Strava, Instagram, Share Profile)

**File:** `lib/screens/profile_screen.dart:~780`

**Problem:** `_socialPill` widgets render but are not wrapped in `GestureDetector`. Tapping them does nothing.

### What to build

Replace `_socialPill()` with a tappable version:
```dart
Widget _socialPill(String label, Color color, {String? url, VoidCallback? onCustomTap}) {
  return Expanded(
    child: GestureDetector(
      onTap: () async {
        if (onCustomTap != null) {
          onCustomTap();
        } else if (url != null && await canLaunchUrl(Uri.parse(url))) {
          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Center(
          child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
        ),
      ),
    ),
  );
}

// Usage (replace current _socialPill calls):
_socialPill('Strava', AppColors.solarAmber, url: 'https://www.strava.com'),
const SizedBox(width: 8),
_socialPill('Instagram', AppColors.pulseRed, url: 'https://www.instagram.com'),
const SizedBox(width: 8),
_socialPill(
  'Share Profile',
  AppColors.voltCyan,
  onCustomTap: () async {
    await Share.share('https://yourapp.com/profile/$_userId');
  },
),
```

---

## 📁 Files to Touch / Create

| File | Change |
|---|---|
| `lib/services/community_service.dart` | **NEW FILE** — getPosts(), likePost() |
| `lib/services/history_service.dart` | **NEW FILE** — getHistory() merging Supabase tables |
| `lib/widgets/create_post_sheet.dart` | **NEW FILE** — post creation bottom sheet |
| `lib/screens/community_screen.dart` | Wire FutureBuilder for posts and challenges |
| `lib/screens/history_screen.dart` | Load from HistoryService, wire export/share/filter |
| `lib/screens/study_screen.dart` | Add Hive task persistence + session recording |
| `lib/screens/profile_screen.dart` | Add share long-press, wire social pills |
| Supabase SQL Editor | Create `community_posts`, `challenges` tables + RLS |

---

## ✅ Verification Checklist

- [ ] Community feed shows real posts from Supabase after a post is created
- [ ] Challenges strip shows active challenges from Supabase
- [ ] History screen shows past runs after at least one run is completed
- [ ] Adding a study task → closing and reopening app → task still there
- [ ] Study chart bars show non-zero heights after completing a session
- [ ] Share Profile button opens the native share sheet
- [ ] Strava pill opens Strava in browser
- [ ] Instagram pill opens Instagram in browser
