import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../providers/watch_metrics_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/animated_card_enter.dart';
import '../widgets/daily_plan_tile.dart';
import '../widgets/metric_ring_card.dart';
import '../widgets/streak_badge.dart';
import '../widgets/add_plan_sheet.dart';
import '../widgets/dashboard_fun_widgets.dart';
import '../widgets/view_all_plans_sheet.dart';
import 'chat_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
                child: _buildStreakRow(theme, app),
              ),
              const SizedBox(height: AppSpacing.xl),


              // 2. Primary Hero Card (Metric Ring)
              AnimatedCardEnter(
                index: 2,
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
                index: 3,
                child: _buildQuickStats(theme, app, isDark, context),
              ),
              const SizedBox(height: AppSpacing.xl),

              // 4. Today's Plan
              AnimatedCardEnter(
                index: 4,
                child: _buildTodaysPlan(theme, isDark, app, context),
              ),
              const SizedBox(height: AppSpacing.xl),

              // 5. Community Teaser
              AnimatedCardEnter(
                index: 5,
                child: _buildCommunityTeaser(theme, isDark, context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStreakRow(ThemeData theme, AppProvider app) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            StreakBadge(
              count: app.currentStreak,
              isActive: app.currentStreak > 0,
              icon: app.isStreakPending ? LucideIcons.hourglass : LucideIcons.flame,
              activeColor: app.isStreakPending ? AppColors.borderSubtle : AppColors.solarAmber,
            ),
            const SizedBox(width: AppSpacing.sm),
            StreakBadge(
              count: DateTime.now().day,
              isActive: true,
              icon: LucideIcons.calendarCheck,
              activeColor: AppColors.voltCyan,
            ),
          ],
        ),
        const DailyQuoteSpark(),
      ],
    );
  }

  Widget _buildQuickStats(ThemeData theme, AppProvider app, bool isDark, BuildContext context) {
    final watchProvider = context.watch<WatchMetricsProvider>();
    final isConnected = watchProvider.isConnected;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          _QuickStatPill(
            icon: LucideIcons.cloudSun,
            label: 'Weather',
            value: '72° Sunny',
            color: AppColors.solarAmber,
            theme: theme,
            isDark: isDark,
          ),
          const SizedBox(width: AppSpacing.md),
          _QuickStatPill(
            icon: isConnected ? LucideIcons.heartPulse : LucideIcons.lock,
            label: 'Heart Rate',
            value: isConnected ? '${watchProvider.pulse > 0 ? watchProvider.pulse : 72} bpm' : '---',
            color: isConnected ? AppColors.pulseRed : (isDark ? Colors.white38 : Colors.black38),
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
            icon: isConnected ? LucideIcons.moon : LucideIcons.lock,
            label: 'Sleep Score',
            value: isConnected ? '85' : '---',
            color: isConnected ? AppColors.irisViolet : (isDark ? Colors.white38 : Colors.black38),
            theme: theme,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildTodaysPlan(ThemeData theme, bool isDark, AppProvider app, BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Today's Plan", style: theme.textTheme.headlineLarge),
            Row(
              children: [
                IconButton(
                  icon: const Icon(LucideIcons.plus, size: 20),
                  color: AppColors.voltCyan,
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => const AddPlanSheet(),
                    );
                  },
                ),
                TextButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => const ViewAllPlansSheet(),
                    );
                  },
                  child: Text(
                    'View All',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.voltCyan,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (app.dailyPlans.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.06),
              ),
            ),
            child: Column(
              children: [
                Icon(LucideIcons.calendarPlus, size: 32, color: AppColors.textSecondary),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'No plans yet',
                  style: theme.textTheme.titleMedium?.copyWith(color: AppColors.textPrimary),
                ),
                Text(
                  'Tap + to create your first plan',
                  style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          )
        else
          DailyPlanTile(
            activityName: app.dailyPlans.first.title,
            durationOrReps: app.dailyPlans.first.duration,
            kcal: app.dailyPlans.first.kcal,
            imageUrl: app.dailyPlans.first.imageUrl,
            onStart: () {
              app.setTabIndex(2);
            },
            onReplace: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const AddPlanSheet(),
              );
            },
          ),
      ],
    );
  }

  Widget _buildCommunityTeaser(ThemeData theme, bool isDark, BuildContext context) {
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
            onPressed: () {
              context.read<AppProvider>().setTabIndex(3);
            },
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
