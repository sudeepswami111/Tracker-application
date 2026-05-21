import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_colors.dart';

class HealthDateSelector extends StatefulWidget {
  final DateTime selectedDate;
  final List<DateTime> completedDates;
  final ValueChanged<DateTime> onDateSelected;
  final DateTime? startDate;
  final int dayCount;

  const HealthDateSelector({
    super.key,
    required this.selectedDate,
    required this.completedDates,
    required this.onDateSelected,
    this.startDate,
    this.dayCount = 15, // Default 15 days
  });

  @override
  State<HealthDateSelector> createState() => _HealthDateSelectorState();
}

class _HealthDateSelectorState extends State<HealthDateSelector> {
  late final ScrollController _scrollController;
  late final DateTime _startDate;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    // Default start date is 7 days before today
    _startDate = widget.startDate ?? DateTime.now().subtract(const Duration(days: 7));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedDate();
    });
  }

  @override
  void didUpdateWidget(covariant HealthDateSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDate != widget.selectedDate) {
      _scrollToSelectedDate();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToSelectedDate() {
    if (!_scrollController.hasClients) return;

    int selectedIndex = 0;
    for (int i = 0; i < widget.dayCount; i++) {
      final date = _startDate.add(Duration(days: i));
      if (date.year == widget.selectedDate.year &&
          date.month == widget.selectedDate.month &&
          date.day == widget.selectedDate.day) {
        selectedIndex = i;
        break;
      }
    }

    // Estimate item width + separator
    const double itemWidth = 52.0;
    const double separatorWidth = 12.0;
    final double offset = (selectedIndex * (itemWidth + separatorWidth)) -
        (MediaQuery.of(context).size.width / 2) +
        (itemWidth / 2);

    _scrollController.animateTo(
      offset.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SizedBox(
      height: 130, // Increased height to prevent shadow clipping and accommodate taller pills
      child: ListView.separated(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: widget.dayCount,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final date = _startDate.add(Duration(days: index));
          final isSelected = date.year == widget.selectedDate.year &&
              date.month == widget.selectedDate.month &&
              date.day == widget.selectedDate.day;

          final now = DateTime.now();
          final isToday = date.year == now.year &&
              date.month == now.month &&
              date.day == now.day;

          final isFuture = date.isAfter(DateTime(now.year, now.month, now.day, 23, 59, 59));

          final isCompleted = widget.completedDates.any((d) =>
              d.year == date.year && d.month == date.month && d.day == date.day);

          return GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              widget.onDateSelected(date);
            },
            behavior: HitTestBehavior.opaque,
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                width: isSelected ? 58 : 50,
                height: isSelected ? 102 : 88, // Increased pill heights to prevent bottom overflow
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [AppColors.irisViolet, Color(0xFF9D4EDD)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isSelected
                      ? null
                      : (isDark ? const Color(0xFF1A1A1A) : Colors.grey[100]),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.irisViolet.withValues(alpha: 0.8)
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.08)),
                    width: isSelected ? 1.5 : 1.0,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.irisViolet.withValues(alpha: 0.4),
                            blurRadius: 14,
                            spreadRadius: 2,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min, // Ensures content wraps perfectly without forcing overflow
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Weekday label e.g. "WED"
                    Text(
                      ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'][date.weekday - 1],
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.9)
                            : (isFuture
                                ? AppColors.textSecondary.withValues(alpha: 0.4)
                                : AppColors.textSecondary),
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                        fontSize: isSelected ? 11 : 10,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Date number e.g. "16"
                    Text(
                      '${date.day}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: isSelected
                            ? Colors.white
                            : (isFuture
                                ? AppColors.textPrimary.withValues(alpha: 0.4)
                                : AppColors.textPrimary),
                        fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                        fontSize: isSelected ? 22 : 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Bottom indicator: "TODAY" label or Check badge or dot
                    if (isToday && isSelected)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'TODAY',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      )
                    else if (isCompleted)
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: AppColors.voltCyan,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.check,
                          size: 12,
                          color: AppColors.backgroundDeep,
                        ),
                      )
                    else if (isToday)
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : AppColors.irisViolet,
                          shape: BoxShape.circle,
                        ),
                      )
                    else
                      const SizedBox(height: 12), // Placeholder to maintain height balance
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
