import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/workout_phase.dart';
import '../theme/app_colors.dart';

class WorkoutPhaseDetailsSheet extends StatelessWidget {
  final WorkoutPhase phase;
  final VoidCallback onStartWorkout;
  final bool showStartButton;

  const WorkoutPhaseDetailsSheet({
    super.key,
    required this.phase,
    required this.onStartWorkout,
    this.showStartButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceElevated.withValues(alpha: 0.9) : Colors.white.withValues(alpha: 0.9),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle / Pill
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Header (Icon & Title)
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.voltCyan.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    phase.icon,
                    color: AppColors.voltCyan,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        phase.title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${phase.durationMinutes} minutes',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.voltCyan,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.x),
                  onPressed: () => Navigator.pop(context),
                  style: IconButton.styleFrom(
                    backgroundColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Description Section
            Text(
              'Description',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              phase.description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),

            // Tips Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.voltCyan.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.voltCyan.withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    LucideIcons.sparkles,
                    color: AppColors.voltCyan,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Coach Tip',
                          style: TextStyle(
                            color: AppColors.voltCyan,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getTipForPhase(phase.title),
                          style: TextStyle(
                            color: isDark ? Colors.white.withValues(alpha: 0.87) : Colors.black.withValues(alpha: 0.87),
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Action Button
            if (showStartButton)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onStartWorkout();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.voltCyan,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.play_arrow, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Start Workout',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: BorderSide(
                      color: isDark ? Colors.white.withValues(alpha: 0.24) : Colors.black.withValues(alpha: 0.24),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  String _getTipForPhase(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('warm') || lower.contains('prep') || lower.contains('start') || lower.contains('mobility')) {
      return 'Start with light walking, dynamic stretching, and mobility work. Never jump straight into high intensity.';
    }
    if (lower.contains('cool') || lower.contains('relax') || lower.contains('reflection') || lower.contains('break')) {
      return 'Slow down, focus on cooling the body, deep breathing, and light static leg or core stretches.';
    }
    if (lower.contains('run') || lower.contains('treadmill')) {
      return 'Maintain a steady, rhythmic pace. Focus on landing softly and keeping your breathing relaxed.';
    }
    if (lower.contains('walk')) {
      return 'Keep a brisk, purposeful stride. Pump your arms gently to engage the whole body.';
    }
    if (lower.contains('cycle') || lower.contains('ride') || lower.contains('spin')) {
      return 'Keep a high pedal cadence (80-90 RPM). Sit comfortably and avoid tensing your shoulders.';
    }
    if (lower.contains('yoga') || lower.contains('stretch')) {
      return 'Focus on alignment and slow, steady breathing. Move through the postures mindfully.';
    }
    if (lower.contains('strength') || lower.contains('gym') || lower.contains('workout')) {
      return 'Prioritize form over weight. Focus on slow, controlled contractions and mind-muscle connection.';
    }
    if (lower.contains('swim')) {
      return 'Focus on streamlined body posture and long, smooth strokes to maximize glide.';
    }
    if (lower.contains('meditat')) {
      return 'Keep your spine straight but relaxed. Gently guide your attention back if your mind wanders.';
    }
    if (lower.contains('study') || lower.contains('deep')) {
      return 'Eliminate distractions. Keep a water bottle nearby and focus on one single task.';
    }
    return 'Listen to your body. Maintain steady breathing and focus on proper form.';
  }
}
