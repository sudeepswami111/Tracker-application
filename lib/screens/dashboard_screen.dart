import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../providers/friend_provider.dart';
import '../providers/watch_metrics_provider.dart';
import '../providers/step_tracker_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/animated_card_enter.dart';
import '../widgets/daily_plan_tile.dart';
import '../widgets/metric_ring_card.dart';
import '../widgets/streak_badge.dart';
import '../widgets/add_plan_sheet.dart';
import '../widgets/dashboard_fun_widgets.dart';
import '../widgets/view_all_plans_sheet.dart';
import '../widgets/weather_widgets.dart';
import '../widgets/people_suggestion_section.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  Color _getAccentColor(String type) {
    switch (type) {
      case 'Run':
        return AppColors.pulseRed;
      case 'Yoga':
      case 'Swim':
        return AppColors.voltCyan;
      case 'Gym':
        return AppColors.solarAmber;
      case 'Cycle':
        return AppColors.irisViolet;
      default:
        return AppColors.pulseRed;
    }
  }

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
            bottom: 150, // Enough padding to prevent bottom nav overlap
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


              // 2. Health Stats Strip (Heart Rate, Active Mins, Sleep Score)
              AnimatedCardEnter(
                index: 2,
                child: _buildHealthStats(theme, app, isDark, context),
              ),
              const SizedBox(height: AppSpacing.xl),

              // 3. Primary Hero Card (Metric Ring - Today's Activity)
              AnimatedCardEnter(
                index: 3,
                child: Consumer<StepTrackerProvider>(
                  builder: (context, stepTracker, child) {
                    if (!stepTracker.isAvailable && !stepTracker.isLoading) {
                      return MetricRingCard(
                        progress: 0,
                        value: 'N/A',
                        unit: 'UNSUPPORTED',
                        label: "Today's Activity",
                        ringColor: AppColors.textSecondary,
                        icon: LucideIcons.footprints,
                      );
                    }
                    return MetricRingCard(
                      progress: stepTracker.progress,
                      value: stepTracker.steps.toString(),
                      unit: 'STEPS',
                      label: "Today's Activity",
                      ringColor: AppColors.voltCyan,
                      icon: LucideIcons.footprints,
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // 3.5 Weather Integration (DashboardWeatherSection)
              AnimatedCardEnter(
                index: 4,
                child: const DashboardWeatherSection(),
              ),
              const SizedBox(height: AppSpacing.xl),

              // 4. Today's Plan
              AnimatedCardEnter(
                index: 4,
                child: _buildTodaysPlan(theme, isDark, app, context),
              ),
              const SizedBox(height: AppSpacing.xl),

              // 5. People You May Know
              AnimatedCardEnter(
                index: 5,
                child: const PeopleSuggestionSection(),
              ),
              const SizedBox(height: AppSpacing.xl),

              // 6. Community Teaser
              AnimatedCardEnter(
                index: 6,
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

  Widget _buildHealthStats(ThemeData theme, AppProvider app, bool isDark, BuildContext context) {
    final watchProvider = context.watch<WatchMetricsProvider>();
    final isConnected = watchProvider.isConnected;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          _QuickStatPill(
            icon: isConnected ? LucideIcons.heartPulse : LucideIcons.lock,
            label: 'Heart Rate',
            value: isConnected ? '${watchProvider.pulse > 0 ? watchProvider.pulse : 72} bpm' : '---',
            color: isConnected ? AppColors.pulseRed : (isDark ? Colors.white38 : Colors.black38),
            theme: theme,
            isDark: isDark,
          ),
          const SizedBox(width: AppSpacing.md),
          Consumer<StepTrackerProvider>(
            builder: (context, stepTracker, _) => _QuickStatPill(
              icon: LucideIcons.activity,
              label: 'Active Mins',
              value: '${stepTracker.activeMinutes} m',
              color: AppColors.voltCyan,
              theme: theme,
              isDark: isDark,
            ),
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
    final plans = app.dailyPlans;
    final planCount = plans.length;

    return Column(
      children: [
        // ── Header row ──
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text("Today's Plan", style: theme.textTheme.headlineLarge),
                if (planCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.voltCyan.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$planCount',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.voltCyan,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
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

        // ── Empty State ──
        if (plans.isEmpty)
          GestureDetector(
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const AddPlanSheet(),
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.08),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.voltCyan.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(LucideIcons.plus, color: AppColors.voltCyan, size: 28),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Plan your first workout',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap anywhere to add a plan',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          )

        // ── Plans: single full-width or horizontal scroll (up to 3) ──
        else if (planCount == 1)
          DailyPlanTile(
            activityName: plans.first.title,
            durationOrReps: plans.first.duration,
            kcal: plans.first.kcal,
            imageUrl: plans.first.imageUrl,
            isCompleted: plans.first.isCompleted,
            accentColor: _getAccentColor(plans.first.type),
            onStart: () {
              if (!plans.first.isCompleted) {
                app.setActiveRunPlan(plans.first);
                app.setTabIndex(2);
              } else {
                app.togglePlanComplete(plans.first.id);
              }
            },
            onDelete: () => app.removeDailyPlan(plans.first.id),
          )
        else
          SizedBox(
            height: 185,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: planCount.clamp(0, 3),
              itemBuilder: (context, index) {
                final plan = plans[index];
                return Padding(
                  padding: EdgeInsets.only(right: index < planCount.clamp(0, 3) - 1 ? 12 : 0),
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width - 64,
                    child: DailyPlanTile(
                      activityName: plan.title,
                      durationOrReps: plan.duration,
                      kcal: plan.kcal,
                      imageUrl: plan.imageUrl,
                      isCompleted: plan.isCompleted,
                      accentColor: _getAccentColor(plan.type),
                      onStart: () {
                        if (!plan.isCompleted) {
                          app.setActiveRunPlan(plan);
                          app.setTabIndex(2);
                        } else {
                          app.togglePlanComplete(plan.id);
                        }
                      },
                      onDelete: () => app.removeDailyPlan(plan.id),
                    ),
                  ),
                );
              },
            ),
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
