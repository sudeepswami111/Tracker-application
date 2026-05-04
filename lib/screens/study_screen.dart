import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/app_provider.dart';
import '../widgets/glass_card.dart';
import '../widgets/progress_ring.dart';
import '../theme/app_colors.dart';

class StudyScreen extends StatefulWidget {
  const StudyScreen({super.key});
  @override State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen> {
  int _timerSeconds = 25 * 60;
  Timer? _timer;

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  void _toggleTimer(AppProvider app) {
    if (app.focusTimerRunning) {
      _timer?.cancel(); app.toggleFocusTimer();
    } else {
      app.toggleFocusTimer();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_timerSeconds <= 1) { _timer?.cancel(); app.completeFocusSession(); setState(() => _timerSeconds = app.focusTimerDuration); return; }
        setState(() => _timerSeconds--);
      });
    }
  }

  void _resetTimer(AppProvider app) {
    _timer?.cancel();
    if (app.focusTimerRunning) app.toggleFocusTimer();
    setState(() => _timerSeconds = app.focusTimerDuration);
  }

  String _fmt(int s) => '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final timerProg = ((app.focusTimerDuration - _timerSeconds) / app.focusTimerDuration * 100);

    return SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Study Tracker', style: theme.textTheme.displayLarge),
      const SizedBox(height: 4),
      Text('Track your learning and build consistency', style: theme.textTheme.bodySmall),
      const SizedBox(height: 20),

      // Streak
      GlassCard(child: Column(children: [
        const Text('🔥', style: TextStyle(fontSize: 48)),
        ShaderMask(shaderCallback: (b) => AppColors.gradientStreak.createShader(b),
          child: Text('${app.studyStreak}', style: theme.textTheme.displayLarge?.copyWith(fontSize: 64, color: Colors.white))),
        Text('Day Streak', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 8),
        Text('Longest ${app.longestStreak} days', style: theme.textTheme.bodySmall),
        const SizedBox(height: 12),
        ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: app.studyStreak / app.longestStreak, minHeight: 6,
          backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.06), valueColor: const AlwaysStoppedAnimation(AppColors.coral))),
      ])),
      const SizedBox(height: 16),

      // Focus Timer
      GlassCard(child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [Icon(LucideIcons.target, size: 18, color: AppColors.primary), const SizedBox(width: 8), Text('Focus Timer', style: theme.textTheme.titleLarge)]),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
            child: Text('${app.focusSessionsCompleted} done', style: theme.textTheme.labelSmall?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700))),
        ]),
        const SizedBox(height: 20),
        ProgressRing(size: 160, strokeWidth: 8, progress: timerProg, color: app.focusTimerRunning ? AppColors.primary : AppColors.darkOutline, label: _fmt(_timerSeconds), sublabel: app.focusTimerRunning ? 'Focus time' : 'Ready', fontSize: 28),
        const SizedBox(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          ElevatedButton.icon(onPressed: () => _toggleTimer(app), icon: Icon(app.focusTimerRunning ? LucideIcons.pause : LucideIcons.play, size: 16), label: Text(app.focusTimerRunning ? 'Pause' : 'Start')),
          const SizedBox(width: 12),
          OutlinedButton.icon(onPressed: () => _resetTimer(app), icon: const Icon(LucideIcons.rotateCcw, size: 16), label: const Text('Reset'),
            style: OutlinedButton.styleFrom(foregroundColor: theme.colorScheme.onSurfaceVariant, side: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.3)))),
        ]),
      ])),
      const SizedBox(height: 16),

      // Today
      GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [Icon(LucideIcons.clock, size: 18, color: AppColors.primary), const SizedBox(width: 8), Text('Today', style: theme.textTheme.titleLarge)]),
          IconButton(icon: const Icon(LucideIcons.plus, size: 18), onPressed: () => _showAddSession(context, app)),
        ]),
        RichText(text: TextSpan(children: [
          TextSpan(text: (app.totalStudyMinutes / 60).toStringAsFixed(1), style: theme.textTheme.displayLarge?.copyWith(fontSize: 32, color: AppColors.primary)),
          TextSpan(text: ' hours studied', style: theme.textTheme.bodySmall),
        ])),
        const SizedBox(height: 12),
        ...app.studySessions.map((s) => Container(margin: const EdgeInsets.only(bottom: 6), padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02), borderRadius: BorderRadius.circular(10)),
          child: Row(children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: s['color'] as Color, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s['subject'] as String, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
              Text(s['time'] as String, style: theme.textTheme.labelSmall?.copyWith(fontSize: 9)),
            ])),
            Text('${s['duration']} min', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700, color: AppColors.primary)),
          ]))),
      ])),
      const SizedBox(height: 16),

      // Subject Progress
      GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(LucideIcons.barChart3, size: 18, color: AppColors.primary), const SizedBox(width: 8), Text('Subject Progress', style: theme.textTheme.titleLarge)]),
        const SizedBox(height: 16),
        ...app.subjects.map((s) => Padding(padding: const EdgeInsets.only(bottom: 14), child: Column(children: [
          Row(children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: s['color'] as Color, shape: BoxShape.circle)),
            const SizedBox(width: 8), Expanded(child: Text(s['name'] as String, style: theme.textTheme.bodySmall)),
            Text('${s['hours']}h', style: theme.textTheme.labelSmall),
            const SizedBox(width: 8),
            Text('${s['progress']}%', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 6),
          ClipRRect(borderRadius: BorderRadius.circular(3), child: LinearProgressIndicator(value: (s['progress'] as int) / 100, minHeight: 6,
            backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.06),
            valueColor: AlwaysStoppedAnimation(s['color'] as Color))),
        ]))),
      ])),
      const SizedBox(height: 16),

      // Heatmap
      GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('📊 Study Heatmap', style: theme.textTheme.titleLarge),
        const SizedBox(height: 16),
        ...List.generate(app.weeklyHeatmap.length, (wi) {
          return Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(children: [
            SizedBox(width: 24, child: Text('W${wi + 1}', style: theme.textTheme.labelSmall?.copyWith(fontSize: 9))),
            ...List.generate(7, (di) {
              final val = app.weeklyHeatmap[wi][di];
              return Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 2),
                child: AspectRatio(aspectRatio: 1, child: Container(decoration: BoxDecoration(
                  color: val == 0 ? (isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.03))
                    : AppColors.primary.withValues(alpha: 0.2 + (val / 4) * 0.6),
                  borderRadius: BorderRadius.circular(4))))));
            }),
          ]));
        }),
      ])),
      const SizedBox(height: 16),

      // Milestones
      GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(LucideIcons.trophy, size: 18, color: AppColors.yellow), const SizedBox(width: 8), Text('Milestones', style: theme.textTheme.titleLarge)]),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: app.milestones.map((m) {
          final achieved = m['achieved'] as bool;
          return Container(width: MediaQuery.of(context).size.width / 2 - 40, padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02), borderRadius: BorderRadius.circular(14),
              border: achieved ? Border.all(color: AppColors.primary.withValues(alpha: 0.2)) : null),
            child: Opacity(opacity: achieved ? 1 : 0.6, child: Row(children: [
              Text(m['icon'] as String, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(child: Text(m['title'] as String, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600))),
              if (achieved) Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: AppColors.green.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                child: Text('✓', style: theme.textTheme.labelSmall?.copyWith(color: AppColors.green, fontSize: 10))),
            ])));
        }).toList()),
      ])),
      const SizedBox(height: 100),
    ]));
  }

  void _showAddSession(BuildContext context, AppProvider app) {
    String subject = app.subjects.first['name'] as String; int duration = 30;
    showModalBottomSheet(context: context, isScrollControlled: true,
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppColors.darkSurfaceContainer : AppColors.lightSurface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Log Study Session', style: Theme.of(ctx).textTheme.headlineMedium), const SizedBox(height: 20),
          DropdownButtonFormField<String>(initialValue: subject, decoration: const InputDecoration(labelText: 'Subject'),
            items: app.subjects.map((s) => DropdownMenuItem(value: s['name'] as String, child: Text(s['name'] as String))).toList(),
            onChanged: (v) => setS(() => subject = v!)),
          const SizedBox(height: 12),
          TextFormField(initialValue: '$duration', decoration: const InputDecoration(labelText: 'Duration (min)'), keyboardType: TextInputType.number, onChanged: (v) => duration = int.tryParse(v) ?? 30),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: () {
            app.addStudySession({'id': DateTime.now().millisecondsSinceEpoch, 'subject': subject, 'duration': duration, 'color': AppColors.primary, 'time': TimeOfDay.now().format(ctx)});
            Navigator.pop(ctx);
          }, icon: const Icon(LucideIcons.plus, size: 16), label: const Text('Log Session'))),
        ]))));
  }
}
