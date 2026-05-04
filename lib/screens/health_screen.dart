import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/app_provider.dart';
import '../widgets/glass_card.dart';
import '../widgets/progress_ring.dart';
import '../theme/app_colors.dart';

class HealthScreen extends StatelessWidget {
  const HealthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Health Monitor', style: theme.textTheme.displayLarge),
      const SizedBox(height: 4),
      Text('Track your vitals and wellness metrics', style: theme.textTheme.bodySmall),
      const SizedBox(height: 20),

      // Heart Rate
      GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [Icon(LucideIcons.heart, size: 18, color: AppColors.coral), const SizedBox(width: 8), Text('Heart Rate', style: theme.textTheme.titleLarge)]),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: AppColors.coral.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
            child: Text('LIVE', style: theme.textTheme.labelSmall?.copyWith(color: AppColors.coral, fontWeight: FontWeight.w700))),
        ]),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Icon(LucideIcons.heart, size: 28, color: AppColors.coral),
            const SizedBox(width: 8),
            Text('${app.heartRate}', style: theme.textTheme.displayLarge?.copyWith(fontSize: 48)),
            const SizedBox(width: 4),
            Padding(padding: const EdgeInsets.only(bottom: 8), child: Text('BPM', style: theme.textTheme.bodySmall)),
          ]),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('Resting ${app.restingHR}', style: theme.textTheme.bodySmall),
            Text('Max ${app.maxHR}', style: theme.textTheme.bodySmall),
          ]),
        ]),
        const SizedBox(height: 16),
        _zoneBar('Rest', '14h', AppColors.blue, 14 / 24, theme),
        _zoneBar('Fat Burn', '6h', AppColors.green, 6 / 24, theme),
        _zoneBar('Cardio', '3h', AppColors.yellow, 3 / 24, theme),
        _zoneBar('Peak', '1h', AppColors.coral, 1 / 24, theme),
      ])),
      const SizedBox(height: 16),

      // Sleep
      GlassCard(child: Column(children: [
        Row(children: [Icon(LucideIcons.moon, size: 18, color: AppColors.blue), const SizedBox(width: 8), Text('Sleep', style: theme.textTheme.titleLarge)]),
        const SizedBox(height: 16),
        ProgressRing(size: 140, strokeWidth: 12, progress: app.sleepQuality, color: AppColors.blue, label: '${app.sleepHours}h', sublabel: '${app.sleepQuality.toInt()}% quality', fontSize: 24),
        const SizedBox(height: 16),
        GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), childAspectRatio: 3.5, crossAxisSpacing: 8, mainAxisSpacing: 8, children: [
          _sleepStage('Deep', '${app.sleepDeep}h', AppColors.primary, theme, isDark),
          _sleepStage('Light', '${app.sleepLight}h', AppColors.blue, theme, isDark),
          _sleepStage('REM', '${app.sleepREM}h', AppColors.pink, theme, isDark),
          _sleepStage('Awake', '${app.sleepAwake}h', AppColors.darkOnSurfaceVariant, theme, isDark),
        ]),
        const SizedBox(height: 12),
        SizedBox(height: 60, child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: List.generate(7, (i) {
          final h = app.sleepWeekly[i]; final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
          return Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 3), child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
            Expanded(child: FractionallySizedBox(heightFactor: (h / 10).clamp(0, 1), alignment: Alignment.bottomCenter,
              child: Container(decoration: BoxDecoration(color: h >= 7 ? AppColors.blue : AppColors.coral, borderRadius: BorderRadius.circular(4))))),
            const SizedBox(height: 4), Text(days[i], style: theme.textTheme.labelSmall?.copyWith(fontSize: 9)),
          ])));
        }))),
      ])),
      const SizedBox(height: 16),

      // Water
      GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [Icon(LucideIcons.droplets, size: 18, color: AppColors.secondary), const SizedBox(width: 8), Text('Water Intake', style: theme.textTheme.titleLarge)]),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
            child: Text('${app.waterGlasses}/${app.waterGlassGoal}', style: theme.textTheme.labelSmall?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700))),
        ]),
        const SizedBox(height: 16),
        Center(child: Wrap(spacing: 8, runSpacing: 8, children: List.generate(app.waterGlassGoal, (i) => Container(width: 36, height: 36,
          decoration: BoxDecoration(color: i < app.waterGlasses ? AppColors.secondary.withValues(alpha: 0.15) : Colors.transparent, borderRadius: BorderRadius.circular(10),
            border: Border.all(color: i < app.waterGlasses ? AppColors.secondary : theme.colorScheme.outline.withValues(alpha: 0.2))),
          child: Icon(LucideIcons.droplets, size: 16, color: i < app.waterGlasses ? AppColors.secondary : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3)))))),
        const SizedBox(height: 12),
        Center(child: ElevatedButton.icon(onPressed: app.addWater, icon: const Icon(LucideIcons.plus, size: 16), label: const Text('Add Glass'))),
      ])),
      const SizedBox(height: 16),

      // Wellness
      GlassCard(child: Column(children: [
        Row(children: [Icon(LucideIcons.activity, size: 18, color: AppColors.green), const SizedBox(width: 8), Text('Wellness Score', style: theme.textTheme.titleLarge)]),
        const SizedBox(height: 16),
        Row(children: [
          ProgressRing(size: 110, strokeWidth: 10, progress: app.wellnessScore.toDouble(), color: AppColors.green, label: '${app.wellnessScore}', sublabel: 'Score', fontSize: 28),
          const SizedBox(width: 24),
          Expanded(child: Column(children: [
            Row(children: [Text('Mood', style: theme.textTheme.bodySmall), const Spacer(), Text(app.mood == 'great' ? '😊' : '🙂', style: const TextStyle(fontSize: 20))]),
            const SizedBox(height: 8),
            Row(children: [Text('Energy', style: theme.textTheme.bodySmall), const SizedBox(width: 8), Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: app.energy / 100, minHeight: 6, backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.06), valueColor: const AlwaysStoppedAnimation(AppColors.coral)))), const SizedBox(width: 8), Text('${app.energy}%', style: theme.textTheme.labelSmall)]),
            const SizedBox(height: 8),
            Row(children: [Text('Stress', style: theme.textTheme.bodySmall), const SizedBox(width: 8), Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: app.stress / 100, minHeight: 6, backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.06), valueColor: AlwaysStoppedAnimation(app.stress < 50 ? AppColors.green : AppColors.coral)))), const SizedBox(width: 8), Text('${app.stress}%', style: theme.textTheme.labelSmall)]),
          ])),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          _VitalCard(icon: LucideIcons.thermometer, label: 'Temp', value: '${app.temperature}°F', color: AppColors.coral, theme: theme, isDark: isDark),
          const SizedBox(width: 8),
          _VitalCard(icon: LucideIcons.activity, label: 'BP', value: '${app.systolic}/${app.diastolic}', color: AppColors.coral, theme: theme, isDark: isDark),
          const SizedBox(width: 8),
          _VitalCard(icon: LucideIcons.wind, label: 'SpO₂', value: '${app.oxygenLevel}%', color: AppColors.blue, theme: theme, isDark: isDark),
        ]),
      ])),
      const SizedBox(height: 100),
    ]));
  }
}

Widget _zoneBar(String name, String time, Color color, double pct, ThemeData theme) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [
  SizedBox(width: 55, child: Text(name, style: theme.textTheme.labelSmall?.copyWith(fontSize: 10))),
  Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(3), child: LinearProgressIndicator(value: pct, minHeight: 6, backgroundColor: Colors.white.withValues(alpha: 0.05), valueColor: AlwaysStoppedAnimation(color)))),
  const SizedBox(width: 8), SizedBox(width: 24, child: Text(time, style: theme.textTheme.labelSmall?.copyWith(fontSize: 10), textAlign: TextAlign.right)),
]));

Widget _sleepStage(String name, String value, Color color, ThemeData theme, bool isDark) => Container(padding: const EdgeInsets.symmetric(horizontal: 8),
  decoration: BoxDecoration(color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02), borderRadius: BorderRadius.circular(8)),
  child: Row(children: [Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)), const SizedBox(width: 6),
    Text(name, style: theme.textTheme.bodySmall?.copyWith(fontSize: 11)), const Spacer(), Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700, fontSize: 12))]));

class _VitalCard extends StatelessWidget {
  final IconData icon; final String label; final String value; final Color color; final ThemeData theme; final bool isDark;
  const _VitalCard({required this.icon, required this.label, required this.value, required this.color, required this.theme, required this.isDark});
  @override Widget build(BuildContext context) => Expanded(child: Container(padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02), borderRadius: BorderRadius.circular(12)),
    child: Row(children: [Icon(icon, size: 16, color: color), const SizedBox(width: 6), Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Text(label, style: theme.textTheme.labelSmall?.copyWith(fontSize: 9)), Text(value, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700, fontSize: 11))])])));
}
