import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../providers/app_provider.dart';
import '../theme/app_colors.dart';

class StreakDetailsSheet extends StatelessWidget {
  final AppProvider app;
  
  const StreakDetailsSheet({super.key, required this.app});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.flame, color: AppColors.solarAmber, size: 28),
                  const SizedBox(width: 8),
                  Text('Streak Details', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              IconButton(
                icon: const Icon(LucideIcons.x),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          Center(
            child: Column(
              children: [
                Text(
                  '${app.currentStreak}',
                  style: theme.textTheme.displayLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.solarAmber,
                  ),
                ),
                Text('Day Streak', style: theme.textTheme.titleMedium?.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn('Best Streak', '${app.longestStreak} Days', theme),
                _buildStatColumn('Status', app.isStreakPending ? 'Pending' : 'Active', theme),
                _buildStatColumn('Next Goal', '${((app.currentStreak / 7).floor() + 1) * 7} Days', theme),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Text('Keep it up! Small steps lead to big changes.', 
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, ThemeData theme) {
    return Column(
      children: [
        Text(label, style: theme.textTheme.labelSmall?.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        Text(value, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
