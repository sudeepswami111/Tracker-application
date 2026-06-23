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
import '../providers/workout_session_provider.dart';

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
  List<int> _phaseRemainingSeconds = [];
  List<bool> _phaseCompleted = [];
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

    _phaseRemainingSeconds = widget.phases
        .map((p) => p.durationMinutes * 60)
        .toList();
    _phaseCompleted = List.generate(widget.phases.length, (_) => false);

    // Initialize audio coach
    AudioCoachService().initialize().then((_) {
      if (mounted) {
        debugPrint('Session started with phases: ${_phases.length}');
        debugPrint('Current phase index: 0');
        debugPrint('Phase started: ${_phases[0].title}');
        AudioCoachService().announcePhase(_phases[_currentPhaseIndex].title);
      }
    });

    _currentPhaseIndex = 0;
    _startCurrentPhase();
  }

  void _startCurrentPhase() {
    final phase = _phases[_currentPhaseIndex];
    if (_currentPhaseIndex > 0) {
      debugPrint('Phase started: ${phase.title}');
    }

    setState(() {
      _isRunning = true;
    });

    // Notify WorkoutSessionProvider
    try {
      context.read<WorkoutSessionProvider>().updateCurrentPhase(_currentPhaseIndex);
    } catch (e) {
      debugPrint('[GuidedWorkoutSessionScreen] Provider update error: $e');
    }

    HapticFeedback.mediumImpact();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _onTick();
    });
  }

  void _onTick() {
    if (!_isRunning) return;
    if (!mounted) return;

    setState(() {
      if (_phaseRemainingSeconds[_currentPhaseIndex] > 0) {
        _phaseRemainingSeconds[_currentPhaseIndex]--;
        _totalElapsedSeconds++;
      }

      if (_phaseRemainingSeconds[_currentPhaseIndex] <= 0) {
        _phaseCompleted[_currentPhaseIndex] = true;
        debugPrint('Phase completed: ${_phases[_currentPhaseIndex].title}');
        
        // Notify provider
        try {
          context.read<WorkoutSessionProvider>().markPhaseCompleted(_currentPhaseIndex, true);
        } catch (_) {}
      }
    });

    if (_phaseRemainingSeconds[_currentPhaseIndex] <= 0) {
      _goToNextPhase(autoAdvance: true);
    }
  }

  void _goToNextPhase({bool autoAdvance = false}) {
    _timer?.cancel();

    if (_currentPhaseIndex < _phases.length - 1) {
      if (autoAdvance) {
        debugPrint('Auto moving to phase: ${_phases[_currentPhaseIndex + 1].title}');
      } else {
        debugPrint('Manual next pressed');
      }
      setState(() {
        _phaseCompleted[_currentPhaseIndex] = true;
        
        // Notify provider
        try {
          context.read<WorkoutSessionProvider>().markPhaseCompleted(_currentPhaseIndex, true);
        } catch (_) {}

        _currentPhaseIndex++;
      });

      _startCurrentPhase();
      AudioCoachService().announcePhase(_phases[_currentPhaseIndex].title);
    } else {
      _finishWorkout();
    }
  }

  void _goToPreviousPhase() {
    if (_currentPhaseIndex > 0) {
      debugPrint('Manual previous pressed');
      _timer?.cancel();
      setState(() {
        _currentPhaseIndex--;
        _isRunning = true;
        // Recommended behavior: restore full duration when manually going back
        _phaseRemainingSeconds[_currentPhaseIndex] = _phases[_currentPhaseIndex].durationMinutes * 60;
        _phaseCompleted[_currentPhaseIndex] = false;

        // Notify provider
        try {
          context.read<WorkoutSessionProvider>().updateCurrentPhase(_currentPhaseIndex);
          context.read<WorkoutSessionProvider>().markPhaseCompleted(_currentPhaseIndex, false);
        } catch (_) {}
      });

      HapticFeedback.mediumImpact();
      AudioCoachService().announcePhase(_phases[_currentPhaseIndex].title);
      debugPrint('Phase started: ${_phases[_currentPhaseIndex].title}');
      _startTimer();
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

  void _showStopConfirmationDialog() {
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
  }

  void _finishWorkout() {
    debugPrint('Workout completed');
    _timer?.cancel();
    HapticFeedback.vibrate();
    AudioCoachService().announceWorkoutCompleted();

    // Mark all phases as completed in provider
    try {
      final session = context.read<WorkoutSessionProvider>();
      for (int i = 0; i < _phases.length; i++) {
        session.markPhaseCompleted(i, true);
      }
      session.completeSession();
    } catch (_) {}

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
        ? (1.0 - (_phaseRemainingSeconds[_currentPhaseIndex] / phaseTotalSeconds)).clamp(0.0, 1.0)
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
                    // Phase timeline indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_phases.length, (idx) {
                        final isCompleted = _phaseCompleted[idx];
                        final isActive = idx == _currentPhaseIndex;
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _phases[idx].shortTitle,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                                color: isActive
                                    ? AppColors.voltCyan
                                    : (isCompleted ? AppColors.teal : AppColors.textSecondary.withValues(alpha: 0.5)),
                              ),
                            ),
                            if (idx < _phases.length - 1)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Icon(
                                  LucideIcons.chevronRight,
                                  size: 12,
                                  color: AppColors.textSecondary.withValues(alpha: 0.3),
                                ),
                              ),
                          ],
                        );
                      }),
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
                              Text(
                                'PHASE ${_currentPhaseIndex + 1} OF ${_phases.length}'.toUpperCase(),
                                style: const TextStyle(
                                  color: AppColors.voltCyan,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 6),
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
                                _fmtSecs(_phaseRemainingSeconds[_currentPhaseIndex]),
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

                    // Phase Previews (Previous & Next)
                    if (_currentPhaseIndex > 0 || nextPhase != null)
                      Row(
                        children: [
                          if (_currentPhaseIndex > 0)
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.02),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.04),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('PREVIOUS PHASE', style: TextStyle(color: AppColors.textSecondary, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                                    const SizedBox(height: 2),
                                    Text(_phases[_currentPhaseIndex - 1].title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 12)),
                                  ],
                                ),
                              ),
                            )
                          else
                            const Spacer(),

                          if (_currentPhaseIndex > 0 && nextPhase != null) const SizedBox(width: 12),

                          if (nextPhase != null)
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.03),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('NEXT PHASE', style: TextStyle(color: AppColors.textSecondary, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                                    const SizedBox(height: 2),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(child: Text(nextPhase.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12))),
                                        Text('${nextPhase.durationMinutes}m', style: const TextStyle(color: AppColors.voltCyan, fontWeight: FontWeight.bold, fontSize: 11)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else if (_currentPhaseIndex > 0) // if last phase, show next phase as finish
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.green.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.green.withValues(alpha: 0.15)),
                                ),
                                child: const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('NEXT PHASE', style: TextStyle(color: AppColors.green, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                                    SizedBox(height: 2),
                                    Text('Finish workout', style: TextStyle(color: AppColors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                                  ],
                                ),
                              ),
                            )
                          else
                            const Spacer(),
                        ],
                      ),
                    const Spacer(),

                    // Play/Pause, Skip, End Action controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Previous Button
                        SizedBox(
                          width: 110,
                          height: 54,
                          child: ElevatedButton.icon(
                            onPressed: _currentPhaseIndex > 0 ? _goToPreviousPhase : null,
                            icon: const Icon(LucideIcons.skipBack, size: 16),
                            label: const Text('Prev', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                              foregroundColor: AppColors.textPrimary,
                              disabledBackgroundColor: Colors.transparent,
                              disabledForegroundColor: AppColors.textSecondary.withValues(alpha: 0.3),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              elevation: 0,
                            ),
                          ),
                        ),

                        // Play/Pause Button
                        IconButton(
                          icon: Icon(_isRunning ? LucideIcons.pause : LucideIcons.play),
                          onPressed: _togglePlayPause,
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.voltCyan,
                            foregroundColor: Colors.black,
                            minimumSize: const Size(72, 72),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          ),
                        ),

                        // Skip/Next/Finish Button
                        SizedBox(
                          width: 110,
                          height: 54,
                          child: ElevatedButton.icon(
                            onPressed: _skipPhase,
                            icon: Icon(nextPhase == null ? LucideIcons.check : LucideIcons.skipForward, size: 16),
                            label: Text(nextPhase == null ? 'Finish' : 'Next', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.voltCyan,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Stop Session Button
                    TextButton.icon(
                      onPressed: _showStopConfirmationDialog,
                      icon: const Icon(LucideIcons.square, size: 14, color: AppColors.pulseRed),
                      label: const Text('Stop Workout', style: TextStyle(color: AppColors.pulseRed, fontWeight: FontWeight.bold, fontSize: 13)),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        backgroundColor: AppColors.pulseRed.withValues(alpha: 0.08),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
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
                          onPressed: () {
                            try {
                              context.read<WorkoutSessionProvider>().resetSession();
                            } catch (_) {}
                            Navigator.pop(context);
                          },
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
