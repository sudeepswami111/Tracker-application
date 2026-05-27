import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class UnifiedActivityCard extends StatelessWidget {
  final int steps;
  final int stepGoal;
  final int activeMinutes;
  final int heartRate;
  final double sleepDuration;
  final bool isHealthDataAvailable;

  const UnifiedActivityCard({
    super.key,
    required this.steps,
    required this.stepGoal,
    required this.activeMinutes,
    required this.heartRate,
    required this.sleepDuration,
    this.isHealthDataAvailable = false,
  });

  String _getStatusText(double progress) {
    if (progress < 0.3) return "Let's get moving";
    if (progress < 0.7) return "Good progress";
    if (progress < 1.0) return "Almost there";
    return "Goal completed";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final double rawProgress = stepGoal > 0 ? steps / stepGoal : 0.0;
    final double progress = rawProgress.clamp(0.0, 1.0);
    final int percentage = (progress * 100).toInt();
    final statusText = _getStatusText(progress);

    final trackColor = isDark ? AppColors.surfaceElevated : AppColors.lightSurfaceContainer;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceCard.withValues(alpha: 0.6) : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.06),
          width: 1,
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(LucideIcons.footprints, color: AppColors.voltCyan, size: 16),
                        const SizedBox(width: 8),
                        Text("Today's Activity", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          steps.toString(),
                          style: theme.textTheme.displayMedium?.copyWith(fontWeight: FontWeight.bold, height: 1),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'steps',
                          style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Goal $stepGoal',
                      style: theme.textTheme.labelMedium?.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.voltCyan.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        statusText,
                        style: theme.textTheme.labelSmall?.copyWith(color: AppColors.voltCyan, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 80,
                width: 80,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: progress),
                      duration: const Duration(milliseconds: 1200),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return CustomPaint(
                          size: const Size(80, 80),
                          painter: _RingPainter(
                            progress: value,
                            activeColor: AppColors.voltCyan,
                            backgroundColor: trackColor,
                            strokeWidth: 8,
                          ),
                        );
                      },
                    ),
                    Text(
                      '$percentage%',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05), height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              if (isHealthDataAvailable)
                _buildMiniMetric(
                  icon: LucideIcons.heartPulse,
                  label: 'Heart Rate',
                  value: heartRate > 0 ? '$heartRate bpm' : '---',
                  color: AppColors.pulseRed,
                  theme: theme,
                ),
              _buildMiniMetric(
                icon: LucideIcons.activity,
                label: 'Active',
                value: activeMinutes > 0 ? '${activeMinutes}m' : '---',
                color: AppColors.voltCyan,
                theme: theme,
              ),
              if (isHealthDataAvailable)
                _buildMiniMetric(
                  icon: LucideIcons.moon,
                  label: 'Sleep',
                  value: sleepDuration > 0 ? '${sleepDuration.toStringAsFixed(1)}h' : '---',
                  color: AppColors.irisViolet,
                  theme: theme,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMetric({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required ThemeData theme,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(color: AppColors.textSecondary, fontSize: 10),
            ),
            Text(
              value,
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color activeColor;
  final Color backgroundColor;
  final double strokeWidth;

  _RingPainter({
    required this.progress,
    required this.activeColor,
    required this.backgroundColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,
      2 * pi,
      false,
      bgPaint,
    );

    if (progress > 0.001) {
      final activePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          colors: [
            activeColor.withValues(alpha: 0.5),
            activeColor,
          ],
          startAngle: 0.0,
          endAngle: 2 * pi * progress,
          transform: const GradientRotation(-pi / 2),
        ).createShader(Rect.fromCircle(center: center, radius: radius));

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        2 * pi * progress,
        false,
        activePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}
