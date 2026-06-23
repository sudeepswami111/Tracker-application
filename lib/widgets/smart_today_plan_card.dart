import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/weather_model.dart';
import '../providers/app_provider.dart';
import '../services/plan_readiness_service.dart';
import '../services/plan_recommendation_service.dart';
import '../theme/app_colors.dart';
import '../models/workout_phase.dart';
import '../services/workout_suggestion_service.dart';
import 'workout_phase_details_sheet.dart';
import '../services/workout_start_router.dart';
import 'package:provider/provider.dart';
import '../providers/workout_session_provider.dart';

class SmartTodayPlanCard extends StatelessWidget {
  final DailyPlan plan;
  final WeatherModel? weather;
  final AppProvider app;
  final VoidCallback onStart;
  final VoidCallback? onDelete;

  const SmartTodayPlanCard({
    super.key,
    required this.plan,
    required this.weather,
    required this.app,
    required this.onStart,
    this.onDelete,
  });

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Remove this plan?',
            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        content: const Text('This will delete the plan from your list.',
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onDelete?.call();
            },
            child: const Text('Remove', style: TextStyle(color: AppColors.pulseRed, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final readiness = PlanReadinessService.calculateReadiness(
      weather: weather,
      currentStreak: app.currentStreak,
      currentSteps: 4500, // Dummy step data until health kit sync is added
    );

    final recommendation = PlanRecommendationService.getRecommendation(
      weather: weather,
      readiness: readiness,
    );

    Color getStatusColor() {
      switch (readiness.status) {
        case ReadinessStatus.ready: return AppColors.teal;
        case ReadinessStatus.good: return AppColors.green;
        case ReadinessStatus.caution: return AppColors.solarAmber;
        case ReadinessStatus.notIdeal: return AppColors.pulseRed;
      }
    }

    final isCompleted = plan.isCompleted;
    final statusColor = getStatusColor();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (plan.imageUrl.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    width: 60,
                    height: 60,
                    child: plan.imageUrl.startsWith('http')
                        ? CachedNetworkImage(
                            imageUrl: plan.imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(color: AppColors.surfaceElevated),
                            errorWidget: (context, url, error) => Container(color: AppColors.surfaceElevated),
                          )
                        : Image.file(
                            File(plan.imageUrl),
                            fit: BoxFit.cover,
                          ),
                  ),
                ),
                const SizedBox(width: 14),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            plan.title,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                              decoration: isCompleted ? TextDecoration.lineThrough : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(LucideIcons.timer, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text('${plan.duration}m', style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
                        const SizedBox(width: 12),
                        const Icon(LucideIcons.zap, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(plan.kcal, style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                  ],
                ),
              ),
              // Readiness Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.activity, size: 14, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      '${readiness.score} ${readiness.label}',
                      style: theme.textTheme.labelSmall?.copyWith(color: statusColor, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          if (!isCompleted) ...[
            const SizedBox(height: 20),
            
            // ── Smart Context ──
            Builder(
              builder: (context) {
                final suggestion = WorkoutPlanSuggestionService.getSuggestion(plan.type);
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.info, size: 18, color: AppColors.voltCyan),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(suggestion.title, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                            const SizedBox(height: 2),
                            Text(suggestion.body, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }
            ),

            // ── One-Tap Alternatives ──
            if (recommendation.alternativeWorkouts.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Alternatives', style: theme.textTheme.labelMedium?.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: recommendation.alternativeWorkouts.map((alt) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.borderSubtle),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(alt, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textPrimary)),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 20),

            // ── Workout Timeline ──
            Builder(
              builder: (context) {
                final durationInt = int.tryParse(plan.duration) ?? 30;
                String? weatherStatus;
                if (weather != null) {
                  if (weather!.currentTemp > 30) {
                    weatherStatus = 'hot';
                  } else if (weather!.condition.toLowerCase().contains('rain')) {
                    weatherStatus = 'rainy';
                  }
                }

                final phases = WorkoutPlanSuggestionService.generatePhases(
                  activityType: plan.type,
                  totalDurationMinutes: durationInt,
                  weatherStatus: weatherStatus,
                );

                final session = context.watch<WorkoutSessionProvider>();
                final isActiveSession = session.activePlanId == plan.id;

                final p0Active = isActiveSession ? session.currentPhaseIndex == 0 : true;
                final p0Completed = isActiveSession && session.phaseCompleted.isNotEmpty && session.phaseCompleted[0];

                final p1Active = isActiveSession ? session.currentPhaseIndex == 1 : false;
                final p1Completed = isActiveSession && session.phaseCompleted.length > 1 && session.phaseCompleted[1];

                final p2Active = isActiveSession ? session.currentPhaseIndex == 2 : false;
                final p2Completed = isActiveSession && session.phaseCompleted.length > 2 && session.phaseCompleted[2];

                return Row(
                  children: [
                    _TimelineStep(
                      phase: phases[0],
                      isActive: p0Active,
                      isCompleted: p0Completed,
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          isScrollControlled: true,
                          builder: (_) => WorkoutPhaseDetailsSheet(
                            phase: phases[0],
                            onStartWorkout: () => WorkoutStartRouter.startWorkoutFromPlan(
                              context: context,
                              plan: plan,
                              phases: phases,
                            ),
                          ),
                        );
                      },
                    ),
                    _TimelineDivider(isCompleted: p0Completed),
                    _TimelineStep(
                      phase: phases[1],
                      isActive: p1Active,
                      isCompleted: p1Completed,
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          isScrollControlled: true,
                          builder: (_) => WorkoutPhaseDetailsSheet(
                            phase: phases[1],
                            onStartWorkout: () => WorkoutStartRouter.startWorkoutFromPlan(
                              context: context,
                              plan: plan,
                              phases: phases,
                            ),
                          ),
                        );
                      },
                    ),
                    _TimelineDivider(isCompleted: p1Completed),
                    _TimelineStep(
                      phase: phases[2],
                      isActive: p2Active,
                      isCompleted: p2Completed,
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          isScrollControlled: true,
                          builder: (_) => WorkoutPhaseDetailsSheet(
                            phase: phases[2],
                            onStartWorkout: () => WorkoutStartRouter.startWorkoutFromPlan(
                              context: context,
                              plan: plan,
                              phases: phases,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
            
            const SizedBox(height: 20),
            
            // ── Goal Impact ──
            Row(
              children: [
                const Icon(LucideIcons.trendingUp, size: 16, color: AppColors.solarAmber),
                const SizedBox(width: 6),
                Text('+${plan.duration}m active', style: theme.textTheme.labelMedium?.copyWith(color: AppColors.solarAmber)),
                const SizedBox(width: 12),
                const Icon(LucideIcons.flame, size: 16, color: AppColors.solarAmber),
                const SizedBox(width: 6),
                Text('Helps streak', style: theme.textTheme.labelMedium?.copyWith(color: AppColors.solarAmber)),
              ],
            ),
          ],

          const SizedBox(height: 24),

          // ── Action Buttons ──
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: isCompleted
                      ? Container(
                          decoration: BoxDecoration(
                            color: AppColors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.green.withValues(alpha: 0.5)),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(LucideIcons.checkCircle2, color: AppColors.green),
                              SizedBox(width: 8),
                              Text('Completed', style: TextStyle(color: AppColors.green, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        )
                      : ElevatedButton(
                          onPressed: () {
                            final durationInt = int.tryParse(plan.duration) ?? 30;
                            String? weatherStatus;
                            if (weather != null) {
                              if (weather!.currentTemp > 30) {
                                weatherStatus = 'hot';
                              } else if (weather!.condition.toLowerCase().contains('rain')) {
                                weatherStatus = 'rainy';
                              }
                            }
                            final phases = WorkoutPlanSuggestionService.generatePhases(
                              activityType: plan.type,
                              totalDurationMinutes: durationInt,
                              weatherStatus: weatherStatus,
                            );
                            WorkoutStartRouter.startWorkoutFromPlan(
                              context: context,
                              plan: plan,
                              phases: phases,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: statusColor == AppColors.pulseRed ? AppColors.pulseRed : AppColors.voltCyan,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Text(
                            _getButtonText(plan.type, recommendation.adaptiveActionText),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                ),
              ),
              if (onDelete != null) ...[
                const SizedBox(width: 12),
                SizedBox(
                  height: 48,
                  width: 48,
                  child: IconButton(
                    onPressed: () => _confirmDelete(context),
                    icon: const Icon(LucideIcons.trash2, size: 20, color: AppColors.textSecondary),
                    style: IconButton.styleFrom(
                      backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _getButtonText(String type, String defaultActionText) {
    if (defaultActionText == 'Switch to Indoor') {
      return defaultActionText;
    }
    final lower = type.toLowerCase().trim();
    if (lower.contains('run') || lower == 'outdoor run' || lower == 'trail run' || lower == 'treadmill') {
      return 'Start Run';
    } else if (lower.contains('walk') || lower == 'outdoor walk') {
      return 'Start Walk';
    } else if (lower.contains('cycling') || lower.contains('cycle') || lower.contains('bike')) {
      return 'Start Ride';
    } else if (lower.contains('yoga')) {
      return 'Start Yoga';
    } else if (lower.contains('study') || lower.contains('focus') || lower.contains('deep work')) {
      return 'Start Focus';
    } else if (lower.contains('meditat')) {
      return 'Start Session';
    } else if (lower.contains('strength') || lower.contains('gym') || lower.contains('swim') || lower.contains('hiit') || lower.contains('stretch') || lower.contains('rest') || lower.contains('recovery')) {
      return 'Start Session';
    }
    return 'Start Workout';
  }
}

class _TimelineStep extends StatelessWidget {
  final WorkoutPhase phase;
  final bool isActive;
  final bool isCompleted;
  final VoidCallback onTap;

  const _TimelineStep({
    required this.phase,
    required this.isActive,
    required this.isCompleted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color ringColor;
    Color iconColor;
    IconData iconData;
    FontWeight fontWeight;
    Color textColor;

    if (isCompleted) {
      ringColor = AppColors.teal;
      iconColor = AppColors.teal;
      iconData = LucideIcons.check;
      fontWeight = FontWeight.normal;
      textColor = AppColors.textSecondary;
    } else if (isActive) {
      ringColor = AppColors.voltCyan;
      iconColor = AppColors.voltCyan;
      iconData = phase.icon;
      fontWeight = FontWeight.bold;
      textColor = AppColors.textPrimary;
    } else {
      ringColor = AppColors.borderSubtle;
      iconColor = AppColors.textSecondary.withValues(alpha: 0.5);
      iconData = phase.icon;
      fontWeight = FontWeight.normal;
      textColor = AppColors.textSecondary.withValues(alpha: 0.5);
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 75,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isActive ? AppColors.voltCyan.withValues(alpha: 0.2) : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: ringColor,
                  width: isActive ? 2.0 : 1.5,
                ),
              ),
              child: Icon(
                iconData,
                size: 16,
                color: iconColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              phase.shortTitle,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: textColor,
                fontSize: 10,
                fontWeight: fontWeight,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${phase.durationMinutes}m',
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                color: isCompleted
                    ? AppColors.teal.withValues(alpha: 0.7)
                    : (isActive ? AppColors.voltCyan : AppColors.textSecondary.withValues(alpha: 0.5)),
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineDivider extends StatelessWidget {
  final bool isCompleted;
  const _TimelineDivider({required this.isCompleted});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 22.0),
        child: Container(
          height: 1.5,
          color: isCompleted
              ? AppColors.teal.withValues(alpha: 0.8)
              : AppColors.borderSubtle.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}
