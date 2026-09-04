import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../providers/app_provider.dart';
import '../services/challenge_service.dart';
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

  // Task list (loaded from Hive)
  List<Map<String, dynamic>> _tasks = [];
  final List<Map<String, dynamic>> _completedTasks = [];

  // Weekly focus time in seconds
  List<double> _weeklyFocusSeconds = [3600 * 2.5, 3600 * 1.8, 3600 * 3.0, 3600 * 2.2, 3600 * 2.0, 3600 * 1.5, 3600 * 1.5];

  final List<Map<String, dynamic>> _defaultSubjects = [
    {
      'title': 'Data Structures',
      'duration': '1h 30m',
      'color': AppColors.secondaryBlue,
      'icon': LucideIcons.binary,
      'done': true,
    },
    {
      'title': 'Operating Systems',
      'duration': '1h 00m',
      'color': AppColors.primaryTeal,
      'icon': LucideIcons.cpu,
      'done': false,
    },
    {
      'title': 'DBMS',
      'duration': '45m',
      'color': AppColors.accentOrange,
      'icon': LucideIcons.database,
      'done': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final tasksBox = Hive.box('study_tasks');
    final sessionsBox = Hive.box('study_sessions');

    setState(() {
      _tasks = tasksBox.values.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      _completedTasks.clear();

      final weekData = sessionsBox.get('weeklyFocusSeconds');
      if (weekData != null) {
        _weeklyFocusSeconds = List<double>.from(weekData);
      }

      final String lastDate = sessionsBox.get('lastDate', defaultValue: '');
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);

      if (lastDate != todayStr) {
        sessionsBox.put('lastDate', todayStr);
        sessionsBox.put('completedSessionsToday', 0);
        _completedSessionsToday = 0;
      } else {
        _completedSessionsToday = sessionsBox.get('completedSessionsToday', defaultValue: 0);
      }

      final List<Map<String, dynamic>> pending = [];
      for (var t in _tasks) {
        if (t['done'] == true) {
          _completedTasks.add(t);
        } else {
          pending.add(t);
        }
      }
      _tasks = pending;
    });
  }

  void _saveTasks() {
    final tasksBox = Hive.box('study_tasks');
    tasksBox.clear();
    for (var t in _tasks) {
      tasksBox.add(t);
    }
    for (var t in _completedTasks) {
      tasksBox.add(t);
    }
  }

  void _saveSessions() {
    final sessionsBox = Hive.box('study_sessions');
    sessionsBox.put('weeklyFocusSeconds', _weeklyFocusSeconds);
    sessionsBox.put('completedSessionsToday', _completedSessionsToday);
    sessionsBox.put('lastDate', DateTime.now().toIso8601String().substring(0, 10));
  }

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
        if (!mounted) {
          _timer?.cancel();
          return;
        }
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
          _saveSessions();
          final app = context.read<AppProvider>();
          app.completeFocusSession();
          ChallengeService().updateStudyChallenges(app.studyHrs);
          return;
        }
        setState(() => _timerSeconds--);
      });
    }
  }

  void _selectDuration(int minutes) {
    HapticFeedback.lightImpact();
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _totalSeconds = minutes * 60;
      _timerSeconds = _totalSeconds;
    });
  }

  void _showAddTaskDialog() {
    String title = '';
    String time = '30m';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Add Study Task', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Subject / Topic', hintText: 'e.g. Computer Networks'),
              onChanged: (v) => title = v,
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(labelText: 'Duration', hintText: 'e.g. 45m or 1h 30m'),
              onChanged: (v) => time = v,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.neutralGray)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryTeal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              if (title.isNotEmpty) {
                setState(() {
                  _tasks.add({
                    'id': DateTime.now().millisecondsSinceEpoch.toString(),
                    'title': title,
                    'time': time,
                    'done': false,
                  });
                });
                _saveTasks();
                Navigator.pop(context);
              }
            },
            child: const Text('Add Task'),
          ),
        ],
      ),
    );
  }

  String _fmt(int s) {
    final m = s ~/ 60;
    final sec = s % 60;
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final double fractionRemaining = _timerSeconds / _totalSeconds;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(
            left: AppSpacing.screenMargin,
            right: AppSpacing.screenMargin,
            top: 14,
            bottom: 150,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 1. HEADER: Study & Focus. Learn. Grow. ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Study',
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Focus. Learn. Grow.',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.neutralGray,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.accentOrange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.accentOrange.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.flame, color: AppColors.accentOrange, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${app.studyStreak > 0 ? app.studyStreak : 12}d Streak',
                          style: GoogleFonts.inter(
                            color: AppColors.accentOrange,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // ── 2. TOP ROW: Today's Focus (75%) & Study Streak (12 days) ──
              Row(
                children: [
                  // Left Card: Today's Focus
                  Expanded(
                    child: _buildTodayFocusCard(isDark),
                  ),
                  const SizedBox(width: 12),
                  // Right Card: Study Streak
                  Expanded(
                    child: _buildStudyStreakCard(app.studyStreak > 0 ? app.studyStreak : 12, isDark),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // ── 3. TODAY'S PLAN (Subjects List) ──
              _buildTodayPlanSection(isDark),
              const SizedBox(height: 18),

              // ── 4. FOCUS TIMER (Hero Card) ──
              _buildFocusTimerCard(fractionRemaining, isDark),
              const SizedBox(height: 18),

              // ── 5. STUDY PLANNER (Weekly Bar Chart) ──
              _buildStudyPlannerChartCard(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodayFocusCard(bool isDark) {
    return Container(
      height: 165,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.zenDarkCard : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.cardBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Today's Focus",
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.neutralGray,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Deep Work',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '2h 30m',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryTeal,
                    ),
                  ),
                ],
              ),
              SizedBox(
                width: 54,
                height: 54,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(54, 54),
                      painter: _MiniCircularGaugePainter(
                        progress: 0.75,
                        strokeWidth: 5,
                        progressColor: AppColors.primaryTeal,
                        trackColor: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                      ),
                    ),
                    Text(
                      '75%',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Text(
            'Goal: 3h 20m',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.neutralGray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudyStreakCard(int streakDays, bool isDark) {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Container(
      height: 165,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.zenDarkCard : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.cardBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Study Streak',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.neutralGray,
            ),
          ),
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.accentOrange.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.flame, color: AppColors.accentOrange, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                '$streakDays days',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          // 7-day checklist dots
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final isCompleted = i < 6; // past days checked
              return Column(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted ? AppColors.primaryGreen : Colors.transparent,
                      border: Border.all(
                        color: isCompleted ? AppColors.primaryGreen : AppColors.neutralGray.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                    ),
                    child: isCompleted
                        ? const Icon(Icons.check, color: Colors.white, size: 9)
                        : null,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    days[i],
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: AppColors.neutralGray,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayPlanSection(bool isDark) {
    final allItems = [..._defaultSubjects, ..._tasks.map((t) => {
      'title': t['title'],
      'duration': t['time'] ?? '30m',
      'color': AppColors.secondaryBlue,
      'icon': LucideIcons.bookOpen,
      'done': t['done'] == true,
    })];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.zenDarkCard : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.cardBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Today's Plan",
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${allItems.length} subjects planned',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.neutralGray,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: _showAddTaskDialog,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryTeal.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.plus, size: 16, color: AppColors.primaryTeal),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...allItems.map((s) => _buildSubjectRow(s, isDark)),
        ],
      ),
    );
  }

  Widget _buildSubjectRow(Map<String, dynamic> s, bool isDark) {
    final Color color = s['color'] as Color;
    final IconData icon = s['icon'] as IconData;
    final bool isDone = s['done'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s['title'] as String,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  s['duration'] as String,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.neutralGray,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            isDone ? Icons.check_circle : LucideIcons.chevronRight,
            size: 18,
            color: isDone ? AppColors.primaryGreen : AppColors.neutralGray,
          ),
        ],
      ),
    );
  }

  Widget _buildFocusTimerCard(double fractionRemaining, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [const Color(0xFFEEF2FF), const Color(0xFFE0E7FF)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFC7D2FE),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondaryBlue.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Focus Timer',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.secondaryBlue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Deep Work',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondaryBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // Large digital countdown
          Text(
            _fmt(_timerSeconds),
            style: GoogleFonts.inter(
              fontSize: 48,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : AppColors.textPrimary,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _isRunning ? 'Session in progress' : 'Start Focus Session',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.neutralGray,
            ),
          ),
          const SizedBox(height: 18),
          // Timer Quick Select chips & Play button
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildDurationChip(15, isDark),
              const SizedBox(width: 8),
              _buildDurationChip(25, isDark),
              const SizedBox(width: 8),
              _buildDurationChip(50, isDark),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: _toggleTimer,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.secondaryBlue,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.secondaryBlue.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    _isRunning ? LucideIcons.pause : LucideIcons.play,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDurationChip(int minutes, bool isDark) {
    final isSelected = _totalSeconds == minutes * 60;
    return GestureDetector(
      onTap: () => _selectDuration(minutes),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.secondaryBlue
              : (isDark ? AppColors.zenDarkCard : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.secondaryBlue : const Color(0xFFCBD5E1),
          ),
        ),
        child: Text(
          '${minutes}m',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildStudyPlannerChartCard(bool isDark) {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    const barHeights = [0.75, 0.55, 0.90, 0.65, 0.60, 0.45, 0.45];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.zenDarkCard : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.cardBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Study Planner',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              Text(
                'Planned Hours: 14h 30m',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondaryBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 120,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final currentDay = (DateTime.now().weekday - 1) % 7;
                final isToday = i == currentDay;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 22,
                      height: 80 * barHeights[i],
                      decoration: BoxDecoration(
                        color: isToday ? AppColors.secondaryBlue : const Color(0xFFC7D2FE),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      days[i],
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                        color: isToday
                            ? (isDark ? Colors.white : AppColors.textPrimary)
                            : AppColors.neutralGray,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniCircularGaugePainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color progressColor;
  final Color trackColor;

  _MiniCircularGaugePainter({
    required this.progress,
    required this.strokeWidth,
    required this.progressColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, trackPaint);

    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _MiniCircularGaugePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.progressColor != progressColor;
}
