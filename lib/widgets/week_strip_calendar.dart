import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_colors.dart';

enum DayState {
  defaultState,
  completed,
  today,
  selected,
}

enum ModuleType {
  fitness,
  run,
  study,
  none,
}

class DayModel {
  final DateTime date;
  final DayState state;
  final ModuleType moduleType;

  DayModel({
    required this.date,
    required this.state,
    required this.moduleType,
  });
}

class WeekStripCalendar extends StatelessWidget {
  final List<DayModel> days;
  final ValueChanged<DateTime> onDaySelected;

  const WeekStripCalendar({
    super.key,
    required this.days,
    required this.onDaySelected,
  });

  Color _getModuleColor(ModuleType type) {
    switch (type) {
      case ModuleType.fitness:
        return AppColors.pulseRed;
      case ModuleType.run:
        return AppColors.voltCyan;
      case ModuleType.study:
        return AppColors.irisViolet;
      case ModuleType.none:
        return Colors.transparent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final day = days[index];
          final theme = Theme.of(context);
          
          return GestureDetector(
            onTap: () => onDaySelected(day.date),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][day.date.weekday - 1],
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: day.state == DayState.today ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                _buildDayPill(day, theme),
                const SizedBox(height: 6),
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _getModuleColor(day.moduleType),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDayPill(DayModel day, ThemeData theme) {
    BoxDecoration decoration;
    Widget? child;

    final baseTextStyle = theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600);

    switch (day.state) {
      case DayState.defaultState:
        decoration = BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.borderSubtle, width: 1),
        );
        child = Text('${day.date.day}', style: baseTextStyle?.copyWith(color: AppColors.textSecondary));
        break;
      case DayState.completed:
        decoration = BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.surfaceElevated,
          border: Border.all(color: AppColors.borderSubtle, width: 1),
        );
        child = Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Text('${day.date.day}', style: baseTextStyle?.copyWith(color: AppColors.textPrimary)),
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                decoration: const BoxDecoration(color: AppColors.voltCyan, shape: BoxShape.circle),
                padding: const EdgeInsets.all(2),
                child: const Icon(LucideIcons.check, size: 8, color: AppColors.backgroundDeep),
              ),
            ),
          ],
        );
        break;
      case DayState.today:
        decoration = const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.irisViolet,
        );
        child = Text('${day.date.day}', style: baseTextStyle?.copyWith(color: Colors.white));
        break;
      case DayState.selected:
        decoration = BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.voltCyan, width: 2),
        );
        child = Text('${day.date.day}', style: baseTextStyle?.copyWith(color: AppColors.textPrimary));
        break;
    }

    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: decoration,
      child: child,
    );
  }
}
