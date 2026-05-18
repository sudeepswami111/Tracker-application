# 📋 Add New Plan Sheet — Feature Upgrade

## Overview of Changes

Four improvements to `lib/widgets/add_plan_sheet.dart`:

1. **Activity Type chips** — sync with all sports/activities from the map/running screen
2. **Numeric-only keyboard** for Duration and Kcal fields
3. **Multiple sample images per activity** — auto-swap preview when activity type is selected
4. **Custom image from gallery** — user can pick their own photo via image_picker

---

## 🔁 Change 1 — Sync Activity Types with Map Section

### Context for Antigravity
The current `add_plan_sheet.dart` has only 4 hardcoded chips: `Run`, `Yoga`, `Gym`, `Swim`.
The running/map screen (`running_screen.dart`) has its own `_selectedRunType` list with activities like `Outdoor Run`, `Trail Run`, `Cycling` — and **Sudeep has recently added more activity types to the map screen that are not yet reflected here**.

### What to do
1. Open `running_screen.dart` → find the full list of activity type chips (the `_typeChip(...)` calls or equivalent).
2. Copy **every activity type** from that list into a shared constant so both screens use the same source of truth.
3. Create a new file: `lib/constants/activity_types.dart`

```dart
// lib/constants/activity_types.dart

import 'package:flutter/material.dart';

class ActivityType {
  final String label;
  final IconData icon;
  const ActivityType({required this.label, required this.icon});
}

// ── MASTER LIST — keep this in sync with running_screen.dart ──────────────
// Antigravity: copy ALL activity types from running_screen.dart here.
// If running_screen uses string labels with icons, mirror them exactly.
const List<ActivityType> kActivityTypes = [
  ActivityType(label: 'Outdoor Run',   icon: Icons.directions_run),
  ActivityType(label: 'Trail Run',     icon: Icons.park),
  ActivityType(label: 'Cycling',       icon: Icons.directions_bike),
  // ← ADD ALL NEWLY ADDED MAP ACTIVITIES HERE — check running_screen.dart
];
```

4. In `add_plan_sheet.dart`, replace the hardcoded 4-chip row with a `Wrap` that renders all `kActivityTypes`:

```dart
// Replace the hardcoded Row of chips with:
Wrap(
  spacing: 8,
  runSpacing: 8,
  children: kActivityTypes.map((activity) {
    final isSelected = _selectedActivity == activity.label;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedActivity = activity.label;
        _selectedImage = _sampleImagesFor(activity.label).first;
        _isCustomImage = false;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.voltCyan : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.voltCyan : AppColors.borderSubtle,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(activity.icon, size: 16,
                color: isSelected ? Colors.black : AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(activity.label,
                style: TextStyle(
                  color: isSelected ? Colors.black : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                )),
          ],
        ),
      ),
    );
  }).toList(),
),
```

5. In `running_screen.dart`, also import `kActivityTypes` and replace the hardcoded `_typeChip` calls so both screens share the same list going forward.

---

## 🔢 Change 2 — Numeric-Only Keyboard for Duration & Kcal

### What to do
Add `keyboardType` and `inputFormatters` to both fields:

```dart
// Duration field
TextField(
  controller: _durationController,
  keyboardType: TextInputType.number,           // ← opens number keyboard
  inputFormatters: [FilteringTextInputFormatter.digitsOnly], // ← blocks letters
  decoration: InputDecoration(
    labelText: 'Duration (mins)',
    hintText: '30',
    suffixText: 'min',
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
  ),
),

// Kcal field
TextField(
  controller: _kcalController,
  keyboardType: TextInputType.number,
  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
  decoration: InputDecoration(
    labelText: 'Calories',
    hintText: '320',
    suffixText: 'kcal',
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
  ),
),
```

Add the import at the top of `add_plan_sheet.dart`:
```dart
import 'package:flutter/services.dart';
```

> **Note:** `suffixText` is optional but good UX — shows the unit inside the field so the user knows they're entering minutes/kcal without a label.

---

## 🖼️ Change 3 — Multiple Sample Images Per Activity

### What to do
Replace the single `_galleryImages` list with a **map keyed by activity type**:

```dart
// In _AddPlanSheetState — replace _galleryImages with:

static const Map<String, List<String>> _activitySampleImages = {
  'Outdoor Run': [
    'https://images.unsplash.com/photo-1552674605-db6ffd4facb5?auto=format&fit=crop&w=300&q=80',
    'https://images.unsplash.com/photo-1571008887538-b36bb32f4571?auto=format&fit=crop&w=300&q=80',
    'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?auto=format&fit=crop&w=300&q=80',
  ],
  'Trail Run': [
    'https://images.unsplash.com/photo-1501555088652-021faa106b9b?auto=format&fit=crop&w=300&q=80',
    'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?auto=format&fit=crop&w=300&q=80',
    'https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05?auto=format&fit=crop&w=300&q=80',
  ],
  'Cycling': [
    'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?auto=format&fit=crop&w=300&q=80',
    'https://images.unsplash.com/photo-1534787238916-9ba6764efd4f?auto=format&fit=crop&w=300&q=80',
    'https://images.unsplash.com/photo-1502744688674-c619d1586c9e?auto=format&fit=crop&w=300&q=80',
  ],
  'Yoga': [
    'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?auto=format&fit=crop&w=300&q=80',
    'https://images.unsplash.com/photo-1506126613408-eca07ce68773?auto=format&fit=crop&w=300&q=80',
    'https://images.unsplash.com/photo-1599901860904-17e6ed7083a0?auto=format&fit=crop&w=300&q=80',
  ],
  'Gym': [
    'https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?auto=format&fit=crop&w=300&q=80',
    'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?auto=format&fit=crop&w=300&q=80',
    'https://images.unsplash.com/photo-1526506118085-60ce8714f8c5?auto=format&fit=crop&w=300&q=80',
  ],
  'Swim': [
    'https://images.unsplash.com/photo-1519315901367-f34f9273400a?auto=format&fit=crop&w=300&q=80',
    'https://images.unsplash.com/photo-1530549387789-4c1017266635?auto=format&fit=crop&w=300&q=80',
    'https://images.unsplash.com/photo-1560090995-01632a28895b?auto=format&fit=crop&w=300&q=80',
  ],
  // ← ADD 3 UNSPLASH URLS FOR EVERY OTHER ACTIVITY TYPE IN kActivityTypes
  // Pattern: search unsplash.com/s/photos/<activity-name> and pick 3 good ones
};

// Helper — fallback to first generic image if activity not in map yet
List<String> _sampleImagesFor(String activityLabel) {
  return _activitySampleImages[activityLabel] ??
      _activitySampleImages['Outdoor Run']!;
}
```

Add state fields:
```dart
String _selectedActivity = kActivityTypes.first.label;
bool _isCustomImage = false;
```

Update `initState()`:
```dart
@override
void initState() {
  super.initState();
  _selectedImage = _sampleImagesFor(kActivityTypes.first.label).first;
}
```

The image preview row below now shows the **3 sample images for the selected activity**:
```dart
SizedBox(
  height: 80,
  child: ListView(
    scrollDirection: Axis.horizontal,
    children: [
      // Sample images for selected activity
      ..._sampleImagesFor(_selectedActivity).map((imgUrl) {
        final isSelected = !_isCustomImage && _selectedImage == imgUrl;
        return GestureDetector(
          onTap: () => setState(() {
            _selectedImage = imgUrl;
            _isCustomImage = false;
          }),
          child: Container(
            width: 80,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? AppColors.voltCyan : Colors.transparent,
                width: 3,
              ),
              image: DecorationImage(
                image: NetworkImage(imgUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),
        );
      }),

      // Custom image picker tile — see Change 4 below
      _buildCustomImageTile(),
    ],
  ),
),
```

---

## 📷 Change 4 — Custom Image from Gallery

### What to do

Add a `+ Custom` tile at the end of the image row that opens the image picker:

```dart
Widget _buildCustomImageTile() {
  return GestureDetector(
    onTap: _pickCustomImage,
    child: Container(
      width: 80,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _isCustomImage ? AppColors.voltCyan : AppColors.borderSubtle,
          width: _isCustomImage ? 3 : 1,
        ),
        color: AppColors.surfaceCard,
        image: _isCustomImage && _customImagePath != null
            ? DecorationImage(
                image: FileImage(File(_customImagePath!)),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: _isCustomImage && _customImagePath != null
          ? null  // show the image, no icon overlay needed
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.imagePlus, color: AppColors.textSecondary, size: 22),
                const SizedBox(height: 4),
                Text('Custom', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
              ],
            ),
    ),
  );
}

String? _customImagePath;

Future<void> _pickCustomImage() async {
  final picker = ImagePicker();
  final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
  if (picked != null) {
    setState(() {
      _customImagePath = picked.path;
      _selectedImage = picked.path;  // will be a local path, not a URL
      _isCustomImage = true;
    });
  }
}
```

Add these imports to `add_plan_sheet.dart`:
```dart
import 'dart:io';
import 'package:image_picker/image_picker.dart';
```

> `image_picker` is **already in `pubspec.yaml`** — no new package needed.

### Update `_savePlan()` to handle local paths
The `DailyPlan.imageUrl` field currently stores a URL string. When `_isCustomImage` is true, it stores a local file path instead. The `DailyPlanTile` widget needs to handle both:

```dart
// In daily_plan_tile.dart — when rendering the image:
Widget _buildImage(String imageUrl) {
  if (imageUrl.startsWith('http')) {
    return Image.network(imageUrl, fit: BoxFit.cover);
  } else {
    return Image.file(File(imageUrl), fit: BoxFit.cover);
  }
}
```

---

## 📁 Files to Touch

| File | Change |
|---|---|
| `lib/constants/activity_types.dart` | **NEW FILE** — master list of all activity types with icons |
| `lib/widgets/add_plan_sheet.dart` | Activity chips from constant, numeric keyboards, sample image map, custom picker tile |
| `lib/screens/running_screen.dart` | Import and use `kActivityTypes` instead of hardcoded `_typeChip` calls |
| `lib/widgets/daily_plan_tile.dart` | Handle both `http://` URLs and local file paths for image rendering |

---

## ✅ Verification Checklist

- [ ] All activity types from map/running screen appear as chips in Add Plan
- [ ] Adding a new activity type to `kActivityTypes` automatically appears in both Add Plan and the running screen
- [ ] Tapping Duration → number keyboard opens, no alphabet input possible
- [ ] Tapping Kcal → same
- [ ] Switching activity type chip → preview images update to that activity's 3 samples
- [ ] Tapping `+ Custom` → gallery opens → selected photo appears in preview with cyan border
- [ ] Custom image plan saves and shows correctly in Today's Plan tile
- [ ] Network images still load correctly for sample images

---

## ⚠️ Notes for Antigravity

1. **Activity list sync is the most important part.** The `kActivityTypes` constant in `activity_types.dart` should be the **single source of truth** — both `add_plan_sheet.dart` and `running_screen.dart` must import from it. Never maintain two separate lists.

2. **For every activity type you add to `kActivityTypes`**, also add 3 Unsplash image URLs to `_activitySampleImages` in `add_plan_sheet.dart`. Use this URL pattern: `https://images.unsplash.com/photo-<ID>?auto=format&fit=crop&w=300&q=80`

3. **Local image paths are not persistent across reinstalls.** This is acceptable for now — it's the standard behaviour of `image_picker` on Android/iOS. A future improvement would be to copy the file to the app's documents directory.
