import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/app_provider.dart';
import '../widgets/glass_card.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class StudyScreen extends StatefulWidget {
  const StudyScreen({super.key});

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen> with TickerProviderStateMixin {
  int _timerSeconds = 25 * 60;
  final int _totalSeconds = 25 * 60;
  Timer? _timer;
  bool _isRunning = false;

  // Task list mock data
  final List<Map<String, dynamic>> _tasks = [
    {'id': '1', 'title': 'Read Chapter 4 (Biology)', 'priority': 'Red', 'time': '45m', 'done': false},
    {'id': '2', 'title': 'Draft History Essay', 'priority': 'Amber', 'time': '60m', 'done': false},
    {'id': '3', 'title': 'Review Math Notes', 'priority': 'Cyan', 'time': '30m', 'done': false},
  ];

  final List<Map<String, dynamic>> _completedTasks = [
    {'id': '4', 'title': 'Reply to study group', 'priority': 'Cyan', 'time': '10m', 'done': true},
  ];
  
  bool _showCompleted = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleTimer() {
    HapticFeedback.lightImpact();
    if (_isRunning) {
      _timer?.cancel();
      setState(() => _isRunning = false);
    } else {
      setState(() => _isRunning = true);
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_timerSeconds <= 1) {
          _timer?.cancel();
          HapticFeedback.heavyImpact();
          setState(() {
            _isRunning = false;
            _timerSeconds = _totalSeconds;
          });
          context.read<AppProvider>().completeFocusSession();
          return;
        }
        setState(() => _timerSeconds--);
      });
    }
  }

  void _skipTimer() {
    HapticFeedback.mediumImpact();
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _timerSeconds = _totalSeconds;
    });
  }

  String _fmt(int s) {
    final m = s ~/ 60;
    final sec = s % 60;
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Red': return AppColors.pulseRed;
      case 'Amber': return AppColors.solarAmber;
      case 'Cyan': return AppColors.voltCyan;
      default: return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final double fractionRemaining = _timerSeconds / _totalSeconds;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDeep : AppColors.lightBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.md),
              // 1. TOP BAR
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Study', style: theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w900)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.irisViolet.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.irisViolet.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.flame, color: AppColors.irisViolet, size: 16),
                        const SizedBox(width: 4),
                        Text('${app.studyStreak} Day Streak', style: theme.textTheme.labelMedium?.copyWith(color: AppColors.irisViolet, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              // 2. POMODORO TILE
              GlassCard(
                child: SizedBox(
                  width: double.infinity,
                  height: 220,
                  child: Column(
                    children: [
                      Expanded(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 140,
                              height: 140,
                              child: CustomPaint(
                                painter: _PomodoroRingPainter(
                                  fraction: fractionRemaining,
                                  isDark: isDark,
                                ),
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _fmt(_timerSeconds),
                                  style: theme.textTheme.displayLarge?.copyWith(
                                    fontSize: 40,
                                    fontWeight: FontWeight.w900,
                                    fontFeatures: const [FontFeature.tabularFigures()],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Deep Work #3', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              Row(
                                children: List.generate(4, (index) {
                                  final bool completed = index < 2;
                                  final bool active = index == 2;
                                  return Container(
                                    margin: const EdgeInsets.only(right: 6),
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: completed ? AppColors.irisViolet : Colors.transparent,
                                      border: Border.all(
                                        color: completed || active ? AppColors.irisViolet : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                                        width: 1.5,
                                      ),
                                      boxShadow: active && _isRunning
                                          ? [BoxShadow(color: AppColors.irisViolet.withValues(alpha: 0.5), blurRadius: 4, spreadRadius: 1)]
                                          : null,
                                    ),
                                  );
                                }),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: _skipTimer,
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
                                  ),
                                  child: Icon(LucideIcons.skipForward, size: 16, color: theme.colorScheme.onSurfaceVariant),
                                ),
                              ),
                              const SizedBox(width: 12),
                              GestureDetector(
                                onTap: _toggleTimer,
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: AppColors.irisViolet,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(color: AppColors.irisViolet.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4)),
                                    ],
                                  ),
                                  child: Icon(_isRunning ? LucideIcons.pause : LucideIcons.play, color: Colors.white, size: 24),
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // 3. AI NUDGE CARD
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.backgroundDeep.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.irisViolet.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: AppColors.irisViolet.withValues(alpha: 0.15), shape: BoxShape.circle),
                      child: const Icon(LucideIcons.sparkles, color: AppColors.irisViolet, size: 18),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('You focus best at 9–11am. Start now?', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text('Start Suggested Session', style: theme.textTheme.labelMedium?.copyWith(color: AppColors.irisViolet, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // 4. FOCUS STATS ROW
              Row(
                children: [
                  Expanded(child: _miniStatCard('Today', '2.5h', AppColors.irisViolet, isDark)),
                  const SizedBox(width: 12),
                  Expanded(child: _miniStatCard('Weekly Avg', '3.1h', theme.colorScheme.onSurface, isDark)),
                  const SizedBox(width: 12),
                  Expanded(child: _miniStatCard('Streak', '${app.studyStreak}d', AppColors.solarAmber, isDark)),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // 5. WEEKLY BAR CHART
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Focus Time', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 100,
                      child: CustomPaint(
                        size: const Size(double.infinity, 100),
                        painter: _WeeklyChartPainter(isDark: isDark),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // 6. TASK LIST HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text("Today's Tasks", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.irisViolet, borderRadius: BorderRadius.circular(10)),
                        child: Text('${_tasks.length}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(LucideIcons.plus, size: 16, color: AppColors.irisViolet),
                    label: const Text('Add Task', style: TextStyle(color: AppColors.irisViolet, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // 7. TASK LIST
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _tasks.length,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (oldIndex < newIndex) newIndex -= 1;
                    final item = _tasks.removeAt(oldIndex);
                    _tasks.insert(newIndex, item);
                  });
                },
                itemBuilder: (context, index) {
                  final task = _tasks[index];
                  return Dismissible(
                    key: Key(task['id'] as String),
                    background: Container(
                      color: AppColors.irisViolet,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.only(left: 20),
                      child: const Icon(LucideIcons.check, color: Colors.white),
                    ),
                    secondaryBackground: Container(
                      color: AppColors.pulseRed,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Icon(LucideIcons.trash2, color: Colors.white),
                    ),
                    onDismissed: (direction) {
                      if (direction == DismissDirection.startToEnd) {
                        // Complete
                        setState(() {
                          task['done'] = true;
                          _completedTasks.insert(0, task);
                          _tasks.removeAt(index);
                        });
                        HapticFeedback.lightImpact();
                      } else {
                        // Delete
                        setState(() {
                          _tasks.removeAt(index);
                        });
                      }
                    },
                    child: _buildTaskRow(task, isDark, theme),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.lg),

              // 8. COMPLETED TASKS SECTION
              if (_completedTasks.isNotEmpty) ...[
                GestureDetector(
                  onTap: () => setState(() => _showCompleted = !_showCompleted),
                  child: Row(
                    children: [
                      Icon(_showCompleted ? LucideIcons.chevronDown : LucideIcons.chevronRight, size: 20, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 8),
                      Text('Completed (${_completedTasks.length})', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                if (_showCompleted)
                  ..._completedTasks.map((task) => Opacity(
                    opacity: 0.5,
                    child: _buildTaskRow(task, isDark, theme),
                  )),
              ],

              const SizedBox(height: 100), // Bottom nav padding
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniStatCard(String label, String value, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: isDark ? Colors.white70 : Colors.black54)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }

  Widget _buildTaskRow(Map<String, dynamic> task, bool isDark, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceElevated : AppColors.lightSurfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: _getPriorityColor(task['priority'] as String),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              task['title'] as String,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                decoration: (task['done'] as bool) ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(task['time'] as String, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _PomodoroRingPainter extends CustomPainter {
  final double fraction;
  final bool isDark;

  _PomodoroRingPainter({required this.fraction, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = 8.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background track
    final bgPaint = Paint()
      ..color = isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, bgPaint);

    // Color shift: Violet -> Amber in the last 20%
    Color progressColor = AppColors.irisViolet;
    if (fraction < 0.2) {
      final t = 1.0 - (fraction / 0.2); // 0.0 at 20%, 1.0 at 0%
      progressColor = Color.lerp(AppColors.irisViolet, AppColors.solarAmber, t) ?? AppColors.solarAmber;
    }

    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final startAngle = -pi / 2;
    final sweepAngle = 2 * pi * fraction;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _PomodoroRingPainter oldDelegate) {
    return oldDelegate.fraction != fraction || oldDelegate.isDark != isDark;
  }
}

class _WeeklyChartPainter extends CustomPainter {
  final bool isDark;

  _WeeklyChartPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final data = [45.0, 60.0, 30.0, 90.0, 120.0, 50.0, 0.0]; // Mon-Sun
    final maxVal = 120.0;
    final barWidth = 16.0;
    final spacing = (size.width - (barWidth * 7)) / 6;
    final currentDayIndex = 4; // Mock Friday

    final bgPaint = Paint()..color = isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05);
    final activePaint = Paint()..color = AppColors.irisViolet;

    for (var i = 0; i < 7; i++) {
      final height = (data[i] / maxVal) * size.height;
      final x = i * (barWidth + spacing);
      final y = size.height - height;

      final rect = RRect.fromRectAndCorners(
        Rect.fromLTWH(x, y, barWidth, height),
        topLeft: const Radius.circular(4),
        topRight: const Radius.circular(4),
      );

      canvas.drawRRect(rect, i == currentDayIndex ? activePaint : bgPaint);
      
      // Draw day label
      final textPainter = TextPainter(
        text: TextSpan(
          text: ['M', 'T', 'W', 'T', 'F', 'S', 'S'][i],
          style: TextStyle(
            color: isDark ? Colors.white54 : Colors.black54,
            fontSize: 10,
            fontWeight: i == currentDayIndex ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x + (barWidth - textPainter.width) / 2, size.height + 4));
    }

    // Draw average dashed line
    final avgHeight = size.height * 0.5; // Mock average
    final dashPaint = Paint()
      ..color = AppColors.solarAmber.withValues(alpha: 0.6)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    
    double dx = 0;
    while (dx < size.width) {
      canvas.drawLine(Offset(dx, size.height - avgHeight), Offset(dx + 6, size.height - avgHeight), dashPaint);
      dx += 10;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
