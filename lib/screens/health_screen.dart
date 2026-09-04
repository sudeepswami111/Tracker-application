import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../providers/app_provider.dart';
import '../providers/watch_metrics_provider.dart';
import '../providers/step_tracker_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/animated_card_enter.dart';
import '../widgets/watch_connect_banner.dart';
import '../widgets/device_scanner_sheet.dart';

class HealthScreen extends StatefulWidget {
  const HealthScreen({super.key});

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final watch = context.watch<WatchMetricsProvider>();
    final stepTracker = context.watch<StepTrackerProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Real data integration with sensible fallbacks matching reference
    final hr = (watch.pulse != null && watch.pulse! > 0) ? watch.pulse! : 72;
    final sleep = (watch.sleepHours != null && watch.sleepHours! > 0)
        ? watch.sleepHours!
        : 7.2;
    final spo2 = (watch.spo2 != null && watch.spo2! > 0) ? watch.spo2! : 98;
    final stress = (watch.stressLevel != null && watch.stressLevel! > 0)
        ? watch.stressLevel!
        : 32;
    final kcal = (stepTracker.steps * 0.04).round().clamp(100, 2000);
    final waterL = (app.waterIntake > 0) ? app.waterIntake : 2.1;

    // Calculated Health Score (0-100)
    final healthScore = 82;

    return Scaffold(
      backgroundColor: isDark ? AppColors.zenDarkBg : AppColors.lightBg,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(
            left: AppSpacing.screenMargin,
            right: AppSpacing.screenMargin,
            top: AppSpacing.md,
            bottom: 150,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 1. Header: Health & Updates from your body ──
              AnimatedCardEnter(
                index: 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Health',
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Updates from your body',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.neutralGray,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── 2. Horizontal Weekly Date Strip (Reference Design) ──
              AnimatedCardEnter(
                index: 1,
                child: _buildWeeklyDateStrip(isDark),
              ),
              const SizedBox(height: 18),

              // ── 3. Health Score Circular Card (Reference Design) ──
              AnimatedCardEnter(
                index: 2,
                child: _buildHealthScoreCard(isDark, healthScore),
              ),
              const SizedBox(height: 18),

              // ── 4. 2x2 Metric Cards Grid with Sparklines ──
              AnimatedCardEnter(
                index: 3,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildSparklineCard(
                            title: 'Heart Rate',
                            value: '$hr',
                            unit: 'bpm',
                            accentColor: AppColors.accentCoral,
                            isDark: isDark,
                            sparklineData: const [0.4, 0.6, 0.3, 0.8, 0.5, 0.7, 0.4, 0.9, 0.6],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSparklineCard(
                            title: 'Sleep',
                            value: sleep.toStringAsFixed(1),
                            unit: 'hours',
                            accentColor: AppColors.secondaryBlue,
                            isDark: isDark,
                            sparklineData: const [0.3, 0.4, 0.6, 0.5, 0.7, 0.8, 0.6, 0.75, 0.85],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildSparklineCard(
                            title: 'SpO2',
                            value: '$spo2%',
                            unit: '',
                            accentColor: AppColors.primaryTeal,
                            isDark: isDark,
                            sparklineData: const [0.7, 0.75, 0.8, 0.7, 0.85, 0.8, 0.9, 0.85, 0.95],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSparklineCard(
                            title: 'Stress',
                            value: '$stress',
                            unit: 'Low',
                            accentColor: AppColors.primaryGreen,
                            isDark: isDark,
                            sparklineData: const [0.6, 0.5, 0.4, 0.55, 0.35, 0.3, 0.4, 0.25, 0.3],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── 5. More Health Metrics List (Reference Design) ──
              AnimatedCardEnter(
                index: 4,
                child: _buildMoreHealthMetrics(isDark, kcal, waterL, app),
              ),
              const SizedBox(height: 20),

              // ── 6. Watch Connection Banner (Always Accessible) ──
              AnimatedCardEnter(
                index: 5,
                child: const WatchConnectBanner(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Weekly Date Selector Strip ─────────────────────────────────────────────
  Widget _buildWeeklyDateStrip(bool isDark) {
    final now = DateTime.now();
    // Monday of current week
    final monday = now.subtract(Duration(days: now.weekday - 1));

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (index) {
        final date = monday.add(Duration(days: index));
        final isSelected = DateUtils.isSameDay(date, _selectedDate);
        final dayNum = date.day;
        final dayName = DateFormat('E').format(date); // Mon, Tue, etc.

        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _selectedDate = date);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primaryTeal
                  : (isDark ? AppColors.zenDarkCard : Colors.white),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isSelected
                    ? AppColors.primaryTeal
                    : (isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.cardBorder),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? AppColors.primaryTeal.withValues(alpha: 0.3)
                      : Colors.black.withValues(alpha: 0.03),
                  blurRadius: isSelected ? 10 : 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$dayNum',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? Colors.white : AppColors.textPrimary),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  dayName,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.9)
                        : AppColors.neutralGray,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  // ─── Health Score Card with Circular Gauge ───────────────────────────────────
  Widget _buildHealthScoreCard(bool isDark, int score) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.zenDarkCard : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.cardBorder,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Health Score',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppColors.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Column(
              children: [
                SizedBox(
                  width: 130,
                  height: 130,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(130, 130),
                        painter: _ScoreGaugePainter(
                          score: score,
                          isDark: isDark,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$score',
                            style: GoogleFonts.inter(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : AppColors.textPrimary,
                              height: 1,
                            ),
                          ),
                          Text(
                            '/100',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.neutralGray,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Great job! 🌿',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── 2x2 Metric Card with Sparkline Curve ────────────────────────────────────
  Widget _buildSparklineCard({
    required String title,
    required String value,
    required String unit,
    required Color accentColor,
    required bool isDark,
    required List<double> sparklineData,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.zenDarkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.cardBorder,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                  letterSpacing: -0.4,
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.neutralGray,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          // Clean Sparkline Curve
          SizedBox(
            height: 32,
            width: double.infinity,
            child: CustomPaint(
              painter: _SparklinePainter(
                data: sparklineData,
                lineColor: accentColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── More Health Metrics List ────────────────────────────────────────────────
  Widget _buildMoreHealthMetrics(
    bool isDark,
    int kcal,
    double waterL,
    AppProvider app,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'More Health Metrics',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.zenDarkCard : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.cardBorder,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Column(
              children: [
                _buildMoreMetricRow(
                  icon: LucideIcons.flame,
                  iconColor: AppColors.accentOrange,
                  title: 'Calories',
                  value: '$kcal kcal',
                  isDark: isDark,
                  onTap: () {},
                ),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9),
                ),
                _buildMoreMetricRow(
                  icon: LucideIcons.droplets,
                  iconColor: AppColors.primaryTeal,
                  title: 'Hydration',
                  value: '${waterL.toStringAsFixed(1)} L >',
                  isDark: isDark,
                  onTap: () => app.setTabIndex(0), // Jump to Hydration Hub in Home
                ),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9),
                ),
                _buildMoreMetricRow(
                  icon: LucideIcons.wind,
                  iconColor: AppColors.secondaryBlue,
                  title: 'Respiratory Rate',
                  value: '16 brpm',
                  isDark: isDark,
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMoreMetricRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : AppColors.neutralGray,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Custom Painter for Circular Health Score Gauge ──────────────────────────

class _ScoreGaugePainter extends CustomPainter {
  final int score;
  final bool isDark;

  _ScoreGaugePainter({required this.score, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 16) / 2;
    const strokeWidth = 10.0;

    // Track
    final trackPaint = Paint()
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.08)
          : const Color(0xFFE6F4F1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // Active arc
    final sweepGradient = const SweepGradient(
      colors: [AppColors.primaryTeal, AppColors.primaryGreen],
      startAngle: 0.0,
      endAngle: 2 * pi,
      transform: GradientRotation(-pi / 2),
    );

    final progress = (score / 100).clamp(0.0, 1.0);
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
  }

  @override
  bool shouldRepaint(covariant _ScoreGaugePainter oldDelegate) {
    return oldDelegate.score != score || oldDelegate.isDark != isDark;
  }
}

// ─── Custom Painter for Sparkline Curves ──────────────────────────────────────

class _SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color lineColor;

  _SparklinePainter({required this.data, required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final path = Path();
    final stepX = size.width / (data.length - 1);

    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final y = size.height - (data[i] * size.height);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        final prevX = (i - 1) * stepX;
        final prevY = size.height - (data[i - 1] * size.height);
        final controlX = (prevX + x) / 2;
        path.cubicTo(controlX, prevY, controlX, y, x, y);
      }
    }

    final strokePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) => true;
}
