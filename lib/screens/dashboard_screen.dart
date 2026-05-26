import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../services/community_service.dart';

import '../providers/watch_metrics_provider.dart';
import '../providers/step_tracker_provider.dart';
import '../providers/weather_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'challenge_screen.dart';
import '../widgets/animated_card_enter.dart';
import '../widgets/daily_plan_tile.dart';
import '../widgets/metric_ring_card.dart';
import '../widgets/unified_activity_card.dart';
import '../widgets/streak_badge.dart';
import '../widgets/add_plan_sheet.dart';
import '../widgets/dashboard_fun_widgets.dart';
import '../widgets/view_all_plans_sheet.dart';
import '../widgets/weather_widgets.dart';
import '../widgets/people_suggestion_section.dart';
import '../widgets/streak_details_sheet.dart';
import '../widgets/smart_calendar_sheet.dart';
import '../widgets/smart_today_plan_card.dart';
import '../widgets/dashboard_community_section.dart';

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
                child: _buildStreakRow(theme, app, context),
              ),
              const SizedBox(height: AppSpacing.xl),

              // 2. Primary Hero Card (Unified Activity)
              AnimatedCardEnter(
                index: 2,
                child: Consumer2<StepTrackerProvider, WatchMetricsProvider>(
                  builder: (context, stepTracker, watchProvider, child) {
                    return UnifiedActivityCard(
                      steps: stepTracker.steps,
                      stepGoal: 10000,
                      activeMinutes: stepTracker.activeMinutes,
                      heartRate: watchProvider.pulse,
                      sleepDuration: watchProvider.sleepHours,
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
                child: const DashboardCommunitySection(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStreakRow(ThemeData theme, AppProvider app, BuildContext context) {
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
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => StreakDetailsSheet(app: app),
                );
              },
            ),
            const SizedBox(width: AppSpacing.sm),
            StreakBadge(
              count: DateTime.now().day,
              isActive: true,
              icon: LucideIcons.calendarCheck,
              activeColor: AppColors.voltCyan,
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => const SmartCalendarSheet(),
                );
              },
            ),
          ],
        ),
        const DailyQuoteSpark(),
      ],
    );
  }


  Widget _buildTodaysPlan(ThemeData theme, bool isDark, AppProvider app, BuildContext context) {
    final plans = app.dailyPlans;
    final planCount = plans.length;
    final weather = context.watch<WeatherProvider>().weather;

    return Column(
      children: [
        // ── Header row ──
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text("Today's Plan", style: theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold)),
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

        // ── Plans: Smart cards for all plans ──
        else
          Column(
            children: plans.map((plan) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: SmartTodayPlanCard(
                plan: plan,
                weather: weather,
                app: app,
                onStart: () {
                  if (!plan.isCompleted) {
                    app.setActiveRunPlan(plan);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ChallengeScreen()));
                  } else {
                    app.togglePlanComplete(plan.id);
                  }
                },
                onDelete: () => app.removeDailyPlan(plan.id),
              ),
            )).toList(),
          ),
      ],
    );
  }
}
