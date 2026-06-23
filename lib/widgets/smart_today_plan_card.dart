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
import '../screens/running_screen.dart';
import '../screens/guided_workout_session_screen.dart';

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

                return Row(
                  children: [
                    _TimelineStep(
                      phase: phases[0],
                      isActive: true,
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          isScrollControlled: true,
                          builder: (_) => WorkoutPhaseDetailsSheet(
                            phase: phases[0],
                            onStartWorkout: () => _startWorkoutFlow(context, phases),
                          ),
                        );
                      },
                    ),
                    _TimelineDivider(isActive: false),
                    _TimelineStep(
                      phase: phases[1],
                      isActive: false,
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          isScrollControlled: true,
                          builder: (_) => WorkoutPhaseDetailsSheet(
                            phase: phases[1],
                            onStartWorkout: () => _startWorkoutFlow(context, phases),
                          ),
                        );
                      },
                    ),
                    _TimelineDivider(isActive: false),
                    _TimelineStep(
                      phase: phases[2],
                      isActive: false,
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          isScrollControlled: true,
                          builder: (_) => WorkoutPhaseDetailsSheet(
                            phase: phases[2],
                            onStartWorkout: () => _startWorkoutFlow(context, phases),
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
                            _startWorkoutFlow(context, phases);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: statusColor == AppColors.pulseRed ? AppColors.pulseRed : AppColors.voltCyan,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Text(
                            recommendation.adaptiveActionText,
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

  void _startWorkoutFlow(BuildContext context, List<WorkoutPhase> phases) {
    final lowerType = plan.type.toLowerCase();
    final isGps = lowerType.contains('run') ||
        lowerType.contains('walk') ||
        lowerType.contains('cycle') ||
        lowerType.contains('bike');

    if (isGps) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RunningScreen(
            phases: phases,
            plan: plan,
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GuidedWorkoutSessionScreen(
            plan: plan,
            phases: phases,
          ),
        ),
      );
    }
  }
}

class _TimelineStep extends StatelessWidget {
  final WorkoutPhase phase;
  final bool isActive;
  final VoidCallback onTap;

  const _TimelineStep({
    required this.phase,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                  color: isActive ? AppColors.voltCyan : AppColors.borderSubtle,
                  width: 1.5,
                ),
              ),
              child: Icon(
                phase.icon,
                size: 16,
                color: isActive ? AppColors.voltCyan : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              phase.title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${phase.durationMinutes}m',
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                color: isActive ? AppColors.voltCyan : AppColors.textSecondary,
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
  final bool isActive;
  const _TimelineDivider({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 22.0),
        child: Container(
          height: 1.5,
          color: isActive ? AppColors.voltCyan : AppColors.borderSubtle,
        ),
      ),
    );
  }
}
