import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/app_provider.dart';
import '../widgets/glass_card.dart';
import '../widgets/stat_card.dart';
import '../widgets/progress_ring.dart';
import '../theme/app_colors.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  late AnimationController _flameController;
  late Animation<double> _flameScale;
  // Feature 1 — Pulse score ring entry animation
  late AnimationController _pulseRingController;
  late Animation<double> _pulseRingAnim;
  // Feature 2 — Habit replay page
  final PageController _replayPageCtrl = PageController();
  int _replayPage = 0;

  @override
  void initState() {
    super.initState();
    _flameController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _flameScale = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _flameController, curve: Curves.easeInOut),
    );
    // Feature 1 — animate ring fill on first build
    _pulseRingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseRingAnim = CurvedAnimation(
      parent: _pulseRingController,
      curve: Curves.easeOut,
    );
    _pulseRingController.forward();
  }

  @override
  void dispose() {
    _flameController.dispose();
    _pulseRingController.dispose();
    _replayPageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
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
          // 1.2 — Personalized Pulse Summary
          Builder(builder: (ctx) {
            final pulse = app.pulseScore;
            String msg;
            Color scoreColor;
            if (pulse >= 80) {
              msg = "You're crushing it today!";
              scoreColor = AppColors.green;
            } else if (pulse >= 50) {
              msg = 'Good pace — keep pushing.';
              scoreColor = AppColors.yellow;
            } else {
              msg = "Let's get moving.";
              scoreColor = AppColors.coral;
            }
            return RichText(
              text: TextSpan(
                style: theme.textTheme.bodySmall,
                children: [
                  TextSpan(text: msg),
                  const TextSpan(text: ' '),
                  TextSpan(
                    text: '$pulse%',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scoreColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const TextSpan(text: ' pulse'),
                ],
              ),
            );
          }),
          const SizedBox(height: 20),

          // ── Feature 1: Pulse Score Ring ──
          _PulseScoreRing(app: app, theme: theme, animation: _pulseRingAnim),
          const SizedBox(height: 20),

          // Stats Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final double cardWidth = (constraints.maxWidth - 12) / 2;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: statCards.map((c) {
                  final isWater = (c['label'] as String).toUpperCase() == 'WATER';
                  return SizedBox(
                    // 1.3 — Full width for Water card
                    width: isWater ? constraints.maxWidth : cardWidth,
                    child: StatCard(
                      icon: c['icon'] as IconData,
                      label: c['label'] as String,
                      value: c['value'] as String,
                      unit: c['unit'] as String,
                      progress: c['progress'] as double,
                      gradient: c['gradient'] as LinearGradient,
                      trend: c['trend'] as int,
                      onTap: isWater ? () => app.addWater() : null,
                      waterGlasses: isWater ? app.waterGlasses : null,
                      waterGlassGoal: isWater ? app.waterGlassGoal : null,
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 20),

          // 1.5 — Streak Inline Motivational Banner
          Builder(builder: (ctx) {
            final longestStreak = app.streaks.isEmpty
                ? 0
                : app.streaks.values.reduce((a, b) => a > b ? a : b);
            final todayGoalCompletion = app.dailyGoals.isEmpty
                ? 0.0
                : (app.dailyGoals
                        .map((g) => (g['progress'] as int).clamp(0, 100))
                        .reduce((a, b) => a + b) /
                    (app.dailyGoals.length * 100));
            return GestureDetector(
              onTap: () {},
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.darkSurface2,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    // Animated flame
                    ScaleTransition(
                      scale: _flameScale,
                      child: Icon(LucideIcons.flame, color: AppColors.coral, size: 28),
                    ),
                    const SizedBox(width: 12),
                    // Streak text
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '$longestStreak ',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            TextSpan(
                              text: 'day streak',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Today's goal % bar
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${(todayGoalCompletion * 100).round()}%',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white70,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: SizedBox(
                            width: 64,
                            child: LinearProgressIndicator(
                              value: todayGoalCompletion.clamp(0.0, 1.0),
                              minHeight: 5,
                              backgroundColor: Colors.white12,
                              valueColor: AlwaysStoppedAnimation(AppColors.coral),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 16),

          // ── Feature 2: Habit Replay Card ──
          _HabitReplayCard(
            history: app.history,
            todaySteps: app.steps,
            todayCalories: app.todayCalories,
            todaySleep: app.sleepHours,
            todayStudy: app.studyHrs,
            pageCtrl: _replayPageCtrl,
            currentPage: _replayPage,
            onPageChanged: (p) => setState(() => _replayPage = p),
            theme: theme,
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
                  final icons = {'positive': LucideIcons.sparkles, 'suggestion': LucideIcons.lightbulb, 'warning': LucideIcons.alertTriangle};
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(icons[insight['type']] ?? LucideIcons.lightbulb, size: 16, color: AppColors.primary),
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
                              child: Icon(badge['icon'] as IconData, size: 24, color: unlocked ? AppColors.primary : theme.colorScheme.onSurfaceVariant),
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
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ProgressRing(size: 80, strokeWidth: 8, progress: app.steps / app.stepsGoal * 100, color: AppColors.primary, label: '${(app.steps / app.stepsGoal * 100).round()}%', sublabel: 'Steps', fontSize: 14),
                  const SizedBox(width: 16),
                  ProgressRing(size: 80, strokeWidth: 8, progress: app.calories / app.caloriesGoal * 100, color: AppColors.coral, label: '${(app.calories / app.caloriesGoal * 100).round()}%', sublabel: 'Cal', fontSize: 14),
                  const SizedBox(width: 16),
                  ProgressRing(size: 80, strokeWidth: 8, progress: app.sleepHours / app.sleepGoal * 100, color: AppColors.green, label: '${(app.sleepHours / app.sleepGoal * 100).round()}%', sublabel: 'Sleep', fontSize: 14),
                  const SizedBox(width: 16),
                  ProgressRing(size: 80, strokeWidth: 8, progress: app.waterIntake / app.waterGoal * 100, color: AppColors.secondary, label: '${(app.waterIntake / app.waterGoal * 100).round()}%', sublabel: 'Water', fontSize: 14),
                ],
              ),
            ),
          ),
          const SizedBox(height: 100), // Bottom nav clearance
        ],
      ),
    );
  }
}

// ── Feature 1: Pulse Score Ring ─────────────────────────────────────────
class _PulseScoreRing extends StatelessWidget {
  final AppProvider app;
  final ThemeData theme;
  final Animation<double> animation;

  const _PulseScoreRing({
    required this.app,
    required this.theme,
    required this.animation,
  });

  String _label(int score) {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Good';
    if (score >= 40) return 'Getting there';
    return "Let's go!";
  }

  Color _labelColor(int score) {
    if (score >= 80) return AppColors.green;
    if (score >= 60) return AppColors.yellow;
    if (score >= 40) return AppColors.coral;
    return AppColors.coral;
  }

  @override
  Widget build(BuildContext context) {
    final score = app.pulseScore;
    final isDark = theme.brightness == Brightness.dark;
    return Center(
      child: AnimatedBuilder(
        animation: animation,
        builder: (_, child) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.12),
                  AppColors.secondary.withValues(alpha: 0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 110,
                  height: 110,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Animated ring
                      SizedBox(
                        width: 110,
                        height: 110,
                        child: CircularProgressIndicator(
                          value: (score / 100) * animation.value,
                          strokeWidth: 10,
                          backgroundColor: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.06),
                          valueColor: AlwaysStoppedAnimation(
                            Color.lerp(
                              AppColors.primary,
                              AppColors.secondary,
                              score / 100,
                            )!,
                          ),
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      // Center score text
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${(score * animation.value).round()}',
                            style: theme.textTheme.displayLarge?.copyWith(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            'PULSE',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 9,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _label(score),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: _labelColor(score),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Feature 2: Habit Replay Card ────────────────────────────────────────
class _HabitReplayCard extends StatelessWidget {
  final List<DailySnapshot> history;
  final int todaySteps;
  final int todayCalories;
  final double todaySleep;
  final double todayStudy;
  final PageController pageCtrl;
  final int currentPage;
  final ValueChanged<int> onPageChanged;
  final ThemeData theme;

  const _HabitReplayCard({
    required this.history,
    required this.todaySteps,
    required this.todayCalories,
    required this.todaySleep,
    required this.todayStudy,
    required this.pageCtrl,
    required this.currentPage,
    required this.onPageChanged,
    required this.theme,
  });

  double _avg(List<double> vals) =>
      vals.isEmpty ? 0 : vals.reduce((a, b) => a + b) / vals.length;

  @override
  Widget build(BuildContext context) {
    final isDark = theme.brightness == Brightness.dark;

    // Last 7 snapshots for averages
    final recent = history.take(7).toList();
    final avgSteps = _avg(recent.map((s) => s.steps.toDouble()).toList());
    final avgCal   = _avg(recent.map((s) => s.calories.toDouble()).toList());
    final avgSleep = _avg(recent.map((s) => s.sleepHours).toList());
    final avgStudy = _avg(recent.map((s) => s.studyHrs).toList());

    final metrics = [
      _ReplayMetric('Steps', avgSteps, todaySteps.toDouble(), LucideIcons.footprints, AppColors.primary, (v) => v.toInt().toString()),
      _ReplayMetric('Calories', avgCal, todayCalories.toDouble(), LucideIcons.flame, AppColors.coral, (v) => '${v.toInt()} kcal'),
      _ReplayMetric('Sleep', avgSleep, todaySleep, LucideIcons.moon, AppColors.green, (v) => '${v.toStringAsFixed(1)} hrs'),
      _ReplayMetric('Study', avgStudy, todayStudy, LucideIcons.bookOpen, AppColors.pink, (v) => '${v.toStringAsFixed(1)} hrs'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfaceContainer.withValues(alpha: 0.7)
            : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Icon(LucideIcons.repeat2, size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('Habit Replay', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const Spacer(),
                // Page dots
                Row(
                  children: List.generate(metrics.length, (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.only(left: 4),
                    width: i == currentPage ? 16 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == currentPage
                          ? metrics[i].color
                          : (isDark ? Colors.white24 : Colors.black12),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  )),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 120,
            child: PageView.builder(
              controller: pageCtrl,
              onPageChanged: onPageChanged,
              itemCount: metrics.length,
              itemBuilder: (_, i) => AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _ReplayPage(
                  key: ValueKey(i),
                  metric: metrics[i],
                  theme: theme,
                  isDark: isDark,
                  hasHistory: recent.isNotEmpty,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReplayMetric {
  final String name;
  final double lastWeekAvg;
  final double today;
  final IconData icon;
  final Color color;
  final String Function(double) fmt;

  const _ReplayMetric(this.name, this.lastWeekAvg, this.today, this.icon, this.color, this.fmt);

  double get pctDiff => lastWeekAvg == 0 ? 0 : ((today - lastWeekAvg) / lastWeekAvg * 100);
  bool get isAhead => today >= lastWeekAvg;
}

class _ReplayPage extends StatelessWidget {
  final _ReplayMetric metric;
  final ThemeData theme;
  final bool isDark;
  final bool hasHistory;

  const _ReplayPage({
    super.key,
    required this.metric,
    required this.theme,
    required this.isDark,
    required this.hasHistory,
  });

  @override
  Widget build(BuildContext context) {
    final diff = metric.pctDiff;
    final ahead = metric.isAhead;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(metric.icon, color: metric.color, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  metric.name,
                  style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 0.5),
                ),
                const SizedBox(height: 4),
                Text(
                  'Today: ${metric.fmt(metric.today)}',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  hasHistory
                      ? 'Last week avg: ${metric.fmt(metric.lastWeekAvg)}'
                      : 'No history yet',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (hasHistory)
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  ahead ? LucideIcons.trendingUp : LucideIcons.trendingDown,
                  color: ahead ? AppColors.green : AppColors.coral,
                  size: 22,
                ),
                const SizedBox(height: 4),
                Text(
                  '${diff.abs().toStringAsFixed(1)}%',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: ahead ? AppColors.green : AppColors.coral,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
