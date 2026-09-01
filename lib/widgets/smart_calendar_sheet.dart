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
  final List<String> _quickTags = [
    '#MorningRun',
    '#LegDay',
    '#UpperBody',
    '#HIIT',
    '#Recovery',
    '#Hydrated',
    '#PeakEnergy',
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
                'Smart Calendar updated!',
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
      height: MediaQuery.of(context).size.height * 0.88,
      child: Column(
        children: [
          // ── Sheet Drag Handle ──
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Header Row ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.voltCyan.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.voltCyan.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        LucideIcons.calendarCheck,
                        color: AppColors.voltCyan,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Smart Calendar',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          'Activity & Daily Planner',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.x, size: 18),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          Divider(
            color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06),
            height: 1,
          ),

          // ── Scrollable Body ──
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Quick Monthly Summary Chips ──
                  Row(
                    children: [
                      _buildMonthStatBadge(
                        icon: LucideIcons.flame,
                        color: AppColors.solarAmber,
                        value: '${app.currentStreak} Days',
                        label: 'Streak',
                        isDark: isDark,
                      ),
                      const SizedBox(width: 8),
                      _buildMonthStatBadge(
                        icon: LucideIcons.activity,
                        color: AppColors.voltCyan,
                        value: '${app.weeklyCompleted} Done',
                        label: 'This Week',
                        isDark: isDark,
                      ),
                      const SizedBox(width: 8),
                      _buildMonthStatBadge(
                        icon: LucideIcons.droplets,
                        color: const Color(0xFF00B4D8),
                        value: '${app.waterGlasses}/8 Cups',
                        label: 'Hydration',
                        isDark: isDark,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ── Table Calendar Glass Container ──
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF141D2B) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
                      ),
                      boxShadow: isDark
                          ? []
                          : [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                    ),
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TableCalendar(
                      firstDay: DateTime.utc(2023, 1, 1),
                      lastDay: DateTime.utc(2030, 12, 31),
                      focusedDay: _focusedDay,
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
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        selectedTextStyle: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                        todayDecoration: BoxDecoration(
                          color: AppColors.voltCyan.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.voltCyan, width: 1.5),
                        ),
                        todayTextStyle: const TextStyle(
                          color: AppColors.voltCyan,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                      headerStyle: HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                        titleTextStyle: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ) ??
                            const TextStyle(fontWeight: FontWeight.w800),
                        leftChevronIcon: Icon(
                          LucideIcons.chevronLeft,
                          size: 20,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                        rightChevronIcon: Icon(
                          LucideIcons.chevronRight,
                          size: 20,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Selected Date Title & Badge ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('EEEE, d MMMM').format(_selectedDay),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            isToday
                                ? "Today's Log & Wellness Note"
                                : 'Log for this day',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      if (isToday)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.voltCyan.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.voltCyan.withValues(alpha: 0.3)),
                          ),
                          child: const Text(
                            'TODAY',
                            style: TextStyle(
                              color: AppColors.voltCyan,
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ── Mood & Energy Selector ──
                  Text(
                    'Daily Vibe & Energy',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: _moodOptions.map((opt) {
                      final isSelected = _selectedMood == opt['label'];
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _selectedMood = isSelected ? null : opt['label'];
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (opt['color'] as Color).withValues(alpha: 0.2)
                                : (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.04)),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? (opt['color'] as Color)
                                  : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06)),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(opt['emoji'] as String, style: const TextStyle(fontSize: 20)),
                              const SizedBox(height: 4),
                              Text(
                                opt['label'] as String,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                                  color: isSelected ? (opt['color'] as Color) : theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),

                  // ── Smart Tags Row ──
                  Text(
                    'Quick Activity Tags',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _quickTags.map((tag) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ActionChip(
                            label: Text(tag),
                            labelStyle: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white87 : Colors.black87,
                            ),
                            backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                            side: BorderSide(
                              color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1),
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            onPressed: () => _addTagToNote(tag),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Daily Reflection / Note ──
                  Text(
                    'Daily Note & Workout Reflection',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _noteController,
                    maxLines: 3,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Record PRs, workout notes, recovery, or reminders...',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF141D2B) : const Color(0xFFF1F5F9),
                      contentPadding: const EdgeInsets.all(14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.voltCyan, width: 1.5),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Save Action Button ──
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveNoteAndMood,
                      icon: _isSaving
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                            )
                          : const Icon(LucideIcons.save, size: 18),
                      label: Text(
                        _isSaving ? 'Saving...' : 'Save Log & Note',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.voltCyan,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Stat Badge Helper ──
  Widget _buildMonthStatBadge({
    required IconData icon,
    required Color color,
    required String value,
    required String label,
    required bool isDark,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF141D2B) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.05),
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
              child: Icon(icon, color: color, size: 14),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
