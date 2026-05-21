import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../providers/app_provider.dart';
import '../widgets/glass_card.dart';
import '../widgets/progress_ring.dart';
import '../theme/app_colors.dart';

class FitnessScreen extends StatelessWidget {
  const FitnessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('Your Progress', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 16),
        // Horizontal scrolling stat pills
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _StatPill(icon: LucideIcons.flame, label: 'Calories', value: '${app.todayCalories}', sub: 'kcal', color: AppColors.coral),
              const SizedBox(width: 12),
              _StatPill(icon: LucideIcons.timer, label: 'Duration', value: '${app.todayDuration}', sub: 'min', color: AppColors.primary),
              const SizedBox(width: 12),
              _StatPill(icon: LucideIcons.activity, label: 'Workouts', value: '${app.todayExercises}', sub: 'done', color: AppColors.secondary),
              const SizedBox(width: 12),
              _StatPill(icon: LucideIcons.scale, label: 'Weight', value: app.bodyWeight.isNotEmpty ? '${app.bodyWeight.last}' : '0', sub: 'kg', color: AppColors.green),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text('Weekly Goal', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 12),
                      ProgressRing(size: 100, strokeWidth: 8, progress: app.weeklyCompleted / app.weeklyGoal * 100, color: AppColors.primary, label: '${app.weeklyCompleted}/${app.weeklyGoal}', sublabel: 'done', fontSize: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Body Metrics', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 16),
                      _metricRow('BMI', '${app.bmi}', theme),
                      _metricRow('Weight', app.bodyWeight.isNotEmpty ? '${app.bodyWeight.last} kg' : '-- kg', theme),
                      _metricRow('Lost', app.bodyWeight.isNotEmpty ? '-${(app.bodyWeight.first - app.bodyWeight.last).toStringAsFixed(1)} kg' : '0 kg', theme, color: AppColors.green),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Today's Workouts", style: theme.textTheme.titleMedium),
                    TextButton.icon(
                      onPressed: () => _showAddWorkout(context, app), 
                      icon: const Icon(LucideIcons.plus, size: 16), 
                      label: const Text('Add')
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (app.workouts.isEmpty)
                  Center(child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('No workouts logged today', style: theme.textTheme.bodySmall),
                  ))
                else
                  ...app.workouts.map((w) => _WorkoutTile(w: w, isDark: isDark, theme: theme)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 100),
      ],
    );
  }

  void _showAddWorkout(BuildContext context, AppProvider app) {
    showModalBottomSheet(context: context, isScrollControlled: true,
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppColors.darkSurfaceContainer : AppColors.lightSurface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _AddWorkoutSheet(app: app));
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String sub;
  final Color color;

  const _StatPill({required this.icon, required this.label, required this.value, required this.sub, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.2), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(label, style: TextStyle(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.5), fontSize: 12)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(sub, style: TextStyle(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.5), fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
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
  String type = 'Outdoor Run'; int duration = 30; int calories = 250; String intensity = 'Medium';
  @override
  Widget build(BuildContext context) {
    return Padding(padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Log Workout', style: Theme.of(context).textTheme.headlineMedium), const SizedBox(height: 20),
        DropdownButtonFormField<String>(initialValue: type, decoration: const InputDecoration(labelText: 'Type'),
          items: ['Outdoor Run', 'Treadmill', 'Cycling', 'Workout', 'HIIT', 'Swim', 'Surf', 'Snowboard', 'Football', 'Basketball', 'Dance'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(), onChanged: (v) => setState(() => type = v!)),
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
