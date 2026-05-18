import 'dart:async';
import 'dart:math';
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
  int _totalSeconds = 25 * 60;
  Timer? _timer;
  bool _isRunning = false;
  int _completedSessionsToday = 0;

  // Task list (mock data removed)
  final List<Map<String, dynamic>> _tasks = [];
  final List<Map<String, dynamic>> _completedTasks = [];
  
  bool _showCompleted = false;

  // Weekly focus time in seconds
  final List<double> _weeklyFocusSeconds = [0, 0, 0, 0, 0, 0, 0];

  final List<Map<String, dynamic>> _suggestions = [
    {'title': 'Deep Work', 'desc': '50m focused session', 'minutes': 50, 'icon': LucideIcons.brain},
    {'title': 'Pomodoro', 'desc': '25m standard focus', 'minutes': 25, 'icon': LucideIcons.timer},
    {'title': 'Quick Review', 'desc': '15m quick sprint', 'minutes': 15, 'icon': LucideIcons.zap},
  ];

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
        final dayIndex = DateTime.now().weekday - 1;
        setState(() {
          _weeklyFocusSeconds[dayIndex] += 1.0;
        });

        if (_timerSeconds <= 1) {
          _timer?.cancel();
          HapticFeedback.heavyImpact();
          setState(() {
            _isRunning = false;
            _timerSeconds = _totalSeconds;
            _completedSessionsToday++;
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

  void _showTimePickerDialog() {
    if (_isRunning) return;
    int minutes = _totalSeconds ~/ 60;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Timer Duration'),
        content: TextField(
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Minutes (e.g., 25)'),
          onChanged: (v) {
            minutes = int.tryParse(v) ?? minutes;
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _totalSeconds = (minutes > 0 ? minutes : 25) * 60;
                _timerSeconds = _totalSeconds;
              });
              Navigator.pop(context);
            },
            child: const Text('Set'),
          ),
        ],
      ),
    );
  }

  void _showAddTaskDialog() {
    String title = '';
    String time = '30m';
    String priority = 'Cyan';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Task'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Task Title'),
              onChanged: (v) => title = v,
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Estimated Time (e.g., 30m)'),
              onChanged: (v) => time = v,
            ),
            DropdownButtonFormField<String>(
              value: priority,
              decoration: const InputDecoration(labelText: 'Priority'),
              items: ['Red', 'Amber', 'Cyan', 'Grey'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
              onChanged: (v) => priority = v!,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (title.isNotEmpty) {
                setState(() {
                  _tasks.add({
                    'id': DateTime.now().millisecondsSinceEpoch.toString(),
                    'title': title,
                    'time': time,
                    'priority': priority,
                    'done': false,
                  });
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  String _formatHours(double seconds) {
    if (seconds == 0) return '0h';
    return '${(seconds / 3600).toStringAsFixed(1)}h';
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
                                GestureDetector(
                                  onTap: _showTimePickerDialog,
                                  child: Text(
                                    _fmt(_timerSeconds),
                                    style: theme.textTheme.displayLarge?.copyWith(
                                      fontSize: 40,
                                      fontWeight: FontWeight.w900,
                                      fontFeatures: const [FontFeature.tabularFigures()],
                                    ),
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
                              Text('Deep Work #${_completedSessionsToday + 1}', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              Row(
                                children: List.generate(4, (index) {
                                  final bool completed = index < _completedSessionsToday;
                                  final bool active = index == _completedSessionsToday;
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

              // 3. SUGGESTIONS
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Suggested Sessions', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _suggestions.map((s) => _buildSuggestionCard(s, isDark, theme)).toList(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // 4. FOCUS STATS ROW
              Builder(builder: (context) {
                final todayFocus = _weeklyFocusSeconds[DateTime.now().weekday - 1];
                final validDays = _weeklyFocusSeconds.where((s) => s > 0).toList();
                final avgFocus = validDays.isEmpty ? 0.0 : validDays.reduce((a, b) => a + b) / validDays.length;
                final maxFocus = validDays.isEmpty ? 0.0 : validDays.reduce(max);
                final minFocus = validDays.isEmpty ? 0.0 : validDays.reduce(min);

                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _miniStatCard('Today', _formatHours(todayFocus), AppColors.irisViolet, isDark)),
                        const SizedBox(width: 12),
                        Expanded(child: _miniStatCard('Weekly Avg', _formatHours(avgFocus), theme.colorScheme.onSurface, isDark)),
                        const SizedBox(width: 12),
                        Expanded(child: _miniStatCard('Streak', '${app.studyStreak}d', AppColors.solarAmber, isDark)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _miniStatCard('Most Focus', _formatHours(maxFocus), AppColors.green, isDark)),
                        const SizedBox(width: 12),
                        Expanded(child: _miniStatCard('Least Focus', _formatHours(minFocus), AppColors.pulseRed, isDark)),
                      ],
                    ),
                  ],
                );
              }),
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
                        painter: _WeeklyChartPainter(isDark: isDark, data: _weeklyFocusSeconds),
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
                    onPressed: _showAddTaskDialog,
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

              const SizedBox(height: 150), // Bottom nav padding
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

  Widget _buildSuggestionCard(Map<String, dynamic> s, bool isDark, ThemeData theme) {
    return GestureDetector(
      onTap: () {
        if (_isRunning) return;
        setState(() {
          _totalSeconds = (s['minutes'] as int) * 60;
          _timerSeconds = _totalSeconds;
        });
        _toggleTimer();
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.backgroundDeep.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.irisViolet.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(s['icon'] as IconData, color: AppColors.irisViolet, size: 24),
            const SizedBox(height: 12),
            Text(s['title'] as String, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(s['desc'] as String, style: theme.textTheme.labelSmall?.copyWith(color: AppColors.textSecondary)),
          ],
        ),
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
  final List<double> data;

  _WeeklyChartPainter({required this.isDark, required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    final maxVal = data.isEmpty || data.reduce(max) == 0 ? 3600.0 : data.reduce(max);
    final barWidth = 16.0;
    final spacing = (size.width - (barWidth * 7)) / 6;
    final currentDayIndex = DateTime.now().weekday - 1; // Real day index

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
    final avgHeight = 0.0; // removed mock average
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
