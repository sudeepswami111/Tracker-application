import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/watch_metrics_provider.dart';
import '../theme/app_colors.dart';
import 'glass_card.dart';

class WatchDashboard extends StatefulWidget {
  const WatchDashboard({super.key});

  @override
  State<WatchDashboard> createState() => _WatchDashboardState();
}

class _WatchDashboardState extends State<WatchDashboard>
    with TickerProviderStateMixin {
  late AnimationController _entryController;
  late AnimationController _pulseRingController;
  late AnimationController _glowController;

  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;
  late Animation<double> _pulseRingAnim;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeIn = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOut,
    );
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutCubic,
    ));

    _pulseRingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseRingAnim = CurvedAnimation(
      parent: _pulseRingController,
      curve: Curves.easeOutCubic,
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _entryController.forward();
    _pulseRingController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _pulseRingController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final watch = context.watch<WatchMetricsProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return FadeTransition(
      opacity: _fadeIn,
      child: SlideTransition(
        position: _slideUp,
        child: Column(
          children: [
            // ── Pulse Ring Card ──
            _buildPulseRingCard(watch, theme, isDark),
            const SizedBox(height: 16),

            // ── Heart Rate Card ──
            _buildHeartRateCard(watch, theme, isDark),
            const SizedBox(height: 16),

            // ── Vitals Grid ──
            Row(
              children: [
                Expanded(
                  child: _buildVitalMetricCard(
                    icon: LucideIcons.wind,
                    label: 'SpO₂',
                    value: '${watch.spO2.toStringAsFixed(0)}%',
                    color: AppColors.blue,
                    theme: theme,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildVitalMetricCard(
                    icon: LucideIcons.thermometer,
                    label: 'Temperature',
                    value: '${watch.temperature.toStringAsFixed(1)}°F',
                    color: AppColors.coral,
                    theme: theme,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildVitalMetricCard(
                    icon: LucideIcons.activity,
                    label: 'Blood Pressure',
                    value: '${watch.systolic}/${watch.diastolic}',
                    color: AppColors.pink,
                    theme: theme,
                    isDark: isDark,
                    subtitle: 'mmHg',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildVitalMetricCard(
                    icon: LucideIcons.moon,
                    label: 'Sleep',
                    value: '${watch.sleepHours.toStringAsFixed(1)}h',
                    color: AppColors.primary,
                    theme: theme,
                    isDark: isDark,
                    subtitle: 'last night',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Wellness Score Card ──
            _buildWellnessCard(watch, theme, isDark),
          ],
        ),
      ),
    );
  }

  // ── Pulse Ring Card ──
  Widget _buildPulseRingCard(
      WatchMetricsProvider watch, ThemeData theme, bool isDark) {
    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [
                      const Color(0xFF12162E),
                      const Color(0xFF1A1F3D),
                    ]
                  : [
                      const Color(0xFFF8F6FF),
                      const Color(0xFFF0EDFF),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.coral.withValues(alpha: _glowAnim.value * 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color:
                    AppColors.coral.withValues(alpha: _glowAnim.value * 0.15),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(LucideIcons.heartPulse,
                      size: 18, color: AppColors.coral),
                  const SizedBox(width: 8),
                  Text('Live Pulse',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      )),
                  const Spacer(),
                  if (watch.isStreaming)
                    _LiveBadge(glowAnim: _glowAnim),
                ],
              ),
              const SizedBox(height: 20),
              // Animated pulse ring
              AnimatedBuilder(
                animation: _pulseRingAnim,
                builder: (context, child) {
                  return SizedBox(
                    width: 160,
                    height: 160,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Glow ring background
                        AnimatedBuilder(
                          animation: _glowAnim,
                          builder: (context, _) {
                            return CustomPaint(
                              size: const Size(160, 160),
                              painter: _PulseRingPainter(
                                progress: (watch.pulse / 200)
                                        .clamp(0.0, 1.0) *
                                    _pulseRingAnim.value,
                                glowIntensity: _glowAnim.value,
                                color: AppColors.coral,
                                bgColor: isDark
                                    ? Colors.white.withValues(alpha: 0.06)
                                    : Colors.black.withValues(alpha: 0.06),
                              ),
                            );
                          },
                        ),
                        // Center text
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${watch.pulse}',
                                style: GoogleFonts.inter(
                                  fontSize: 44,
                                  fontWeight: FontWeight.w900,
                                  color: theme.colorScheme.onSurface,
                                  letterSpacing: -2,
                                ),
                              ),
                              Text(
                                'BPM',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onSurfaceVariant,
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Heart Rate Card ──
  Widget _buildHeartRateCard(
      WatchMetricsProvider watch, ThemeData theme, bool isDark) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Icon(LucideIcons.heart, size: 18, color: AppColors.coral),
                const SizedBox(width: 8),
                Text('Heart Rate', style: theme.textTheme.titleLarge),
              ]),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.coral.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('LIVE',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.coral,
                      fontWeight: FontWeight.w700,
                    )),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Icon(LucideIcons.heart, size: 28, color: AppColors.coral),
                const SizedBox(width: 8),
                Text('${watch.pulse}',
                    style: theme.textTheme.displayLarge
                        ?.copyWith(fontSize: 48)),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child:
                      Text('BPM', style: theme.textTheme.bodySmall),
                ),
              ]),
              Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                Text('Resting ${watch.restingHeartRate}',
                    style: theme.textTheme.bodySmall),
                Text('Max ${watch.maxHeartRate}',
                    style: theme.textTheme.bodySmall),
              ]),
            ],
          ),
          const SizedBox(height: 16),
          _zoneBar('Rest', '14h', AppColors.blue, 14 / 24, theme, isDark),
          _zoneBar(
              'Fat Burn', '6h', AppColors.green, 6 / 24, theme, isDark),
          _zoneBar('Cardio', '3h', AppColors.yellow, 3 / 24, theme, isDark),
          _zoneBar('Peak', '1h', AppColors.coral, 1 / 24, theme, isDark),
        ],
      ),
    );
  }

  Widget _zoneBar(String name, String time, Color color, double pct,
      ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        SizedBox(
          width: 55,
          child: Text(name,
              style: theme.textTheme.labelSmall?.copyWith(fontSize: 10)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.05),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 24,
          child: Text(time,
              style: theme.textTheme.labelSmall?.copyWith(fontSize: 10),
              textAlign: TextAlign.right),
        ),
      ]),
    );
  }

  // ── Vital Metric Card ──
  Widget _buildVitalMetricCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required ThemeData theme,
    required bool isDark,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfaceContainer.withValues(alpha: 0.6)
            : AppColors.lightSurface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 11,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 10,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Wellness Score Card ──
  Widget _buildWellnessCard(
      WatchMetricsProvider watch, ThemeData theme, bool isDark) {
    final score = watch.wellnessScore;
    Color scoreColor;
    String scoreLabel;
    if (score >= 80) {
      scoreColor = AppColors.green;
      scoreLabel = 'Excellent';
    } else if (score >= 60) {
      scoreColor = AppColors.yellow;
      scoreLabel = 'Good';
    } else if (score >= 40) {
      scoreColor = AppColors.orange;
      scoreLabel = 'Fair';
    } else {
      scoreColor = AppColors.coral;
      scoreLabel = 'Needs Attention';
    }

    return GlassCard(
      child: Column(
        children: [
          Row(children: [
            Icon(LucideIcons.activity, size: 18, color: AppColors.green),
            const SizedBox(width: 8),
            Text('Wellness Score', style: theme.textTheme.titleLarge),
          ]),
          const SizedBox(height: 20),
          Row(
            children: [
              // Animated score ring
              AnimatedBuilder(
                animation: _pulseRingAnim,
                builder: (context, _) {
                  return SizedBox(
                    width: 110,
                    height: 110,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 110,
                          height: 110,
                          child: CircularProgressIndicator(
                            value: (score / 100) * _pulseRingAnim.value,
                            strokeWidth: 10,
                            backgroundColor: isDark
                                ? Colors.white.withValues(alpha: 0.06)
                                : Colors.black.withValues(alpha: 0.06),
                            valueColor: AlwaysStoppedAnimation(scoreColor),
                            strokeCap: StrokeCap.round,
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$score',
                              style: GoogleFonts.inter(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              'Score',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color:
                                    theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: scoreColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        scoreLabel,
                        style: TextStyle(
                          color: scoreColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _wellnessMetric(
                      'Heart',
                      '${watch.pulse} BPM',
                      AppColors.coral,
                      watch.pulse > 0
                          ? (watch.pulse / 100).clamp(0.0, 1.0)
                          : 0.7,
                      theme,
                      isDark,
                    ),
                    const SizedBox(height: 8),
                    _wellnessMetric(
                      'SpO₂',
                      '${watch.spO2.toStringAsFixed(0)}%',
                      AppColors.blue,
                      watch.spO2 > 0 ? (watch.spO2 / 100) : 0.97,
                      theme,
                      isDark,
                    ),
                    const SizedBox(height: 8),
                    _wellnessMetric(
                      'Sleep',
                      '${watch.sleepHours.toStringAsFixed(1)}h',
                      AppColors.primary,
                      watch.sleepHours > 0
                          ? (watch.sleepHours / 10).clamp(0.0, 1.0)
                          : 0.72,
                      theme,
                      isDark,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _wellnessMetric(String label, String value, Color color,
      double progress, ThemeData theme, bool isDark) {
    return Row(
      children: [
        SizedBox(
          width: 40,
          child: Text(label,
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 11)),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.05),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(value,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 10,
            )),
      ],
    );
  }
}

// ── LIVE Badge with animated glow dot ──
class _LiveBadge extends StatelessWidget {
  final Animation<double> glowAnim;

  const _LiveBadge({required this.glowAnim});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: glowAnim,
      builder: (context, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.coral.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.coral
                  .withValues(alpha: glowAnim.value * 0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.coral
                    .withValues(alpha: glowAnim.value * 0.2),
                blurRadius: 8,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: AppColors.coral
                      .withValues(alpha: 0.5 + glowAnim.value * 0.5),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.coral
                          .withValues(alpha: glowAnim.value * 0.6),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'LIVE',
                style: TextStyle(
                  color: AppColors.coral,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Pulse Ring Custom Painter ──
class _PulseRingPainter extends CustomPainter {
  final double progress;
  final double glowIntensity;
  final Color color;
  final Color bgColor;

  _PulseRingPainter({
    required this.progress,
    required this.glowIntensity,
    required this.color,
    required this.bgColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 14) / 2;

    // Background ring
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..color = bgColor
        ..strokeCap = StrokeCap.round,
    );

    // Glow effect
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..color = color.withValues(alpha: glowIntensity * 0.15)
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    final sweepAngle = 2 * math.pi * progress;
    
    if (sweepAngle > 0.01) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        sweepAngle,
        false,
        glowPaint,
      );

      // Main progress arc with gradient
      final gradientShader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: -math.pi / 2 + sweepAngle,
        colors: [
          color,
          color.withValues(alpha: 0.7),
          color,
        ],
        stops: const [0.0, 0.5, 1.0],
        transform: const GradientRotation(-math.pi / 2),
      ).createShader(Rect.fromCircle(center: center, radius: radius));

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        sweepAngle,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 12
          ..shader = gradientShader
          ..strokeCap = StrokeCap.round,
      );

      // End-cap glow dot
      final endAngle = -math.pi / 2 + sweepAngle;
      final dotCenter = Offset(
        center.dx + radius * math.cos(endAngle),
        center.dy + radius * math.sin(endAngle),
      );
      canvas.drawCircle(
        dotCenter,
        7,
        Paint()..color = color.withValues(alpha: glowIntensity * 0.4),
      );
      canvas.drawCircle(
        dotCenter,
        4,
        Paint()..color = Colors.white,
      );
    }
  }

  @override
  bool shouldRepaint(_PulseRingPainter old) =>
      old.progress != progress || old.glowIntensity != glowIntensity;
}
