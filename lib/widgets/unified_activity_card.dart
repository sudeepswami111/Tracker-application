import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class UnifiedActivityCard extends StatefulWidget {
  final int steps;
  final int stepGoal;
  final int activeMinutes;
  final int heartRate;
  final double sleepDuration;
  final bool showHealthMetrics;

  const UnifiedActivityCard({
    super.key,
    required this.steps,
    required this.stepGoal,
    required this.activeMinutes,
    required this.heartRate,
    required this.sleepDuration,
    this.showHealthMetrics = true,
  });

  @override
  State<UnifiedActivityCard> createState() => _UnifiedActivityCardState();
}

class _UnifiedActivityCardState extends State<UnifiedActivityCard>
    with TickerProviderStateMixin {
  late AnimationController _ringController;
  late AnimationController _pulseController;
  late AnimationController _shimmerController;
  late Animation<double> _ringAnim;
  late Animation<double> _pulseAnim;
  late Animation<double> _shimmerAnim;

  @override
  void initState() {
    super.initState();
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    _ringAnim = CurvedAnimation(parent: _ringController, curve: Curves.easeOutCubic);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _shimmerAnim = Tween<double>(begin: -1.0, end: 2.0).animate(_shimmerController);

    _ringController.forward();
  }

  @override
  void didUpdateWidget(UnifiedActivityCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.steps != widget.steps) {
      _ringController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ringController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  String _statusLabel(double p) {
    if (p < 0.3) return "GET MOVING";
    if (p < 0.6) return "IN PROGRESS";
    if (p < 1.0) return "ALMOST THERE";
    return "GOAL CRUSHED";
  }

  Color _statusColor(double p) {
    if (p < 0.3) return const Color(0xFFFF6B6B);
    if (p < 0.6) return const Color(0xFFF59E0B);
    if (p < 1.0) return AppColors.voltCyan;
    return const Color(0xFF22C55E);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final double progress = (widget.stepGoal > 0
            ? widget.steps / widget.stepGoal
            : 0.0)
        .clamp(0.0, 1.0);
    final int pct = (progress * 100).toInt();
    final statusLabel = _statusLabel(progress);
    final statusColor = _statusColor(progress);

    // Effective HR — fallback to 72 if no data
    final int hr =
        (widget.showHealthMetrics && widget.heartRate > 0) ? widget.heartRate : 72;
    final double sleep = (widget.showHealthMetrics && widget.sleepDuration > 0)
        ? widget.sleepDuration
        : 7.5;
    final String activeStr = widget.activeMinutes > 0
        ? '${widget.activeMinutes}m'
        : '--';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: isDark
            ? const LinearGradient(
                colors: [Color(0xFF0F1729), Color(0xFF0A1020)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [Color(0xFFF8FAFF), Color(0xFFEEF2FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        border: Border.all(
          color: isDark
              ? AppColors.voltCyan.withValues(alpha: 0.15)
              : AppColors.voltCyan.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.voltCyan.withValues(alpha: isDark ? 0.07 : 0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // ── Background grid lines ──
            Positioned.fill(child: _GridLines(isDark: isDark)),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Header ──
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.voltCyan.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.voltCyan.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: AppColors.voltCyan,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.voltCyan.withValues(alpha: 0.8),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'LIVE ACTIVITY',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.5,
                                color: AppColors.voltCyan,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      _AnimatedStatusBadge(
                        label: statusLabel,
                        color: statusColor,
                        shimmerAnim: _shimmerAnim,
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── Central Orbital Ring + Steps ──
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Orbital rings
                      AnimatedBuilder(
                        animation: Listenable.merge([_ringAnim, _pulseAnim]),
                        builder: (context, _) {
                          return SizedBox(
                            width: 120,
                            height: 120,
                            child: CustomPaint(
                              painter: _OrbitalRingPainter(
                                progress: _ringAnim.value * progress,
                                pulse: _pulseAnim.value,
                                isDark: isDark,
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '$pct',
                                      style: GoogleFonts.inter(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w900,
                                        color: isDark ? Colors.white : Colors.black,
                                        height: 1,
                                      ),
                                    ),
                                    Text(
                                      '%',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.voltCyan,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(width: 20),

                      // Steps counter + goal bar
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TODAY\'S STEPS',
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.8,
                                color: isDark
                                    ? Colors.white38
                                    : Colors.black38,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Odometer-style rolling number
                            AnimatedBuilder(
                              animation: _shimmerAnim,
                              builder: (context, _) {
                                return ShaderMask(
                                  shaderCallback: (bounds) => LinearGradient(
                                    colors: [
                                      isDark ? Colors.white : Colors.black87,
                                      AppColors.voltCyan,
                                      isDark ? Colors.white : Colors.black87,
                                    ],
                                    stops: [
                                      (_shimmerAnim.value - 0.3).clamp(0.0, 1.0),
                                      _shimmerAnim.value.clamp(0.0, 1.0),
                                      (_shimmerAnim.value + 0.3).clamp(0.0, 1.0),
                                    ],
                                  ).createShader(bounds),
                                  child: _RollingNumber(
                                    value: widget.steps,
                                    fontSize: 36,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'of ${widget.stepGoal} goal',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: isDark ? Colors.white38 : Colors.black38,
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Progress bar
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: AnimatedBuilder(
                                animation: _ringAnim,
                                builder: (context, _) {
                                  return LinearProgressIndicator(
                                    value: _ringAnim.value * progress,
                                    minHeight: 6,
                                    backgroundColor: isDark
                                        ? Colors.white.withValues(alpha: 0.08)
                                        : Colors.black.withValues(alpha: 0.08),
                                    valueColor: AlwaysStoppedAnimation(
                                      AppColors.voltCyan,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // ── Metric Pods ──
                  Row(
                    children: [
                      Expanded(
                        child: _MetricPod(
                          value: '$hr',
                          unit: 'bpm',
                          label: 'Heart Rate',
                          color: const Color(0xFFFF4D6D),
                          icon: '❤️',
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MetricPod(
                          value: activeStr,
                          unit: 'active',
                          label: 'Move Time',
                          color: AppColors.voltCyan,
                          icon: '⚡',
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MetricPod(
                          value: sleep.toStringAsFixed(1),
                          unit: 'hrs',
                          label: 'Sleep',
                          color: const Color(0xFF818CF8),
                          icon: '🌙',
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Animated status badge with shimmer ──
class _AnimatedStatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Animation<double> shimmerAnim;

  const _AnimatedStatusBadge({
    required this.label,
    required this.color,
    required this.shimmerAnim,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: shimmerAnim,
      builder: (context, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: color,
            ),
          ),
        );
      },
    );
  }
}

// ── Metric pod tile ──
class _MetricPod extends StatelessWidget {
  final String value;
  final String unit;
  final String label;
  final Color color;
  final String icon;
  final bool isDark;

  const _MetricPod({
    required this.value,
    required this.unit,
    required this.label,
    required this.color,
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: isDark
            ? color.withValues(alpha: 0.07)
            : color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.2 : 0.25),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: color,
                    height: 1,
                  ),
                ),
                TextSpan(
                  text: ' $unit',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    color: color.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Subtle background grid ──
class _GridLines extends StatelessWidget {
  final bool isDark;
  const _GridLines({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _GridPainter(isDark: isDark));
  }
}

class _GridPainter extends CustomPainter {
  final bool isDark;
  _GridPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.025)
          : Colors.black.withValues(alpha: 0.03)
      ..strokeWidth = 0.5;

    const spacing = 28.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}

// ── Orbital ring painter with outer + inner glow ──
class _OrbitalRingPainter extends CustomPainter {
  final double progress;
  final double pulse;
  final bool isDark;

  _OrbitalRingPainter({
    required this.progress,
    required this.pulse,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // ── Outer ring track ──
    final trackPaint = Paint()
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.06)
          : Colors.black.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, 52, trackPaint);

    // ── Outer progress arc (neon glow) ──
    if (progress > 0.001) {
      // Glow layer
      final glowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6)
        ..color = AppColors.voltCyan.withValues(alpha: 0.35 * pulse);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: 52),
        -pi / 2,
        2 * pi * progress,
        false,
        glowPaint,
      );

      // Sharp arc
      final arcPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          colors: [
            AppColors.voltCyan.withValues(alpha: 0.4),
            AppColors.voltCyan,
          ],
          startAngle: 0.0,
          endAngle: 2 * pi * progress,
          transform: const GradientRotation(-pi / 2),
        ).createShader(Rect.fromCircle(center: center, radius: 52));
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: 52),
        -pi / 2,
        2 * pi * progress,
        false,
        arcPaint,
      );

      // ── Arc end dot ──
      final angle = -pi / 2 + 2 * pi * progress;
      final dotPos = Offset(
        center.dx + 52 * cos(angle),
        center.dy + 52 * sin(angle),
      );
      canvas.drawCircle(
        dotPos,
        5,
        Paint()
          ..color = AppColors.voltCyan
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.drawCircle(
        dotPos,
        3.5,
        Paint()..color = Colors.white,
      );
    }

    // ── Inner dashed ring (decorative) ──
    final dashPaint = Paint()
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.05)
          : Colors.black.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    const dashCount = 24;
    for (int i = 0; i < dashCount; i++) {
      final startAngle = (2 * pi / dashCount) * i;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: 36),
        startAngle,
        pi / dashCount * 0.6,
        false,
        dashPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _OrbitalRingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.pulse != pulse ||
      oldDelegate.isDark != isDark;
}

// ── Odometer-style rolling number ──────────────────────────────────────────

/// Renders each digit in a vertically scrolling column, like a slot machine.
/// Only the digits that change animate; stable digits stay still.
class _RollingNumber extends StatelessWidget {
  final int value;
  final double fontSize;
  final FontWeight fontWeight;
  final Color color;

  const _RollingNumber({
    required this.value,
    required this.fontSize,
    required this.fontWeight,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final digits = value.toString().split('');
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: digits.map((d) {
        return _RollingDigit(
          digit: int.parse(d),
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
        );
      }).toList(),
    );
  }
}

/// A single digit that animates vertically between 0–9 like an odometer.
class _RollingDigit extends StatefulWidget {
  final int digit;
  final double fontSize;
  final FontWeight fontWeight;
  final Color color;

  const _RollingDigit({
    required this.digit,
    required this.fontSize,
    required this.fontWeight,
    required this.color,
  });

  @override
  State<_RollingDigit> createState() => _RollingDigitState();
}

class _RollingDigitState extends State<_RollingDigit>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  int _oldDigit = 0;

  @override
  void initState() {
    super.initState();
    _oldDigit = widget.digit;
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
  }

  @override
  void didUpdateWidget(_RollingDigit old) {
    super.didUpdateWidget(old);
    if (old.digit != widget.digit) {
      _oldDigit = old.digit;
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.fontSize * 1.15;
    return SizedBox(
      height: h,
      child: ClipRect(
        child: AnimatedBuilder(
          animation: _anim,
          builder: (context, _) {
            // Animate from _oldDigit to widget.digit by sliding up
            final t = _anim.value;
            // offset: 0 = showing oldDigit, 1 = showing newDigit
            // We shift upward: negative dy means move up
            final dy = -t * h;

            return Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                // Old digit sliding out (moving up)
                Transform.translate(
                  offset: Offset(0, dy),
                  child: SizedBox(
                    height: h,
                    child: _digitText(_oldDigit, h),
                  ),
                ),
                // New digit sliding in (comes from below)
                Transform.translate(
                  offset: Offset(0, h + dy),
                  child: SizedBox(
                    height: h,
                    child: _digitText(widget.digit, h),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _digitText(int d, double h) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        '$d',
        style: GoogleFonts.inter(
          fontSize: widget.fontSize,
          fontWeight: widget.fontWeight,
          color: widget.color,
          height: 1.15,
        ),
      ),
    );
  }
}
