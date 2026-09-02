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
        backgroundColor: const Color(0xFF131B2B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Row(
          children: [
            Icon(LucideIcons.trash2, color: AppColors.pulseRed, size: 20),
            SizedBox(width: 10),
            Text(
              'Remove Plan?',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
            ),
          ],
        ),
        content: const Text(
          'This workout will be removed from today\'s agenda.',
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

  String _getCategoryTag(String type) {
    final lower = type.toLowerCase();
    if (lower.contains('run') || lower.contains('treadmill')) return 'CARDIO PROTOCOL';
    if (lower.contains('walk')) return 'MOBILITY & STEPS';
    if (lower.contains('cycle') || lower.contains('bike')) return 'ENDURANCE RIDE';
    if (lower.contains('swim')) return 'AQUA TRAINING';
    if (lower.contains('gym') || lower.contains('hiit')) return 'STRENGTH & POWER';
    return 'DAILY TARGET';
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
    final categoryTag = _getCategoryTag(plan.type);

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

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F1622) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Top Ambient Neon Velocity Glow
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 3,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.voltCyan,
                      const Color(0xFF00B4D8),
                      statusColor,
                    ],
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── 1. Top HUD Row: Tag + Readiness + Delete ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Protocol Tag
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: AppColors.voltCyan,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.voltCyan.withValues(alpha: 0.8),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 7),
                          Text(
                            categoryTag,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.1,
                              color: AppColors.voltCyan,
                            ),
                          ),
                        ],
                      ),

                      // Readiness & Options Menu
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: statusColor.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(LucideIcons.zap, size: 10, color: statusColor),
                                const SizedBox(width: 4),
                                Text(
                                  '${readiness.score}% READY',
                                  style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 9.5,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (onDelete != null) ...[
                            const SizedBox(width: 6),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => _confirmDelete(context),
                                child: Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.04),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    LucideIcons.x,
                                    size: 14,
                                    color: Colors.white54,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // ── 2. Hero Center: Icon/Image + Title ──
                  Row(
                    children: [
                      // Futuristic Avatar Icon Container
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.voltCyan.withValues(alpha: 0.25),
                              const Color(0xFF0077B6).withValues(alpha: 0.15),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: AppColors.voltCyan.withValues(alpha: 0.35),
                            width: 1.4,
                          ),
                        ),
                        child: plan.imageUrl.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: plan.imageUrl.startsWith('http')
                                    ? CachedNetworkImage(
                                        imageUrl: plan.imageUrl,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => Center(
                                          child: Icon(activityIcon, color: AppColors.voltCyan, size: 24),
                                        ),
                                        errorWidget: (context, url, error) => Center(
                                          child: Icon(activityIcon, color: AppColors.voltCyan, size: 24),
                                        ),
                                      )
                                    : Image.file(
                                        File(plan.imageUrl),
                                        fit: BoxFit.cover,
                                      ),
                              )
                            : Center(
                                child: Icon(activityIcon, color: AppColors.voltCyan, size: 26),
                              ),
                      ),
                      const SizedBox(width: 14),

                      // Workout Title
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              plan.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                                letterSpacing: -0.4,
                                decoration: isCompleted ? TextDecoration.lineThrough : null,
                                color: isCompleted ? (isDark ? Colors.white38 : Colors.black38) : null,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              isCompleted
                                  ? 'Workout finished for today'
                                  : 'Optimal time • ${app.currentStreak} Day Streak Active',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isDark ? Colors.white54 : Colors.black54,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // ── 3. Telemetry Glass Bar ──
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF141D2B) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildTelemetryItem(
                          icon: LucideIcons.timer,
                          value: '${plan.duration}m',
                          label: 'DURATION',
                          color: AppColors.voltCyan,
                          isDark: isDark,
                        ),
                        _buildTelemetryDivider(isDark),
                        _buildTelemetryItem(
                          icon: LucideIcons.flame,
                          value: plan.kcal.contains('kcal') ? plan.kcal.replaceAll('kcal', '').trim() : plan.kcal,
                          label: 'EST. KCAL',
                          color: AppColors.solarAmber,
                          isDark: isDark,
                        ),
                        _buildTelemetryDivider(isDark),
                        _buildTelemetryItem(
                          icon: LucideIcons.trendingUp,
                          value: '+${plan.duration}m',
                          label: 'FITNESS GOAL',
                          color: const Color(0xFF00E599),
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),

                  // ── 3.5. Smart Optimal Time Window Capsule ──
                  if (!isCompleted) ...[
                    const SizedBox(height: 12),
                    Builder(
                      builder: (context) {
                        final timeRec = WorkoutPlanSuggestionService.getOptimalTimeRecommendation(
                          plan.type,
                          currentTemp: weather?.currentTemp,
                          isRainy: weather?.condition.toLowerCase().contains('rain') ?? false,
                        );
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF131D2D) : const Color(0xFFF0F9FF),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.voltCyan.withValues(alpha: 0.25),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.voltCyan.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(timeRec.icon, size: 14, color: AppColors.voltCyan),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Text(
                                          'OPTIMAL TIME: ',
                                          style: TextStyle(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 0.5,
                                            color: AppColors.voltCyan,
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            timeRec.optimalWindow,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800,
                                              color: isDark ? Colors.white : Colors.black87,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      timeRec.quickTip,
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        color: isDark ? Colors.white70 : Colors.black87,
                                        fontWeight: FontWeight.w500,
                                        height: 1.25,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],

                  if (!isCompleted && phases.length >= 3) ...[
                    const SizedBox(height: 12),

                    // ── 4. Unified Phase Stepper Runway ──
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF121927) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
                        ),
                      ),
                      child: Row(
                        children: [
                          _buildPhaseTile(
                            context: context,
                            stepNum: '01',
                            label: 'Warm-up',
                            duration: '${phases[0].durationMinutes}m',
                            color: const Color(0xFF00E599),
                            phase: phases[0],
                            plan: plan,
                            phases: phases,
                            isActive: isActiveSession ? session.currentPhaseIndex == 0 : true,
                            isCompleted: isActiveSession && session.phaseCompleted.isNotEmpty && session.phaseCompleted[0],
                            isDark: isDark,
                          ),
                          _buildRunwayDivider(isDark),
                          _buildPhaseTile(
                            context: context,
                            stepNum: '02',
                            label: 'Workout',
                            duration: '${phases[1].durationMinutes}m',
                            color: AppColors.voltCyan,
                            phase: phases[1],
                            plan: plan,
                            phases: phases,
                            isActive: isActiveSession ? session.currentPhaseIndex == 1 : false,
                            isCompleted: isActiveSession && session.phaseCompleted.length > 1 && session.phaseCompleted[1],
                            isDark: isDark,
                          ),
                          _buildRunwayDivider(isDark),
                          _buildPhaseTile(
                            context: context,
                            stepNum: '03',
                            label: 'Cooldown',
                            duration: '${phases[2].durationMinutes}m',
                            color: const Color(0xFF00B4D8),
                            phase: phases[2],
                            plan: plan,
                            phases: phases,
                            isActive: isActiveSession ? session.currentPhaseIndex == 2 : false,
                            isCompleted: isActiveSession && session.phaseCompleted.length > 2 && session.phaseCompleted[2],
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // ── 5. Action Trigger: Hero Glow Button ──
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: isCompleted
                        ? Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF00E599).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFF00E599).withValues(alpha: 0.4),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(LucideIcons.checkCircle2, color: Color(0xFF00E599), size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'WORKOUT COMPLETED',
                                  style: TextStyle(
                                    color: Color(0xFF00E599),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.voltCyan,
                                  Color(0xFF00C49F),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.voltCyan.withValues(alpha: 0.35),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () {
                                  HapticFeedback.heavyImpact();
                                  WorkoutStartRouter.startWorkoutFromPlan(
                                    context: context,
                                    plan: plan,
                                    phases: phases,
                                  );
                                },
                                child: Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(LucideIcons.play, size: 18, color: Colors.black),
                                      const SizedBox(width: 8),
                                      Text(
                                        _getButtonText(plan.type, recommendation.adaptiveActionText).toUpperCase(),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 14,
                                          color: Colors.black,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTelemetryItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required bool isDark,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: isDark ? Colors.white38 : Colors.black38,
          ),
        ),
      ],
    );
  }

  Widget _buildTelemetryDivider(bool isDark) {
    return Container(
      width: 1,
      height: 24,
      color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08),
    );
  }

  Widget _buildPhaseTile({
    required BuildContext context,
    required String stepNum,
    required String label,
    required String duration,
    required Color color,
    required WorkoutPhase phase,
    required DailyPlan plan,
    required List<WorkoutPhase> phases,
    required bool isActive,
    required bool isCompleted,
    required bool isDark,
  }) {
    return Expanded(
      child: GestureDetector(
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
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          decoration: BoxDecoration(
            color: isActive
                ? color.withValues(alpha: 0.15)
                : (isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.03)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive
                  ? color.withValues(alpha: 0.4)
                  : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04)),
              width: isActive ? 1.2 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                stepNum,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: isActive ? color : (isDark ? Colors.white38 : Colors.black38),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                duration,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRunwayDivider(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Icon(
        LucideIcons.chevronRight,
        size: 14,
        color: isDark ? Colors.white24 : Colors.black26,
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
    } else if (lower.contains('swim')) {
      return 'Start Swim';
    }
    return 'Start Workout';
  }
}
