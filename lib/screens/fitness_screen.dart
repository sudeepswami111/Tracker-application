import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/app_provider.dart';
import '../widgets/glass_card.dart';
import '../widgets/stat_card.dart';
import '../widgets/progress_ring.dart';
import '../theme/app_colors.dart';

class FitnessScreen extends StatelessWidget {
  const FitnessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Fitness Tracker', style: theme.textTheme.displayLarge),
          const SizedBox(height: 4),
          Text('Track your workouts and body metrics', style: theme.textTheme.bodySmall),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = (constraints.maxWidth - 12) / 2;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(width: cardWidth, child: StatCard(icon: LucideIcons.flame, label: 'Calories', value: '${app.todayCalories}', unit: 'kcal', progress: app.todayCalories / 3000 * 100, gradient: AppColors.gradientCoral, trend: 5)),
                  SizedBox(width: cardWidth, child: StatCard(icon: LucideIcons.clock, label: 'Duration', value: '${app.todayDuration}', unit: 'min', progress: app.todayDuration / 90 * 100, gradient: AppColors.gradientPrimary, trend: 12)),
                  SizedBox(width: cardWidth, child: StatCard(icon: LucideIcons.dumbbell, label: 'Exercises', value: '${app.todayExercises}', unit: 'done', progress: app.todayExercises / 6 * 100, gradient: AppColors.gradientSecondary)),
                  SizedBox(width: cardWidth, child: StatCard(icon: LucideIcons.trendingDown, label: 'Weight', value: app.bodyWeight.isNotEmpty ? '${app.bodyWeight.last}' : '0', unit: 'kg', progress: 100, gradient: AppColors.gradientGreen, trend: -2)),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          GlassCard(child: Column(children: [
            Text('Weekly Goal', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            ProgressRing(size: 160, strokeWidth: 12, progress: app.weeklyCompleted / app.weeklyGoal * 100, color: AppColors.primary, label: '${app.weeklyCompleted}/${app.weeklyGoal}', sublabel: 'workouts', fontSize: 24),
            const SizedBox(height: 12),
            Text('${app.weeklyGoal - app.weeklyCompleted} more to hit your goal!', style: theme.textTheme.bodySmall),
          ])),
          const SizedBox(height: 16),
          GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text("Today's Workouts", style: theme.textTheme.titleLarge),
              ElevatedButton.icon(onPressed: () => _showAddWorkout(context, app), icon: const Icon(LucideIcons.plus, size: 16), label: const Text('Log')),
            ]),
            const SizedBox(height: 12),
            ...app.workouts.map((w) => _WorkoutTile(w: w, isDark: isDark, theme: theme)),
          ])),
          const SizedBox(height: 16),
          GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Body Metrics', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            _metricRow('Current Weight', app.bodyWeight.isNotEmpty ? '${app.bodyWeight.last} kg' : '-- kg', theme),
            _metricRow('BMI', '${app.bmi}', theme),
            _metricRow('Weight Lost', app.bodyWeight.isNotEmpty ? '-${(app.bodyWeight.first - app.bodyWeight.last).toStringAsFixed(1)} kg' : '0 kg', theme, color: AppColors.green),
          ])),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  void _showAddWorkout(BuildContext context, AppProvider app) {
    showModalBottomSheet(context: context, isScrollControlled: true,
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppColors.darkSurfaceContainer : AppColors.lightSurface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _AddWorkoutSheet(app: app));
  }
}

class _WorkoutTile extends StatelessWidget {
  final Map<String, dynamic> w;
  final bool isDark;
  final ThemeData theme;
  const _WorkoutTile({required this.w, required this.isDark, required this.theme});

  @override
  Widget build(BuildContext context) {
    final intensityColor = w['intensity'] == 'High' ? AppColors.coral : w['intensity'] == 'Medium' ? AppColors.primary : AppColors.green;
    return Container(
      margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02), borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        Container(width: 44, height: 44, decoration: BoxDecoration(gradient: w['intensity'] == 'High' ? AppColors.gradientCoral : w['intensity'] == 'Medium' ? AppColors.gradientPrimary : AppColors.gradientGreen, borderRadius: BorderRadius.circular(12)),
          child: Icon(w['icon'] as IconData, size: 20, color: Colors.white)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(w['type'] as String, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          Text(w['time'] as String, style: theme.textTheme.bodySmall?.copyWith(fontSize: 11)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${w['duration']} min', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          Text('${w['calories']} kcal', style: theme.textTheme.bodySmall?.copyWith(fontSize: 11, color: AppColors.coral)),
        ]),
        const SizedBox(width: 8),
        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: intensityColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
          child: Text(w['intensity'] as String, style: theme.textTheme.labelSmall?.copyWith(color: intensityColor, fontWeight: FontWeight.w700))),
      ]),
    );
  }
}

Widget _metricRow(String label, String value, ThemeData theme, {Color? color}) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
  Text(label, style: theme.textTheme.bodySmall), Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700, color: color))]));

class _AddWorkoutSheet extends StatefulWidget {
  final AppProvider app;
  const _AddWorkoutSheet({required this.app});
  @override State<_AddWorkoutSheet> createState() => _AddWorkoutSheetState();
}

class _AddWorkoutSheetState extends State<_AddWorkoutSheet> {
  String type = 'Running'; int duration = 30; int calories = 250; String intensity = 'Medium';
  @override
  Widget build(BuildContext context) {
    return Padding(padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Log Workout', style: Theme.of(context).textTheme.headlineMedium), const SizedBox(height: 20),
        DropdownButtonFormField<String>(initialValue: type, decoration: const InputDecoration(labelText: 'Type'),
          items: ['Running', 'Weight Training', 'Yoga', 'Cycling', 'HIIT'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(), onChanged: (v) => setState(() => type = v!)),
        const SizedBox(height: 12),
        TextFormField(initialValue: '$duration', decoration: const InputDecoration(labelText: 'Duration (min)'), keyboardType: TextInputType.number, onChanged: (v) => duration = int.tryParse(v) ?? 30),
        const SizedBox(height: 12),
        TextFormField(initialValue: '$calories', decoration: const InputDecoration(labelText: 'Calories'), keyboardType: TextInputType.number, onChanged: (v) => calories = int.tryParse(v) ?? 250),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(initialValue: intensity, decoration: const InputDecoration(labelText: 'Intensity'),
          items: ['Low', 'Medium', 'High'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(), onChanged: (v) => setState(() => intensity = v!)),
        const SizedBox(height: 20),
        SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: () {
          widget.app.addWorkout({'id': DateTime.now().millisecondsSinceEpoch, 'type': type, 'duration': duration, 'calories': calories, 'intensity': intensity, 'time': TimeOfDay.now().format(context), 'icon': Icons.fitness_center});
          Navigator.pop(context);
        }, icon: const Icon(LucideIcons.plus, size: 16), label: const Text('Add Workout'))),
      ]));
  }
}
