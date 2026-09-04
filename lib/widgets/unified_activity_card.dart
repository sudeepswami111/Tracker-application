import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_colors.dart';

class UnifiedActivityCard extends StatefulWidget {
  final int steps;
  final int stepGoal;
  final int activeMinutes;
  final int heartRate;
  final double sleepDuration;
  final int calories;
  final bool showHealthMetrics;

  const UnifiedActivityCard({
    super.key,
    required this.steps,
    required this.stepGoal,
    required this.activeMinutes,
    required this.heartRate,
    required this.sleepDuration,
    this.calories = 430,
    this.showHealthMetrics = true,
  });

  @override
  State<UnifiedActivityCard> createState() => _UnifiedActivityCardState();
}

class _UnifiedActivityCardState extends State<UnifiedActivityCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _progressAnim = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(UnifiedActivityCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.steps != widget.steps) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final double targetProgress = (widget.stepGoal > 0
            ? widget.steps / widget.stepGoal
            : 0.0)
        .clamp(0.0, 1.0);
    final int pct = (targetProgress * 100).toInt();

    // Effective metrics
    final int hr = (widget.showHealthMetrics && widget.heartRate > 0)
        ? widget.heartRate
        : 72;
    final double sleep = (widget.showHealthMetrics && widget.sleepDuration > 0)
        ? widget.sleepDuration
        : 7.2;
    final int activeMin = widget.activeMinutes > 0 ? widget.activeMinutes : 48;
    final int kcal = widget.calories > 0
        ? widget.calories
        : (widget.steps * 0.04).round().clamp(100, 2000);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppColors.zenDarkCard : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppColors.cardBorder,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.04),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: Column(
          children: [
            // ── 1. Large Circular Steps Component (Reference Design) ──
            AnimatedBuilder(
              animation: _progressAnim,
              builder: (context, _) {
                final currentProgress = _progressAnim.value * targetProgress;
                return SizedBox(
                  width: 210,
                  height: 210,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Custom Circular Arc Painter
                      CustomPaint(
                        size: const Size(210, 210),
                        painter: _StepsRingPainter(
                          progress: currentProgress,
                          isDark: isDark,
                        ),
                      ),
                      // Inner Content: Shoe Badge + Steps + Subtitle
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Top Shoe Badge Icon
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: AppColors.primaryTeal.withValues(alpha: 0.14),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              LucideIcons.footprints,
                              size: 16,
                              color: AppColors.primaryTeal,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Large Bold Number with Rolling Effect
                          _RollingNumber(
                            value: (_progressAnim.value * widget.steps).round(),
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : AppColors.textPrimary,
                          ),
                          Text(
                            'Steps',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '$pct% of ${widget.stepGoal} steps goal',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white38 : AppColors.neutralGray,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // ── 2. Hourly Step Activity Histogram ──
            _buildHourlyHistogram(isDark),

            const SizedBox(height: 20),

            // ── 3. Bottom 4 Mini Metric Pods (Heart Rate, Active Min, Sleep, Calories) ──
            Row(
              children: [
                Expanded(
                  child: _MiniMetricCard(
                    icon: LucideIcons.heart,
                    iconColor: AppColors.accentCoral,
                    bgColor: AppColors.accentCoral.withValues(alpha: 0.1),
                    value: '$hr',
                    unit: 'bpm',
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MiniMetricCard(
                    icon: LucideIcons.zap,
                    iconColor: AppColors.primaryTeal,
                    bgColor: AppColors.primaryTeal.withValues(alpha: 0.1),
                    value: '$activeMin',
                    unit: 'Active Min',
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MiniMetricCard(
                    icon: LucideIcons.moon,
                    iconColor: AppColors.secondaryBlue,
                    bgColor: AppColors.secondaryBlue.withValues(alpha: 0.1),
                    value: sleep.toStringAsFixed(1),
                    unit: 'Hours',
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MiniMetricCard(
                    icon: LucideIcons.flame,
                    iconColor: AppColors.accentOrange,
                    bgColor: AppColors.accentOrange.withValues(alpha: 0.1),
                    value: '$kcal',
                    unit: 'kcal',
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHourlyHistogram(bool isDark) {
    // Simulated realistic hourly step bars with dynamic peak around afternoon/now
    final List<double> barHeights = [
      0.15, 0.1, 0.05, 0.05, 0.08, 0.12,
      0.25, 0.45, 0.6, 0.75, 0.5, 0.65,
      0.85, 0.95, 1.0, 0.7, 0.4, 0.2,
      0.15, 0.1, 0.08, 0.05, 0.05, 0.05
    ];

    return Column(
      children: [
        SizedBox(
          height: 38,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(barHeights.length, (index) {
              final h = barHeights[index];
              final isCurrent = index == 14;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1.5),
                  child: Container(
                    height: 38 * h,
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? AppColors.primaryTeal
                          : (index < 14
                              ? AppColors.primaryTeal.withValues(alpha: 0.45)
                              : (isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : const Color(0xFFE2E8F0))),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('12 AM',
                style: GoogleFonts.inter(
                    fontSize: 9.5,
                    color: isDark ? Colors.white38 : AppColors.neutralGray)),
            Text('Morning',
                style: GoogleFonts.inter(
                    fontSize: 9.5,
                    color: isDark ? Colors.white38 : AppColors.neutralGray)),
            Text('Now',
                style: GoogleFonts.inter(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryTeal)),
            Text('12 AM',
                style: GoogleFonts.inter(
                    fontSize: 9.5,
                    color: isDark ? Colors.white38 : AppColors.neutralGray)),
          ],
        ),
      ],
    );
  }
}

// ─── Custom Painter for Large Circular Arc ────────────────────────────────────

class _StepsRingPainter extends CustomPainter {
  final double progress;
  final bool isDark;

  _StepsRingPainter({required this.progress, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 24) / 2;
    const strokeWidth = 14.0;

    // Background track
    final trackPaint = Paint()
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.06)
          : const Color(0xFFE6F4F1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    if (progress > 0.001) {
      // Gradient progress arc
      final sweepGradient = SweepGradient(
        colors: const [
          AppColors.primaryTeal,
          AppColors.primaryGreen,
        ],
        startAngle: 0.0,
        endAngle: 2 * pi * progress,
        transform: const GradientRotation(-pi / 2),
      );

      final arcPaint = Paint()
        ..shader = sweepGradient.createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        2 * pi * progress,
        false,
        arcPaint,
      );

      // Arc end dot indicator
      final angle = -pi / 2 + 2 * pi * progress;
      final dotPos = Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );

      canvas.drawCircle(
        dotPos,
        strokeWidth / 2,
        Paint()..color = AppColors.primaryGreen,
      );
      canvas.drawCircle(
        dotPos,
        strokeWidth / 4,
        Paint()..color = Colors.white,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StepsRingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isDark != isDark;
  }
}

// ─── Mini Metric Card Pod ─────────────────────────────────────────────────────

class _MiniMetricCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String value;
  final String unit;
  final bool isDark;

  const _MiniMetricCard({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.value,
    required this.unit,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B2B3E) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : AppColors.cardBorder,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 14, color: iconColor),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppColors.textPrimary,
              height: 1.1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            unit,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white54 : AppColors.neutralGray,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─── Rolling Number Widget ────────────────────────────────────────────────────

class _RollingNumber extends StatelessWidget {
  final int value;
  final double fontSize;
  final FontWeight fontWeight;
  final Color color;

  const _RollingNumber({
    required this.value,
    this.fontSize = 32,
    this.fontWeight = FontWeight.w900,
    this.color = Colors.white,
  });

  String _formatNumber(int n) {
    return n.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _formatNumber(value),
      style: GoogleFonts.inter(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: -0.5,
        height: 1.1,
      ),
    );
  }
}
