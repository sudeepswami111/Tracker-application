import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/app_provider.dart';
import '../widgets/glass_card.dart';
import '../widgets/stat_card.dart';
import '../widgets/progress_ring.dart';
import '../theme/app_colors.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final theme = Theme.of(context);

    final statCards = [
      {'icon': LucideIcons.footprints, 'label': 'Steps', 'value': app.steps.toString(), 'unit': '', 'progress': (app.steps / app.stepsGoal * 100), 'gradient': AppColors.gradientPrimary, 'trend': 8},
      {'icon': LucideIcons.flame, 'label': 'Calories', 'value': app.calories.toString(), 'unit': 'kcal', 'progress': (app.calories / app.caloriesGoal * 100), 'gradient': AppColors.gradientCoral, 'trend': 5},
      {'icon': LucideIcons.mapPin, 'label': 'Distance', 'value': app.distance.toString(), 'unit': 'km', 'progress': (app.distance / app.distanceGoal * 100), 'gradient': AppColors.gradientBlue, 'trend': 12},
      {'icon': LucideIcons.moon, 'label': 'Sleep', 'value': app.sleepHours.toString(), 'unit': 'hrs', 'progress': (app.sleepHours / app.sleepGoal * 100), 'gradient': AppColors.gradientGreen, 'trend': -3},
      {'icon': LucideIcons.droplets, 'label': 'Water', 'value': app.waterIntake.toString(), 'unit': 'L', 'progress': (app.waterIntake / app.waterGoal * 100), 'gradient': AppColors.gradientSecondary, 'trend': 2},
      {'icon': LucideIcons.bookOpen, 'label': 'Study', 'value': app.studyHrs.toString(), 'unit': 'hrs', 'progress': (app.studyHrs / app.studyGoal * 100), 'gradient': AppColors.gradientPink, 'trend': 15},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page Header
          Text('Dashboard', style: theme.textTheme.displayLarge),
          const SizedBox(height: 4),
          Text('Your daily life at a glance', style: theme.textTheme.bodySmall),
          const SizedBox(height: 20),

          // Stats Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.35,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: statCards.length,
            itemBuilder: (_, i) {
              final c = statCards[i];
              return StatCard(
                icon: c['icon'] as IconData,
                label: c['label'] as String,
                value: c['value'] as String,
                unit: c['unit'] as String,
                progress: c['progress'] as double,
                gradient: c['gradient'] as LinearGradient,
                trend: c['trend'] as int,
              );
            },
          ),
          const SizedBox(height: 20),

          // Streaks Section
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🔥 Active Streaks', style: theme.textTheme.titleLarge),
                const SizedBox(height: 16),
                ...app.streaks.entries.map((e) {
                  final colors = {
                    'Fitness': AppColors.coral,
                    'Running': AppColors.secondary,
                    'Health': AppColors.green,
                    'Study': AppColors.primary,
                  };
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        const Text('🔥', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 10),
                        Expanded(child: Text(e.key, style: theme.textTheme.bodyMedium)),
                        Text(
                          '${e.value}',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: colors[e.key],
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text('days', style: theme.textTheme.bodySmall),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Daily Goals
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.target, size: 18, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text('Daily Goals', style: theme.textTheme.titleLarge),
                  ],
                ),
                const SizedBox(height: 16),
                ...app.dailyGoals.map((goal) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(goal['title'] as String, style: theme.textTheme.bodyMedium)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: ((goal['progress'] as int) >= 100 ? AppColors.green : AppColors.primary).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              (goal['progress'] as int) >= 100 ? '✓ Done' : '${goal['progress']}%',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: (goal['progress'] as int) >= 100 ? AppColors.green : AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: ((goal['progress'] as int) / 100).clamp(0.0, 1.0),
                          minHeight: 5,
                          backgroundColor: theme.brightness == Brightness.dark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.black.withValues(alpha: 0.06),
                          valueColor: AlwaysStoppedAnimation(
                            (goal['progress'] as int) >= 100 ? AppColors.green : AppColors.primaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // AI Insights
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.sparkles, size: 18, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text('AI Insights', style: theme.textTheme.titleLarge),
                  ],
                ),
                const SizedBox(height: 16),
                ...app.insights.map((insight) {
                  final icons = {'positive': '✨', 'suggestion': '💡', 'warning': '⚠️'};
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(icons[insight['type']] ?? '💡', style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 10),
                        Expanded(child: Text(insight['message']!, style: theme.textTheme.bodySmall?.copyWith(height: 1.5))),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Achievements
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.trophy, size: 18, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text('Achievements', style: theme.textTheme.titleLarge),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: app.achievements.map((badge) {
                    final unlocked = badge['unlocked'] as bool;
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: unlocked
                                ? AppColors.primary.withValues(alpha: 0.15)
                                : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(16),
                            border: unlocked
                                ? Border.all(color: AppColors.primary.withValues(alpha: 0.3))
                                : null,
                          ),
                          child: Center(
                            child: Opacity(
                              opacity: unlocked ? 1 : 0.4,
                              child: Text(badge['icon'] as String, style: const TextStyle(fontSize: 24)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: 64,
                          child: Text(
                            badge['title'] as String,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.labelSmall?.copyWith(fontSize: 9),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Overall Progress Rings
          GlassCard(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ProgressRing(size: 80, strokeWidth: 8, progress: app.steps / app.stepsGoal * 100, color: AppColors.primary, label: '${(app.steps / app.stepsGoal * 100).round()}%', sublabel: 'Steps', fontSize: 14),
                ProgressRing(size: 80, strokeWidth: 8, progress: app.calories / app.caloriesGoal * 100, color: AppColors.coral, label: '${(app.calories / app.caloriesGoal * 100).round()}%', sublabel: 'Cal', fontSize: 14),
                ProgressRing(size: 80, strokeWidth: 8, progress: app.sleepHours / app.sleepGoal * 100, color: AppColors.green, label: '${(app.sleepHours / app.sleepGoal * 100).round()}%', sublabel: 'Sleep', fontSize: 14),
                ProgressRing(size: 80, strokeWidth: 8, progress: app.waterIntake / app.waterGoal * 100, color: AppColors.secondary, label: '${(app.waterIntake / app.waterGoal * 100).round()}%', sublabel: 'Water', fontSize: 14),
              ],
            ),
          ),
          const SizedBox(height: 100), // Bottom nav clearance
        ],
      ),
    );
  }
}
