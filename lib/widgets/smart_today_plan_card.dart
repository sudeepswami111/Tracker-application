import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../models/weather_model.dart';
import '../models/workout_phase.dart';
import '../providers/app_provider.dart';
import '../providers/workout_session_provider.dart';
import '../services/plan_readiness_service.dart';
import '../services/plan_recommendation_service.dart';
import '../services/workout_suggestion_service.dart';
import '../services/workout_start_router.dart';
import '../theme/app_colors.dart';
import 'workout_phase_details_sheet.dart';

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
    HapticFeedback.selectionClick();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141D2B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Remove this plan?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
        ),
        content: const Text(
          'This will remove this workout from your daily agenda.',
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onDelete?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.pulseRed.withValues(alpha: 0.2),
              foregroundColor: AppColors.pulseRed,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Remove', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  IconData _getActivityIcon(String type) {
    final lower = type.toLowerCase();
    if (lower.contains('run') || lower.contains('treadmill')) return LucideIcons.footprints;
    if (lower.contains('walk')) return LucideIcons.footprints;
    if (lower.contains('cycle') || lower.contains('bike')) return LucideIcons.bike;
    if (lower.contains('swim')) return LucideIcons.waves;
    if (lower.contains('hiit') || lower.contains('strength') || lower.contains('gym')) return LucideIcons.dumbbell;
    if (lower.contains('yoga') || lower.contains('stretch')) return LucideIcons.sparkles;
    return LucideIcons.activity;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isCompleted = plan.isCompleted;

    final readiness = PlanReadinessService.calculateReadiness(
      weather: weather,
      currentStreak: app.currentStreak,
      currentSteps: app.steps > 0 ? app.steps : 4500,
    );

    final recommendation = PlanRecommendationService.getRecommendation(
      weather: weather,
      readiness: readiness,
    );

    Color getStatusColor() {
      switch (readiness.status) {
        case ReadinessStatus.ready:
          return AppColors.voltCyan;
        case ReadinessStatus.good:
          return const Color(0xFF00E599);
        case ReadinessStatus.caution:
          return AppColors.solarAmber;
        case ReadinessStatus.notIdeal:
          return AppColors.pulseRed;
      }
    }

    final statusColor = getStatusColor();
    final durationInt = int.tryParse(plan.duration) ?? 30;
    final activityIcon = _getActivityIcon(plan.type);

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

    final isIndoor = plan.type.toLowerCase().contains('treadmill') ||
        plan.type.toLowerCase().contains('gym') ||
        plan.type.toLowerCase().contains('hiit') ||
        plan.type.toLowerCase().contains('indoor');

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF101724) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: Thumbnail / Icon + Title + Readiness ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Workout Thumbnail or Icon
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.voltCyan.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.voltCyan.withValues(alpha: 0.25),
                        width: 1.2,
                      ),
                    ),
                    child: plan.imageUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: plan.imageUrl.startsWith('http')
                                ? CachedNetworkImage(
                                    imageUrl: plan.imageUrl,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(color: Colors.black12),
                                    errorWidget: (context, url, error) => Center(
                                      child: Icon(activityIcon, color: AppColors.voltCyan, size: 22),
                                    ),
                                  )
                                : Image.file(
                                    File(plan.imageUrl),
                                    fit: BoxFit.cover,
                                  ),
                          )
                        : Center(
                            child: Icon(activityIcon, color: AppColors.voltCyan, size: 24),
                          ),
                  ),
                ],
              ),
              const SizedBox(width: 12),

              // Title & Quick Specs
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        letterSpacing: -0.2,
                        decoration: isCompleted ? TextDecoration.lineThrough : null,
                        color: isCompleted ? (isDark ? Colors.white38 : Colors.black38) : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        _buildPillBadge(
                          icon: LucideIcons.timer,
                          text: '${plan.duration}m',
                          color: AppColors.voltCyan,
                          isDark: isDark,
                        ),
                        const SizedBox(width: 6),
                        _buildPillBadge(
                          icon: LucideIcons.flame,
                          text: plan.kcal.contains('kcal') ? plan.kcal : '${plan.kcal} kcal',
                          color: AppColors.solarAmber,
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Readiness Indicator Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.activity, size: 12, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      '${readiness.score} ${readiness.label}',
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (!isCompleted) ...[
            const SizedBox(height: 14),

            // ── AI Coach Smart Window Banner ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF141D2B) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isIndoor ? LucideIcons.home : LucideIcons.sparkles,
                    size: 14,
                    color: AppColors.voltCyan,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isIndoor
                          ? 'Indoor Workout • Optimal 100% Controlled Conditions'
                          : 'Ideal Window: Morning or Evening • Stay Hydrated',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ── Interactive 3-Phase Athletic Timeline ──
            if (phases.length >= 3)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildPhaseItem(
                        context: context,
                        phase: phases[0],
                        label: 'Warm-up',
                        duration: '${phases[0].durationMinutes}m',
                        icon: LucideIcons.sparkles,
                        color: const Color(0xFF00E599),
                        isActive: isActiveSession ? session.currentPhaseIndex == 0 : true,
                        isCompleted: isActiveSession && session.phaseCompleted.isNotEmpty && session.phaseCompleted[0],
                        plan: plan,
                        phases: phases,
                        isDark: isDark,
                      ),
                    ),
                    _buildPhaseConnector(isDark),
                    Expanded(
                      child: _buildPhaseItem(
                        context: context,
                        phase: phases[1],
                        label: plan.type.length > 10 ? 'Main' : plan.type,
                        duration: '${phases[1].durationMinutes}m',
                        icon: activityIcon,
                        color: AppColors.voltCyan,
                        isActive: isActiveSession ? session.currentPhaseIndex == 1 : false,
                        isCompleted: isActiveSession && session.phaseCompleted.length > 1 && session.phaseCompleted[1],
                        plan: plan,
                        phases: phases,
                        isDark: isDark,
                      ),
                    ),
                    _buildPhaseConnector(isDark),
                    Expanded(
                      child: _buildPhaseItem(
                        context: context,
                        phase: phases[2],
                        label: 'Cooldown',
                        duration: '${phases[2].durationMinutes}m',
                        icon: LucideIcons.droplets,
                        color: const Color(0xFF00B4D8),
                        isActive: isActiveSession ? session.currentPhaseIndex == 2 : false,
                        isCompleted: isActiveSession && session.phaseCompleted.length > 2 && session.phaseCompleted[2],
                        plan: plan,
                        phases: phases,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 14),

            // ── Goal Impact Subtext ──
            Row(
              children: [
                const Icon(LucideIcons.trendingUp, size: 13, color: AppColors.solarAmber),
                const SizedBox(width: 4),
                Text(
                  '+${plan.duration}m active time',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.solarAmber,
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(LucideIcons.flame, size: 13, color: AppColors.solarAmber),
                const SizedBox(width: 4),
                Text(
                  'Extends ${app.currentStreak}-day streak',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.solarAmber,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 16),

          // ── Action Buttons ──
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: isCompleted
                      ? Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF00E599).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0xFF00E599).withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(LucideIcons.checkCircle2, color: Color(0xFF00E599), size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Completed Today',
                                style: TextStyle(
                                  color: Color(0xFF00E599),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ElevatedButton.icon(
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            WorkoutStartRouter.startWorkoutFromPlan(
                              context: context,
                              plan: plan,
                              phases: phases,
                            );
                          },
                          icon: const Icon(LucideIcons.play, size: 16, color: Colors.black),
                          label: Text(
                            _getButtonText(plan.type, recommendation.adaptiveActionText),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: Colors.black,
                              letterSpacing: 0.2,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.voltCyan,
                            foregroundColor: Colors.black,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                ),
              ),
              if (onDelete != null) ...[
                const SizedBox(width: 10),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => _confirmDelete(context),
                    child: Container(
                      height: 46,
                      width: 46,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
                        ),
                      ),
                      child: const Icon(
                        LucideIcons.trash2,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
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

  Widget _buildPillBadge({
    required IconData icon,
    required String text,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseItem({
    required BuildContext context,
    required WorkoutPhase phase,
    required String label,
    required String duration,
    required IconData icon,
    required Color color,
    required bool isActive,
    required bool isCompleted,
    required DailyPlan plan,
    required List<WorkoutPhase> phases,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (_) => WorkoutPhaseDetailsSheet(
            phase: phase,
            onStartWorkout: () => WorkoutStartRouter.startWorkoutFromPlan(
              context: context,
              plan: plan,
              phases: phases,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: isActive
              ? color.withValues(alpha: 0.12)
              : (isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.03)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive
                ? color.withValues(alpha: 0.35)
                : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04)),
            width: isActive ? 1.2 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isCompleted ? const Color(0xFF00E599) : color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isCompleted ? LucideIcons.check : icon,
                size: 13,
                color: isCompleted ? Colors.black : color,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              duration,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhaseConnector(bool isDark) {
    return Container(
      width: 12,
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      color: isDark ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.15),
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
    } else if (lower.contains('swim')) {
      return 'Start Swim';
    } else if (lower.contains('gym') || lower.contains('strength') || lower.contains('workout') || lower.contains('hiit')) {
      return 'Start Workout';
    }
    return 'Start Workout';
  }
}
