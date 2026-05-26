import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/weather_model.dart';
import '../providers/app_provider.dart';
import '../services/plan_readiness_service.dart';
import '../services/plan_recommendation_service.dart';
import '../theme/app_colors.dart';

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
                        if (onDelete != null)
                          GestureDetector(
                            onTap: () => _confirmDelete(context),
                            child: Padding(
                              padding: const EdgeInsets.only(left: 6, top: 2),
                              child: Icon(LucideIcons.trash2, size: 16, color: AppColors.textSecondary),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(LucideIcons.timer, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(plan.duration, style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
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
            Container(
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
                        Text(recommendation.bestTimeMessage, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        const SizedBox(height: 2),
                        Text(recommendation.reason, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
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
            Row(
              children: [
                _TimelineStep('Warm-up\n5m', isActive: true),
                _TimelineDivider(),
                _TimelineStep('${plan.type}\n${plan.duration}', isActive: false),
                _TimelineDivider(),
                _TimelineStep('Cooldown\n5m', isActive: false),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // ── Goal Impact ──
            Row(
              children: [
                const Icon(LucideIcons.trendingUp, size: 16, color: AppColors.solarAmber),
                const SizedBox(width: 6),
                Text('+${plan.duration} active', style: theme.textTheme.labelMedium?.copyWith(color: AppColors.solarAmber)),
                const SizedBox(width: 12),
                const Icon(LucideIcons.flame, size: 16, color: AppColors.solarAmber),
                const SizedBox(width: 6),
                Text('Helps streak', style: theme.textTheme.labelMedium?.copyWith(color: AppColors.solarAmber)),
              ],
            ),
          ],

          const SizedBox(height: 24),

          // ── Action Button ──
          SizedBox(
            width: double.infinity,
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
                    onPressed: onStart,
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
        ],
      ),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  final String label;
  final bool isActive;

  const _TimelineStep(this.label, {required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: isActive ? AppColors.voltCyan : AppColors.borderSubtle,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class _TimelineDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 4).copyWith(bottom: 16),
        color: AppColors.borderSubtle,
      ),
    );
  }
}
