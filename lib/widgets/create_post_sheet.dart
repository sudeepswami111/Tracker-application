import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_colors.dart';
import '../services/community_service.dart';
import '../providers/app_provider.dart';
import '../providers/watch_metrics_provider.dart';
import '../providers/step_tracker_provider.dart';
import 'profile_avatar.dart';

class CreatePostSheet extends StatefulWidget {
  const CreatePostSheet({super.key});

  @override
  State<CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<CreatePostSheet> {
  final _contentCtrl = TextEditingController();
  String _selectedActivity = 'Running';
  bool _isSubmitting = false;
  File? _selectedImage;
  
  // State for stats and mood
  Set<String> _selectedStats = {};
  String? _selectedMood;
  bool _showMoodSelector = false;

  final List<MoodOption> _moodOptions = const [
    MoodOption('🔥', 'Strong'),
    MoodOption('😊', 'Good'),
    MoodOption('😌', 'Calm'),
    MoodOption('😴', 'Tired'),
    MoodOption('💪', 'Motivated'),
  ];

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick photo: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _openStatsSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _StatsStampSelector(
        initiallySelected: _selectedStats,
        onDone: (selected) {
          setState(() {
            _selectedStats = selected;
          });
        },
      ),
    );
  }

  Future<void> _submit() async {
    final text = _contentCtrl.text.trim();
    final hasStats = _selectedStats.isNotEmpty;
    final hasImage = _selectedImage != null;
    if (text.isEmpty && !hasStats && !hasImage) return;

    // Fetch the stats list synchronously before any async gap
    List<StatItem> availableStats = [];
    if (hasStats) {
      availableStats = _getStatsList(context);
    }

    setState(() => _isSubmitting = true);

    String? imageUrl;
    if (_selectedImage != null) {
      try {
        final ext = _selectedImage!.path.split('.').last;
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.$ext';
        
        await Supabase.instance.client.storage.from('community_images').upload(fileName, _selectedImage!);
        imageUrl = Supabase.instance.client.storage.from('community_images').getPublicUrl(fileName);
      } catch (e) {
        debugPrint('Image upload failed: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Image upload failed: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }

    try {
      // Build final post content
      String finalContent = text;
      
      // Build stats string
      if (hasStats) {
        final selectedItems = availableStats.where((item) => _selectedStats.contains(item.key));
        final statsStr = selectedItems.map((item) => '${item.emoji} ${item.formattedValue}').join(' · ');
        if (finalContent.isNotEmpty) {
          finalContent += '\n\n';
        }
        finalContent += '📊 Stats: $statsStr';
      }

      // Build mood string
      if (_selectedMood != null) {
        if (finalContent.isNotEmpty) {
          finalContent += '\n\n';
        }
        finalContent += 'Feeling: $_selectedMood';
      }

      await CommunityService().createPost(finalContent, _selectedActivity, imageUrl: imageUrl);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post shared'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true); // Return true to indicate a refresh is needed
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not post. Try again. ($e)'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    _contentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final appProv = context.watch<AppProvider>();

    final text = _contentCtrl.text.trim();
    final hasStats = _selectedStats.isNotEmpty;
    final hasImage = _selectedImage != null;
    final isEnabled = (text.isNotEmpty || hasStats || hasImage) && !_isSubmitting;

    // Filter list of stat items that are currently selected
    final available = _getStatsList(context);
    final selectedItems = available.where((item) => _selectedStats.contains(item.key)).toList();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceElevated : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12, width: 0.5),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Drag Handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // 2. Header Title Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Create Post',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x, size: 22),
                    onPressed: () => Navigator.pop(context),
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 3. User info row
              Row(
                children: [
                  ProfileAvatar(
                    imageUrl: appProv.avatarUrl,
                    name: appProv.userName,
                    radius: 18,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appProv.userName,
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: isDark ? Colors.white12 : Colors.black12, width: 0.5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.globe, size: 10, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              'Community',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 4. Text Input
              TextField(
                controller: _contentCtrl,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                style: theme.textTheme.bodyLarge?.copyWith(fontSize: 16),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: "What did you complete today?",
                  hintStyle: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.6)),
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
              const SizedBox(height: 12),

              // 5. Image Preview
              if (_selectedImage != null) ...[
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(
                        _selectedImage!,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedImage = null),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(LucideIcons.x, size: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // 6. Stats Preview Card
              if (selectedItems.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceCard.withValues(alpha: 0.4) : Colors.grey[50],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(LucideIcons.barChart2, size: 14, color: AppColors.voltCyan),
                              const SizedBox(width: 8),
                              Text(
                                "Today's Stats",
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: AppColors.voltCyan,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () => setState(() => _selectedStats.clear()),
                            child: Icon(LucideIcons.trash2, size: 14, color: AppColors.textSecondary.withValues(alpha: 0.7)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: selectedItems.map((item) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(item.emoji, style: const TextStyle(fontSize: 14)),
                                const SizedBox(width: 6),
                                Text(
                                  item.formattedValue,
                                  style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 7. Mood Selector Section
              if (_showMoodSelector) ...[
                Text(
                  'How are you feeling?',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: _moodOptions.map((mood) {
                      final moodString = '${mood.emoji} ${mood.label}';
                      final isSelected = _selectedMood == moodString;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(moodString),
                          selected: isSelected,
                          onSelected: (val) {
                            setState(() {
                              if (val) {
                                _selectedMood = moodString;
                              } else {
                                _selectedMood = null;
                              }
                            });
                          },
                          backgroundColor: isDark ? AppColors.surfaceCard.withValues(alpha: 0.4) : Colors.grey[200],
                          selectedColor: AppColors.irisViolet.withValues(alpha: 0.15),
                          side: BorderSide(
                            color: isSelected 
                                ? AppColors.irisViolet.withValues(alpha: 0.6) 
                                : Colors.transparent,
                          ),
                          labelStyle: TextStyle(
                            color: isSelected ? AppColors.irisViolet : theme.colorScheme.onSurface,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 8. Add to post Action Chips
              Text(
                'Add to your post',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _ActionChip(
                    icon: LucideIcons.barChart2,
                    label: 'Add Stats',
                    isSelected: _selectedStats.isNotEmpty,
                    onTap: _openStatsSelector,
                    theme: theme,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  _ActionChip(
                    icon: LucideIcons.image,
                    label: 'Photo',
                    isSelected: _selectedImage != null,
                    onTap: _pickImage,
                    theme: theme,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  _ActionChip(
                    icon: LucideIcons.smile,
                    label: 'Mood',
                    isSelected: _selectedMood != null,
                    onTap: () {
                      setState(() {
                        _showMoodSelector = !_showMoodSelector;
                      });
                    },
                    theme: theme,
                    isDark: isDark,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 9. Activity Type Selector
              Text(
                'Activity Type',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              _ActivityTypeSelector(
                selectedActivity: _selectedActivity,
                onSelected: (act) => setState(() => _selectedActivity = act),
                isDark: isDark,
                theme: theme,
              ),
              const SizedBox(height: 24),

              // 10. Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: isEnabled ? _submit : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.irisViolet,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: isDark ? Colors.white10 : Colors.black12,
                    disabledForegroundColor: AppColors.textSecondary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Posting...',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          'Post',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: isEnabled ? Colors.white : AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Helpers & Inner Widgets ──

class MoodOption {
  final String label;
  final String emoji;
  const MoodOption(this.emoji, this.label);
}

class StatItem {
  final String key;
  final String label;
  final IconData icon;
  final String emoji;
  final String formattedValue;
  final bool isAvailable;

  StatItem({
    required this.key,
    required this.label,
    required this.icon,
    required this.emoji,
    required this.formattedValue,
    required this.isAvailable,
  });
}

List<StatItem> _getStatsList(BuildContext context) {
  final app = Provider.of<AppProvider>(context, listen: false);
  final stepTracker = Provider.of<StepTrackerProvider>(context, listen: false);
  final watch = Provider.of<WatchMetricsProvider>(context, listen: false);

  final int stepsVal = stepTracker.steps;
  final int activeMinVal = stepTracker.activeMinutes;
  final int streakVal = app.currentStreak;
  final int calVal = app.todayCalories > 0 ? app.todayCalories : stepTracker.calories;
  final int? hrVal = watch.isConnected ? watch.pulse : null;
  final double? sleepVal = watch.isConnected ? watch.sleepHours : null;
  final int workoutDurVal = app.todayDuration;
  final double distVal = stepTracker.distance > 0 ? stepTracker.distance : app.distance;

  final formatter = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
  String formatInt(int val) => val.toString().replaceAllMapped(formatter, (Match m) => '${m[1]},');

  return [
    StatItem(
      key: 'Steps',
      label: 'Steps',
      icon: LucideIcons.footprints,
      emoji: '👟',
      formattedValue: '${formatInt(stepsVal)} steps',
      isAvailable: stepsVal > 0,
    ),
    StatItem(
      key: 'Active Minutes',
      label: 'Active Minutes',
      icon: LucideIcons.zap,
      emoji: '⚡',
      formattedValue: '$activeMinVal active mins',
      isAvailable: activeMinVal > 0,
    ),
    StatItem(
      key: 'Streak',
      label: 'Streak',
      icon: LucideIcons.flame,
      emoji: '🔥',
      formattedValue: '$streakVal day streak',
      isAvailable: streakVal > 0,
    ),
    StatItem(
      key: 'Calories',
      label: 'Calories',
      icon: LucideIcons.flame,
      emoji: '🔥',
      formattedValue: '$calVal kcal',
      isAvailable: calVal > 0,
    ),
    StatItem(
      key: 'Heart Rate',
      label: 'Heart Rate',
      icon: LucideIcons.heart,
      emoji: '💓',
      formattedValue: hrVal != null && hrVal > 0 ? '$hrVal bpm' : 'Heart Rate — No data',
      isAvailable: hrVal != null && hrVal > 0,
    ),
    StatItem(
      key: 'Sleep',
      label: 'Sleep',
      icon: LucideIcons.moon,
      emoji: '💤',
      formattedValue: sleepVal != null && sleepVal > 0 ? '${sleepVal.toStringAsFixed(1)}h sleep' : 'Sleep — No data',
      isAvailable: sleepVal != null && sleepVal > 0,
    ),
    StatItem(
      key: 'Workout Duration',
      label: 'Workout Duration',
      icon: LucideIcons.timer,
      emoji: '⏱️',
      formattedValue: '$workoutDurVal min',
      isAvailable: workoutDurVal > 0,
    ),
    StatItem(
      key: 'Distance',
      label: 'Distance',
      icon: LucideIcons.mapPin,
      emoji: '📍',
      formattedValue: '${distVal.toStringAsFixed(2)} km',
      isAvailable: distVal > 0.0,
    ),
  ];
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final ThemeData theme;
  final bool isDark;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.irisViolet.withValues(alpha: 0.15)
              : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.irisViolet.withValues(alpha: 0.6)
                : (isDark ? Colors.white12 : Colors.black12),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppColors.irisViolet : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.irisViolet : theme.colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityTypeSelector extends StatelessWidget {
  final String selectedActivity;
  final ValueChanged<String> onSelected;
  final List<String> activities = const [
    'Running',
    'Workout',
    'Study',
    'Nutrition',
    'Recovery',
    'Cycling',
    'Swimming',
    'Yoga',
    'Meditation'
  ];
  final bool isDark;
  final ThemeData theme;

  const _ActivityTypeSelector({
    required this.selectedActivity,
    required this.onSelected,
    required this.isDark,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: activities.length,
        itemBuilder: (context, index) {
          final act = activities[index];
          final isSelected = selectedActivity == act;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              avatar: isSelected
                  ? const Icon(LucideIcons.check, size: 14, color: Colors.white)
                  : null,
              label: Text(act),
              selected: isSelected,
              onSelected: (val) {
                if (val) onSelected(act);
              },
              backgroundColor: isDark ? AppColors.surfaceElevated : Colors.grey[200],
              selectedColor: AppColors.irisViolet,
              checkmarkColor: Colors.white,
              showCheckmark: false,
              side: BorderSide(
                color: isSelected
                    ? Colors.transparent
                    : (isDark ? Colors.white12 : Colors.black12),
              ),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : theme.colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StatsStampSelector extends StatefulWidget {
  final Set<String> initiallySelected;
  final ValueChanged<Set<String>> onDone;

  const _StatsStampSelector({
    required this.initiallySelected,
    required this.onDone,
  });

  @override
  State<_StatsStampSelector> createState() => _StatsStampSelectorState();
}

class _StatsStampSelectorState extends State<_StatsStampSelector> {
  late Set<String> _localSelected;

  @override
  void initState() {
    super.initState();
    _localSelected = Set.from(widget.initiallySelected);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final stats = _getStatsList(context);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceElevated : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12, width: 0.5),
      ),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Title / Action Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Add Stats',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              TextButton(
                onPressed: () {
                  widget.onDone(_localSelected);
                  Navigator.pop(context);
                },
                child: const Text(
                  'Done',
                  style: TextStyle(color: AppColors.voltCyan, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // List of Stats
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: stats.length,
              separatorBuilder: (context, index) => Divider(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                height: 1,
              ),
              itemBuilder: (context, index) {
                final item = stats[index];
                final isSelected = _localSelected.contains(item.key);
                
                return Opacity(
                  opacity: item.isAvailable ? 1.0 : 0.45,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(item.emoji, style: const TextStyle(fontSize: 18)),
                    ),
                    title: Text(
                      item.label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    subtitle: Text(
                      item.formattedValue,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: item.isAvailable
                            ? AppColors.textSecondary
                            : AppColors.textSecondary.withValues(alpha: 0.8),
                      ),
                    ),
                    trailing: Switch.adaptive(
                      value: isSelected,
                      activeThumbColor: AppColors.voltCyan,
                      onChanged: item.isAvailable
                          ? (value) {
                              setState(() {
                                if (value) {
                                  _localSelected.add(item.key);
                                } else {
                                  _localSelected.remove(item.key);
                                }
                              });
                            }
                          : null,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
