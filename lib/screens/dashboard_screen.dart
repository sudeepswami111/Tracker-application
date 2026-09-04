import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/app_provider.dart';
import '../providers/watch_metrics_provider.dart';
import '../providers/step_tracker_provider.dart';
import '../providers/weather_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'challenge_screen.dart';
import 'study_screen.dart';
import 'workout/fitness_screen.dart';
import '../widgets/animated_card_enter.dart';
import '../widgets/unified_activity_card.dart';
import '../widgets/streak_badge.dart';
import '../widgets/add_plan_sheet.dart';
import '../widgets/dashboard_fun_widgets.dart';
import '../widgets/view_all_plans_sheet.dart';
import '../widgets/weather_widgets.dart';
import '../widgets/streak_details_sheet.dart';
import '../widgets/smart_calendar_sheet.dart';
import '../widgets/smart_today_plan_card.dart';
import '../widgets/milestone_trophy_section.dart';
import '../widgets/hydration_hub_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.zenDarkBg : AppColors.lightBg,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.primaryTeal,
          onRefresh: () async {
            await Future.wait([
              context.read<StepTrackerProvider>().refreshSteps(),
              context.read<WatchMetricsProvider>().refresh(),
            ]);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(
              left: AppSpacing.screenMargin,
              right: AppSpacing.screenMargin,
              top: AppSpacing.md,
              bottom: 150, // Bottom nav clearance
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 1. Top Streak & Calendar Header ──
                AnimatedCardEnter(
                  index: 0,
                  child: _buildStreakRow(theme, app, context),
                ),
                const SizedBox(height: 16),

                // ── 2. Large Circular Steps Progress Card ──
                AnimatedCardEnter(
                  index: 1,
                  child: Consumer2<StepTrackerProvider, WatchMetricsProvider>(
                    builder: (context, stepTracker, watchProvider, child) {
                      return UnifiedActivityCard(
                        steps: stepTracker.steps,
                        stepGoal: app.stepsGoal,
                        activeMinutes: stepTracker.activeMinutes,
                        heartRate: watchProvider.pulse ?? 0,
                        sleepDuration: watchProvider.sleepHours ?? 0.0,
                        calories: (stepTracker.steps * 0.04).round().clamp(100, 2500),
                        showHealthMetrics: watchProvider.isConnected,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // ── 3. Today's Journey (Reference Design Feature) ──
                AnimatedCardEnter(
                  index: 2,
                  child: _buildTodaysJourney(context, isDark, app),
                ),
                const SizedBox(height: 24),

                // ── 4. Today's Plan (Dynamic Workout Plans) ──
                AnimatedCardEnter(
                  index: 3,
                  child: _buildTodaysPlan(theme, isDark, app, context),
                ),
                const SizedBox(height: 24),

                // ── 5. Hydration Hub ──
                const AnimatedCardEnter(
                  index: 4,
                  child: HydrationHubCard(),
                ),
                const SizedBox(height: 24),

                // ── 6. Weather & Outdoor Context ──
                const AnimatedCardEnter(
                  index: 5,
                  child: DashboardWeatherSection(),
                ),
                const SizedBox(height: 24),

                // ── 7. Milestones & Trophy Vault ──
                const AnimatedCardEnter(
                  index: 6,
                  child: MilestoneTrophySection(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStreakRow(ThemeData theme, AppProvider app, BuildContext context) {
    final isDark = theme.brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            StreakBadge(
              count: app.currentStreak,
              isActive: app.currentStreak > 0,
              icon: app.isStreakPending ? LucideIcons.hourglass : LucideIcons.flame,
              activeColor: app.isStreakPending ? AppColors.neutralGray : AppColors.accentOrange,
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
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  HapticFeedback.selectionClick();
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => const SmartCalendarSheet(),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? Colors.white.withValues(alpha: 0.1) : AppColors.cardBorder,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.calendar, size: 14, color: AppColors.primaryTeal),
                      const SizedBox(width: 6),
                      Text(
                        DateFormat('MMM d').format(DateTime.now()),
                        style: GoogleFonts.inter(
                          color: isDark ? Colors.white : AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const DailyQuoteSpark(),
      ],
    );
  }

  // ─── Today's Journey Section from Reference Design ───
  Widget _buildTodaysJourney(BuildContext context, bool isDark, AppProvider app) {
    final journeyItems = [
      _JourneyActivity(
        title: 'Walk',
        statusText: '${(app.distance > 0 ? app.distance : 2.4).toStringAsFixed(1)} km',
        icon: LucideIcons.checkCircle2,
        iconColor: AppColors.primaryGreen,
        iconBgColor: AppColors.primaryGreen.withValues(alpha: 0.12),
        onTap: () => app.setTabIndex(2), // Switch to Run/Walk
      ),
      _JourneyActivity(
        title: 'Workout',
        statusText: 'In progress',
        icon: LucideIcons.dumbbell,
        iconColor: AppColors.secondaryBlue,
        iconBgColor: AppColors.secondaryBlue.withValues(alpha: 0.12),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FitnessScreen())),
      ),
      _JourneyActivity(
        title: 'Study',
        statusText: '${(app.totalStudyMinutes / 60).toStringAsFixed(1)}h 30m',
        icon: LucideIcons.bookOpen,
        iconColor: AppColors.secondaryBlue,
        iconBgColor: AppColors.secondaryBlue.withValues(alpha: 0.12),
        onTap: () => app.setTabIndex(4), // Switch to Study Tab
      ),
      _JourneyActivity(
        title: 'Meditation',
        statusText: '10 min',
        icon: LucideIcons.sparkles,
        iconColor: AppColors.primaryGreen,
        iconBgColor: AppColors.primaryGreen.withValues(alpha: 0.12),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FitnessScreen())),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Today's Journey",
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => const SmartCalendarSheet(),
                );
              },
              child: Text(
                'View All',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryTeal,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.zenDarkCard : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.cardBorder,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: journeyItems.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                thickness: 1,
                color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9),
              ),
              itemBuilder: (context, index) {
                final item = journeyItems[index];
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: item.onTap,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: item.iconBgColor,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(item.icon, size: 16, color: item.iconColor),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              item.title,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            item.statusText,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white60 : AppColors.neutralGray,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            LucideIcons.chevronRight,
                            size: 14,
                            color: AppColors.neutralGray,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTodaysPlan(ThemeData theme, bool isDark, AppProvider app, BuildContext context) {
    final plans = app.dailyPlans;
    final planCount = plans.length;
    final weather = context.watch<WeatherProvider>().weather;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  "Today's Plan",
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                if (planCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primaryTeal.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$planCount',
                      style: GoogleFonts.inter(
                        color: AppColors.primaryTeal,
                        fontSize: 11,
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
                  icon: const Icon(LucideIcons.plus, size: 18),
                  color: AppColors.primaryTeal,
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
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryTeal,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),

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
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
              decoration: BoxDecoration(
                color: isDark ? AppColors.zenDarkCard : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.cardBorder,
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.primaryTeal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(LucideIcons.plus, color: AppColors.primaryTeal, size: 26),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Plan your first workout',
                    style: GoogleFonts.inter(
                      color: isDark ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap anywhere to add an activity',
                    style: GoogleFonts.inter(
                      color: AppColors.neutralGray,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          )
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

class _JourneyActivity {
  final String title;
  final String statusText;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final VoidCallback onTap;

  _JourneyActivity({
    required this.title,
    required this.statusText,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.onTap,
  });
}
