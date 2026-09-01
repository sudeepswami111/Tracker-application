import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../providers/app_provider.dart';
import '../services/dashboard_interaction_storage_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class SmartCalendarSheet extends StatefulWidget {
  const SmartCalendarSheet({super.key});

  @override
  State<SmartCalendarSheet> createState() => _SmartCalendarSheetState();
}

class _SmartCalendarSheetState extends State<SmartCalendarSheet>
    with SingleTickerProviderStateMixin {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  final TextEditingController _noteController = TextEditingController();
  bool _isSaving = false;
  String? _selectedMood;
  CalendarFormat _calendarFormat = CalendarFormat.week; // Default: Compact zero-scroll week strip
  int _activeTab = 0; // 0: Vibe & Notes, 1: Day Metrics, 2: Routine & Habits

  final List<String> _quickTags = [
    '#MorningRun',
    '#LegDay',
    '#UpperBody',
    '#HIIT',
    '#Recovery',
    '#Hydrated',
    '#RestDay',
  ];

  final List<Map<String, dynamic>> _moodOptions = [
    {'emoji': '⚡', 'label': 'Unstoppable', 'color': AppColors.voltCyan},
    {'emoji': '🔥', 'label': 'Energized', 'color': AppColors.solarAmber},
    {'emoji': '💪', 'label': 'Strong', 'color': const Color(0xFF00E599)},
    {'emoji': '😌', 'label': 'Rested', 'color': const Color(0xFF00B4D8)},
    {'emoji': '🥱', 'label': 'Fatigued', 'color': AppColors.coral},
  ];

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime(_focusedDay.year, _focusedDay.month, _focusedDay.day);
    _loadDayData(_selectedDay);
  }

  Future<void> _loadDayData(DateTime date) async {
    final noteStr = await DashboardInteractionStorageService.getCalendarNote(date);
    final moodStr = await DashboardInteractionStorageService.getDailyMood(date);
    if (mounted) {
      setState(() {
        _noteController.text = noteStr ?? '';
        _selectedMood = moodStr;
      });
    }
  }

  Future<void> _saveNoteAndMood() async {
    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    final date = _selectedDay;
    final text = _noteController.text.trim();

    if (text.isNotEmpty) {
      await DashboardInteractionStorageService.saveCalendarNote(date, text);
    } else {
      await DashboardInteractionStorageService.deleteCalendarNote(date);
    }

    if (_selectedMood != null) {
      await DashboardInteractionStorageService.saveDailyMood(date, _selectedMood!);
    }

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(LucideIcons.check, color: AppColors.voltCyan, size: 18),
              SizedBox(width: 8),
              Text(
                'Saved to Smart Calendar!',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF161F2E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _addTagToNote(String tag) {
    HapticFeedback.selectionClick();
    final current = _noteController.text;
    if (current.contains(tag)) return;
    final separator = current.isEmpty || current.endsWith(' ') ? '' : ' ';
    _noteController.text = '$current$separator$tag ';
    _noteController.selection = TextSelection.fromPosition(
      TextPosition(offset: _noteController.text.length),
    );
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isToday = isSameDay(_selectedDay, DateTime.now());

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F1520) : theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      height: MediaQuery.of(context).size.height * 0.85,
      child: Column(
        children: [
          // ── Drag Handle ──
          const SizedBox(height: 10),
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // ── Compact Header Bar ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppColors.voltCyan.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.voltCyan.withValues(alpha: 0.3),
                          width: 1.2,
                        ),
                      ),
                      child: const Icon(
                        LucideIcons.calendarCheck,
                        color: AppColors.voltCyan,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Smart Calendar',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                        Text(
                          DateFormat('MMMM yyyy').format(_focusedDay),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    // Format Toggle Pill (Week ⟷ Month)
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _calendarFormat = _calendarFormat == CalendarFormat.week
                                ? CalendarFormat.month
                                : CalendarFormat.week;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.06)
                                : Colors.black.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.voltCyan.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _calendarFormat == CalendarFormat.week
                                    ? LucideIcons.layoutGrid
                                    : LucideIcons.calendar,
                                size: 13,
                                color: AppColors.voltCyan,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                _calendarFormat == CalendarFormat.week ? 'Month' : 'Week',
                                style: const TextStyle(
                                  color: AppColors.voltCyan,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      icon: const Icon(LucideIcons.x, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // ── Table Calendar Container (Dynamic Week/Month Mode) ──
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF141D2B) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.05),
              ),
            ),
            child: TableCalendar(
              firstDay: DateTime.utc(2023, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              availableGestures: AvailableGestures.horizontalSwipe,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                HapticFeedback.selectionClick();
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
                _loadDayData(selectedDay);
              },
              onPageChanged: (focusedDay) {
                setState(() {
                  _focusedDay = focusedDay;
                });
              },
              rowHeight: 44,
              daysOfWeekHeight: 18,
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: TextStyle(
                  color: isDark ? Colors.white38 : Colors.black38,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
                weekendStyle: TextStyle(
                  color: isDark ? Colors.white24 : Colors.black26,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                defaultTextStyle: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                weekendTextStyle: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black54,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                selectedDecoration: BoxDecoration(
                  color: AppColors.voltCyan,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.voltCyan.withValues(alpha: 0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                selectedTextStyle: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
                todayDecoration: BoxDecoration(
                  color: AppColors.voltCyan.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.voltCyan, width: 1.2),
                ),
                todayTextStyle: const TextStyle(
                  color: AppColors.voltCyan,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
              headerVisible: false, // Clean minimalist strip
            ),
          ),

          const SizedBox(height: 10),

          // ── Selected Day Banner & Interactive Segmented Switcher ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      DateFormat('EEE, d MMM').format(_selectedDay),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (isToday) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.voltCyan.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'TODAY',
                          style: TextStyle(
                            color: AppColors.voltCyan,
                            fontWeight: FontWeight.w900,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                // 3-Segment Deck Switcher
                Container(
                  padding: const EdgeInsets.all(2.5),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      _buildTabButton(0, 'Log', LucideIcons.penLine, isDark),
                      _buildTabButton(1, 'Metrics', LucideIcons.activity, isDark),
                      _buildTabButton(2, 'Habits', LucideIcons.checkSquare, isDark),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // ── Zero-Scroll Tab Content Deck ──
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _buildCurrentTabContent(app, theme, isDark, isToday),
              ),
            ),
          ),

          // ── Fixed Action Bottom Bar (Always Visible, Zero Scrolling Needed) ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0C111A) : const Color(0xFFF8FAFC),
              border: Border(
                top: BorderSide(
                  color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06),
                ),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveNoteAndMood,
                icon: _isSaving
                    ? const SizedBox(
                        height: 14,
                        width: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                    : const Icon(LucideIcons.save, size: 16),
                label: Text(
                  _isSaving ? 'Saving...' : 'Save for ${DateFormat('MMM d').format(_selectedDay)}',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.voltCyan,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab Pill Switcher Helper ──
  Widget _buildTabButton(int index, String label, IconData icon, bool isDark) {
    final isSelected = _activeTab == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _activeTab = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.voltCyan : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 12,
              color: isSelected
                  ? Colors.black
                  : (isDark ? Colors.white60 : Colors.black54),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? Colors.black
                    : (isDark ? Colors.white60 : Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Deck Switcher Content ──
  Widget _buildCurrentTabContent(AppProvider app, ThemeData theme, bool isDark, bool isToday) {
    switch (_activeTab) {
      case 1:
        return _buildMetricsTab(app, theme, isDark, isToday);
      case 2:
        return _buildHabitsTab(app, theme, isDark);
      case 0:
      default:
        return _buildVibeAndNoteTab(theme, isDark);
    }
  }

  // ── Tab 0: Vibe & Notes (Compact & Structured) ──
  Widget _buildVibeAndNoteTab(ThemeData theme, bool isDark) {
    return SingleChildScrollView(
      key: const ValueKey('tab_vibe'),
      physics: const ClampingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 5 Mood Emojis
          Row(
            children: _moodOptions.map((opt) {
              final isSelected = _selectedMood == opt['label'];
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.5),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _selectedMood = isSelected ? null : opt['label'];
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (opt['color'] as Color).withValues(alpha: 0.2)
                            : (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.04)),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? (opt['color'] as Color)
                              : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06)),
                          width: isSelected ? 1.4 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(opt['emoji'] as String, style: const TextStyle(fontSize: 16)),
                          const SizedBox(height: 2),
                          Text(
                            opt['label'] as String,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                              color: isSelected ? (opt['color'] as Color) : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 8),

          // Quick Activity Tags
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _quickTags.map((tag) {
                return Padding(
                  padding: const EdgeInsets.only(right: 5),
                  child: ActionChip(
                    label: Text(tag),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    labelStyle: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                    side: BorderSide(
                      color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08),
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onPressed: () => _addTagToNote(tag),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 8),

          // Compact Note Input with Safe Scroll
          TextField(
            controller: _noteController,
            minLines: 3,
            maxLines: 5,
            textAlignVertical: TextAlignVertical.top,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white : Colors.black87,
            ),
            decoration: InputDecoration(
              hintText: 'Record PRs, splits, reflections, or reminders...',
              hintStyle: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
              filled: true,
              fillColor: isDark ? const Color(0xFF141D2B) : const Color(0xFFF1F5F9),
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.voltCyan, width: 1.2),
              ),
            ),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  // ── Tab 1: Day Metrics Snapshot ──
  Widget _buildMetricsTab(AppProvider app, ThemeData theme, bool isDark, bool isToday) {
    return Column(
      key: const ValueKey('tab_metrics'),
      children: [
        Row(
          children: [
            _buildMiniMetricCard(
              icon: LucideIcons.footprints,
              title: isToday ? '${app.steps}' : '--',
              subtitle: 'Steps Walked',
              color: AppColors.voltCyan,
              isDark: isDark,
            ),
            const SizedBox(width: 8),
            _buildMiniMetricCard(
              icon: LucideIcons.flame,
              title: isToday ? '${app.calories} kcal' : '--',
              subtitle: 'Burned',
              color: AppColors.solarAmber,
              isDark: isDark,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildMiniMetricCard(
              icon: LucideIcons.droplets,
              title: isToday ? '${app.waterGlasses} Cups' : '--',
              subtitle: 'Water Logged',
              color: const Color(0xFF00B4D8),
              isDark: isDark,
            ),
            const SizedBox(width: 8),
            _buildMiniMetricCard(
              icon: LucideIcons.moon,
              title: isToday ? '${app.sleepHours.toStringAsFixed(1)}h' : '--',
              subtitle: 'Sleep Quality',
              color: AppColors.irisViolet,
              isDark: isDark,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF141D2B) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(LucideIcons.sparkles, size: 14, color: AppColors.voltCyan),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isToday
                      ? 'Current Streak: ${app.currentStreak} days active!'
                      : 'Past log record for ${DateFormat('MMMM d').format(_selectedDay)}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Tab 2: Routine & Habits Checklist ──
  Widget _buildHabitsTab(AppProvider app, ThemeData theme, bool isDark) {
    final plans = app.dailyPlans;
    if (plans.isEmpty) {
      return Center(
        key: const ValueKey('tab_habits_empty'),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.calendarCheck, size: 28, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
            const SizedBox(height: 6),
            Text(
              'No custom plans for this day',
              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      key: const ValueKey('tab_habits_list'),
      itemCount: plans.length,
      padding: EdgeInsets.zero,
      itemBuilder: (context, index) {
        final plan = plans[index];
        final isDone = plan.isCompleted;
        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF141D2B) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDone
                  ? AppColors.voltCyan.withValues(alpha: 0.3)
                  : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04)),
            ),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  app.togglePlanComplete(plan.id);
                },
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: isDone ? AppColors.voltCyan : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isDone ? AppColors.voltCyan : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                      width: 1.4,
                    ),
                  ),
                  child: isDone ? const Icon(LucideIcons.check, size: 14, color: Colors.black) : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  plan.title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                    color: isDone ? theme.colorScheme.onSurfaceVariant : (isDark ? Colors.white : Colors.black87),
                  ),
                ),
              ),
              Text(
                plan.duration,
                style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Mini Metric Card Helper ──
  Widget _buildMiniMetricCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool isDark,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF141D2B) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 14, color: color),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
