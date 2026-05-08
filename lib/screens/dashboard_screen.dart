import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/animated_card_enter.dart';
import '../widgets/daily_plan_tile.dart';
import '../widgets/metric_ring_card.dart';
import '../widgets/streak_badge.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final longestStreak = app.streaks.isEmpty
        ? 0
        : app.streaks.values.reduce((a, b) => a > b ? a : b);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(
            left: AppSpacing.screenMargin,
            right: AppSpacing.screenMargin,
            top: AppSpacing.xl,
            bottom: AppSpacing.navHeight + 32,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Streak Row
              AnimatedCardEnter(
                index: 0,
                child: _buildStreakRow(theme, longestStreak),
              ),
              const SizedBox(height: AppSpacing.xl),

              // 2. Primary Hero Card (Metric Ring)
              AnimatedCardEnter(
                index: 1,
                child: MetricRingCard(
                  progress: app.steps / app.stepsGoal,
                  value: app.steps.toString(),
                  unit: 'STEPS',
                  label: "Today's Activity",
                  ringColor: AppColors.voltCyan,
                  icon: LucideIcons.footprints,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // 3. Quick Stats Strip
              AnimatedCardEnter(
                index: 2,
                child: _buildQuickStats(theme, app, isDark),
              ),
              const SizedBox(height: AppSpacing.xl),

              // 4. Today's Plan
              AnimatedCardEnter(
                index: 3,
                child: _buildTodaysPlan(theme, isDark),
              ),
              const SizedBox(height: AppSpacing.xl),

              // 5. Community Teaser
              AnimatedCardEnter(
                index: 4,
                child: _buildCommunityTeaser(theme, isDark),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStreakRow(ThemeData theme, int streakCount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            StreakBadge(
              count: streakCount,
              isActive: streakCount > 0,
              icon: LucideIcons.flame,
              activeColor: AppColors.solarAmber,
            ),
            const SizedBox(width: AppSpacing.sm),
            StreakBadge(
              count: 4,
              isActive: true,
              icon: LucideIcons.calendarCheck,
              activeColor: AppColors.voltCyan,
            ),
          ],
        ),
        SizedBox(
          width: 48,
          height: 48,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: 0.75,
                strokeWidth: 4,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                valueColor: const AlwaysStoppedAnimation(AppColors.irisViolet),
              ),
              const Icon(LucideIcons.target, size: 16, color: AppColors.irisViolet),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStats(ThemeData theme, AppProvider app, bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          _QuickStatPill(
            icon: LucideIcons.heartPulse,
            label: 'Heart Rate',
            value: '72 bpm',
            color: AppColors.pulseRed,
            theme: theme,
            isDark: isDark,
          ),
          const SizedBox(width: AppSpacing.md),
          _QuickStatPill(
            icon: LucideIcons.activity,
            label: 'Active Mins',
            value: '45 m',
            color: AppColors.voltCyan,
            theme: theme,
            isDark: isDark,
          ),
          const SizedBox(width: AppSpacing.md),
          _QuickStatPill(
            icon: LucideIcons.moon,
            label: 'Sleep Score',
            value: '85',
            color: AppColors.irisViolet,
            theme: theme,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildTodaysPlan(ThemeData theme, bool isDark) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Today's Plan", style: theme.textTheme.headlineLarge),
            TextButton(
              onPressed: () {},
              child: Text(
                'View All',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.voltCyan,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        DailyPlanTile(
          activityName: 'Morning Run 5K',
          durationOrReps: '30 min',
          kcal: '320 kcal',
          imageUrl:
              'https://images.unsplash.com/photo-1552674605-db6ffd4facb5?auto=format&fit=crop&w=150&q=80',
          onStart: () {},
          onReplace: () {},
        ),
      ],
    );
  }

  Widget _buildCommunityTeaser(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Community Feed", style: theme.textTheme.headlineLarge),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.06),
            ),
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 16,
                backgroundImage:
                    NetworkImage('https://i.pravatar.cc/150?img=33'),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Sarah completed a 10K run!',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              const Icon(LucideIcons.zap, size: 16, color: AppColors.solarAmber),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(
                color: isDark
                    ? AppColors.borderSubtle
                    : AppColors.lightOutline,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              ),
            ),
            child: Text(
              'Open Community',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickStatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final ThemeData theme;
  final bool isDark;

  const _QuickStatPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(fontSize: 10),
              ),
              Text(
                value,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
