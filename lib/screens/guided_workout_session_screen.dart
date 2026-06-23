import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';

import '../providers/app_provider.dart';
import '../providers/step_tracker_provider.dart';
import '../models/workout_phase.dart';
import '../theme/app_colors.dart';
import '../services/audio_coach_service.dart';

class GuidedWorkoutSessionScreen extends StatefulWidget {
  final DailyPlan plan;
  final List<WorkoutPhase> phases;

  const GuidedWorkoutSessionScreen({
    super.key,
    required this.plan,
    required this.phases,
  });

  @override
  State<GuidedWorkoutSessionScreen> createState() => _GuidedWorkoutSessionScreenState();
}

class _GuidedWorkoutSessionScreenState extends State<GuidedWorkoutSessionScreen> {
  late List<WorkoutPhase> _phases;
  int _currentPhaseIndex = 0;
  int _phaseRemainingSeconds = 0;
  int _totalElapsedSeconds = 0;
  Timer? _timer;
  bool _isRunning = true;
  late ConfettiController _confetti;
  bool _isFinished = false;

  @override
  void initState() {
    super.initState();
    _phases = List.from(widget.phases);
    _confetti = ConfettiController(duration: const Duration(seconds: 3));

    // Initialize audio coach
    AudioCoachService().initialize().then((_) {
      if (mounted) {
        AudioCoachService().announcePhase(_phases[_currentPhaseIndex].title);
      }
    });

    _currentPhaseIndex = 0;
    _startCurrentPhase();
  }

  void _startCurrentPhase() {
    final phase = _phases[_currentPhaseIndex];

    setState(() {
      _phaseRemainingSeconds = phase.durationMinutes * 60;
      _isRunning = true;
    });

    HapticFeedback.mediumImpact();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isRunning) return;

      if (!mounted) return;

      setState(() {
        _phaseRemainingSeconds--;
        _totalElapsedSeconds++;
      });

      if (_phaseRemainingSeconds <= 0) {
        _goToNextPhase();
      }
    });
  }

  void _goToNextPhase() {
    _timer?.cancel();

    if (_currentPhaseIndex < _phases.length - 1) {
      setState(() {
        _currentPhaseIndex++;
      });

      _startCurrentPhase();
      AudioCoachService().announcePhase(_phases[_currentPhaseIndex].title);
    } else {
      _finishWorkout();
    }
  }

  void _skipPhase() {
    HapticFeedback.mediumImpact();
    _goToNextPhase();
  }

  void _togglePlayPause() {
    HapticFeedback.lightImpact();
    setState(() {
      _isRunning = !_isRunning;
    });
    if (_isRunning) {
      AudioCoachService().announceWorkoutResumed();
    } else {
      AudioCoachService().announceWorkoutPaused();
    }
  }

  void _finishWorkout() {
    _timer?.cancel();
    HapticFeedback.vibrate();
    AudioCoachService().announceWorkoutCompleted();

    // Calculate total duration in minutes
    final durationMinutes = int.tryParse(widget.plan.duration) ?? 30;
    final kcalBurned = int.tryParse(widget.plan.kcal) ?? 200;

    // Complete plan and record metrics
    final app = context.read<AppProvider>();
    app.completePlan(widget.plan.id);

    app.addWorkout({
      'type': widget.plan.type,
      'title': widget.plan.title,
      'duration': durationMinutes,
      'calories': kcalBurned,
      'date': DateTime.now().toIso8601String(),
    });

    // Add manual steps to step tracker provider
    context.read<StepTrackerProvider>().addManualSteps(durationMinutes * 100);

    setState(() {
      _isFinished = true;
    });
    _confetti.play();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _confetti.dispose();
    super.dispose();
  }

  String _fmtSecs(int secs) {
    final m = secs ~/ 60;
    final s = secs % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentPhase = _phases[_currentPhaseIndex];
    final nextPhase = _currentPhaseIndex < _phases.length - 1 ? _phases[_currentPhaseIndex + 1] : null;

    final phaseTotalSeconds = currentPhase.durationMinutes * 60;
    final progressValue = phaseTotalSeconds > 0
        ? (1.0 - (_phaseRemainingSeconds / phaseTotalSeconds)).clamp(0.0, 1.0)
        : 0.0;

    final targetTotalSecs = (widget.phases.fold<int>(0, (sum, p) => sum + p.durationMinutes)) * 60;
    final totalProgress = targetTotalSecs > 0
        ? (_totalElapsedSeconds / targetTotalSecs).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDeep : AppColors.lightBg,
      body: SafeArea(
        child: Stack(
          children: [
            if (!_isFinished)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.plan.type.toUpperCase(),
                              style: const TextStyle(
                                color: AppColors.voltCyan,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.5,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.plan.title,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.x),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: AppColors.surfaceElevated,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                title: const Text('Quit session?', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                                content: const Text('Your progress for this workout will not be saved.', style: TextStyle(color: AppColors.textSecondary)),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      Navigator.pop(context);
                                    },
                                    child: const Text('Quit', style: TextStyle(color: AppColors.pulseRed, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            );
                          },
                          style: IconButton.styleFrom(
                            backgroundColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),

                    // Large Circular Timer
                    SizedBox(
                      width: 260,
                      height: 260,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outer progress ring
                          SizedBox(
                            width: 250,
                            height: 250,
                            child: CircularProgressIndicator(
                              value: progressValue,
                              strokeWidth: 10,
                              backgroundColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.voltCyan),
                            ),
                          ),
                          // Content
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.voltCyan.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  currentPhase.icon,
                                  color: AppColors.voltCyan,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _fmtSecs(_phaseRemainingSeconds),
                                style: theme.textTheme.displayLarge?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                currentPhase.title.toUpperCase(),
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),

                    // Total Elapsed Progress
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Time', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                            Text(
                              '${_fmtSecs(_totalElapsedSeconds)} / ${_fmtSecs(targetTotalSecs)}',
                              style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: totalProgress,
                            minHeight: 6,
                            backgroundColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.solarAmber),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Next Phase Preview Card
                    if (nextPhase != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(nextPhase.icon, color: AppColors.textSecondary, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('NEXT PHASE', style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                  const SizedBox(height: 2),
                                  Text(nextPhase.title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                                ],
                              ),
                            ),
                            Text(
                              '${nextPhase.durationMinutes}m',
                              style: const TextStyle(color: AppColors.voltCyan, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.green.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.green.withValues(alpha: 0.15)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.checkCircle, color: AppColors.green, size: 20),
                            SizedBox(width: 12),
                            Text('Last Phase - Finish strong!', style: TextStyle(color: AppColors.green, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    const Spacer(),

                    // Play/Pause, Skip, End Action controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Stop Button
                        IconButton(
                          icon: const Icon(LucideIcons.square),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: AppColors.surfaceElevated,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                title: const Text('End workout?', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                                content: const Text('You have not completed all phases.', style: TextStyle(color: AppColors.textSecondary)),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      _finishWorkout();
                                    },
                                    child: const Text('End', style: TextStyle(color: AppColors.pulseRed, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            );
                          },
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.pulseRed.withValues(alpha: 0.1),
                            foregroundColor: AppColors.pulseRed,
                            minimumSize: const Size(60, 60),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                        ),

                        // Play/Pause Button
                        IconButton(
                          icon: Icon(_isRunning ? LucideIcons.pause : LucideIcons.play),
                          onPressed: _togglePlayPause,
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.voltCyan,
                            foregroundColor: Colors.black,
                            minimumSize: const Size(80, 80),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                          ),
                        ),

                        // Skip/Next/Finish Button
                        if (nextPhase == null)
                          ElevatedButton.icon(
                            onPressed: _skipPhase,
                            icon: const Icon(LucideIcons.check, size: 16),
                            label: const Text('Finish', style: TextStyle(fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.voltCyan,
                              foregroundColor: Colors.black,
                              minimumSize: const Size(100, 60),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                          )
                        else
                          IconButton(
                            icon: const Icon(LucideIcons.skipForward),
                            onPressed: _skipPhase,
                            style: IconButton.styleFrom(
                              backgroundColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                              foregroundColor: AppColors.textPrimary,
                              minimumSize: const Size(60, 60),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),

            // Finished Celebration State
            if (_isFinished)
              Positioned.fill(
                child: Container(
                  color: isDark ? AppColors.backgroundDeep : AppColors.lightBg,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(),
                      // Celebration Trophy Badge
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: AppColors.voltCyan.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.voltCyan.withValues(alpha: 0.25),
                              blurRadius: 30,
                            ),
                          ],
                        ),
                        child: const Icon(
                          LucideIcons.trophy,
                          color: AppColors.voltCyan,
                          size: 48,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Workout Complete!',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Amazing work! You completed the guided workout and crushed your goal.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 48),

                      // Stats Grid
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem('DURATION', '${widget.plan.duration}m', LucideIcons.timer),
                            Container(width: 1, height: 40, color: isDark ? Colors.white24 : Colors.black12),
                            _buildStatItem('BURN', '${widget.plan.kcal} kcal', LucideIcons.flame),
                            Container(width: 1, height: 40, color: isDark ? Colors.white24 : Colors.black12),
                            _buildStatItem('PHASES', '${_phases.length}', LucideIcons.listTodo),
                          ],
                        ),
                      ),
                      const Spacer(),

                      // Close Button
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.voltCyan,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text('Back to Dashboard', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

            // Confetti Widget
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confetti,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: const [AppColors.voltCyan, AppColors.solarAmber, AppColors.pulseRed, AppColors.green],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}
