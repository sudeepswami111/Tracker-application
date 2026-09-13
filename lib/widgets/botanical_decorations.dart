import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

/// Botanical branch / leaves decoration used in the corners and quote cards
class BotanicalBranchPainter extends CustomPainter {
  final Color color;
  final double leafScale;

  BotanicalBranchPainter({
    this.color = const Color(0xFF5C946E),
    this.leafScale = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final stemPaint = Paint()
      ..color = color.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8 * leafScale
      ..strokeCap = StrokeCap.round;

    final leafPaint = Paint()
      ..color = color.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    // Stem path
    final stemPath = Path();
    stemPath.moveTo(size.width * 0.1, size.height * 0.95);
    stemPath.cubicTo(
      size.width * 0.35,
      size.height * 0.7,
      size.width * 0.55,
      size.height * 0.45,
      size.width * 0.85,
      size.height * 0.1,
    );
    canvas.drawPath(stemPath, stemPaint);

    // Leaves at various points along the stem
    _drawLeaf(canvas, leafPaint, Offset(size.width * 0.85, size.height * 0.1), -math.pi / 4, 18 * leafScale, 8 * leafScale);
    _drawLeaf(canvas, leafPaint, Offset(size.width * 0.65, size.height * 0.32), -math.pi / 3, 16 * leafScale, 7 * leafScale);
    _drawLeaf(canvas, leafPaint, Offset(size.width * 0.70, size.height * 0.30), math.pi / 8, 15 * leafScale, 6.5 * leafScale);
    _drawLeaf(canvas, leafPaint, Offset(size.width * 0.45, size.height * 0.56), -math.pi / 2.8, 17 * leafScale, 7.5 * leafScale);
    _drawLeaf(canvas, leafPaint, Offset(size.width * 0.50, size.height * 0.52), math.pi / 6, 16 * leafScale, 7 * leafScale);
    _drawLeaf(canvas, leafPaint, Offset(size.width * 0.28, size.height * 0.78), -math.pi / 2.5, 15 * leafScale, 6.5 * leafScale);
    _drawLeaf(canvas, leafPaint, Offset(size.width * 0.32, size.height * 0.75), math.pi / 5, 14 * leafScale, 6 * leafScale);
  }

  void _drawLeaf(Canvas canvas, Paint paint, Offset center, double angle, double length, double width) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);

    final path = Path();
    path.moveTo(0, 0);
    path.quadraticBezierTo(length * 0.5, -width, length, 0);
    path.quadraticBezierTo(length * 0.5, width, 0, 0);
    path.close();

    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant BotanicalBranchPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.leafScale != leafScale;
}

/// Botanical Leaf Icon / Emblem
class BotanicalLeafIcon extends StatelessWidget {
  final double size;
  final Color color;

  const BotanicalLeafIcon({
    super.key,
    this.size = 28,
    this.color = AppColors.sageGreen,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: BotanicalBranchPainter(color: color, leafScale: size / 40),
      ),
    );
  }
}

/// Segmented Pill Tab Bar used across Steps, Running, Health, Milestones, Study
class SegmentedPillTabs extends StatelessWidget {
  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final Color activeBgColor;
  final Color activeTextColor;
  final Color inactiveTextColor;

  const SegmentedPillTabs({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabSelected,
    this.activeBgColor = AppColors.forestGreen,
    this.activeTextColor = Colors.white,
    this.inactiveTextColor = AppColors.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF0EBE0),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(tabs.length, (index) {
          final isSelected = index == selectedIndex;
          return GestureDetector(
            onTap: () => onTabSelected(index),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? activeBgColor : Colors.transparent,
                borderRadius: BorderRadius.circular(26),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: activeBgColor.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : null,
              ),
              child: Text(
                tabs[index],
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected ? activeTextColor : inactiveTextColor,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// 3-Box Stat Row for Distance, Calories, Active Time
class MetricStatCard extends StatelessWidget {
  final String distance;
  final String calories;
  final String activeTime;

  const MetricStatCard({
    super.key,
    required this.distance,
    required this.calories,
    required this.activeTime,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              icon: Icons.place_outlined,
              iconColor: AppColors.skyBlue,
              label: 'Distance',
              value: distance,
            ),
          ),
          Container(width: 1, height: 42, color: AppColors.cardBorder),
          Expanded(
            child: _buildStatItem(
              icon: Icons.local_fire_department_outlined,
              iconColor: AppColors.accentOrange,
              label: 'Calories',
              value: calories,
            ),
          ),
          Container(width: 1, height: 42, color: AppColors.cardBorder),
          Expanded(
            child: _buildStatItem(
              icon: Icons.access_time_rounded,
              iconColor: AppColors.sageGreen,
              label: 'Active Time',
              value: activeTime,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: iconColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}

/// Glowing Dark Hexagon Milestone Badge Hero from Screen 8
class HexagonMilestoneBadge extends StatelessWidget {
  final int count;
  final String label;

  const HexagonMilestoneBadge({
    super.key,
    required this.count,
    this.label = 'Total Milestones',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Soft outer concentric rings
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.forestGreen.withValues(alpha: 0.03),
            ),
          ),
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.forestGreen.withValues(alpha: 0.05),
            ),
          ),
          // Dark green hexagon
          CustomPaint(
            size: const Size(110, 110),
            painter: _HexagonPainter(
              fillColor: AppColors.forestGreen,
              shadowColor: AppColors.forestGreen.withValues(alpha: 0.35),
            ),
          ),
          // Inner content
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$count',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HexagonPainter extends CustomPainter {
  final Color fillColor;
  final Color shadowColor;

  _HexagonPainter({required this.fillColor, required this.shadowColor});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    for (int i = 0; i < 6; i++) {
      final angle = (i * 60 - 30) * math.pi / 180;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    // Shadow
    canvas.drawShadow(path, shadowColor, 12, false);

    // Fill
    final paint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _HexagonPainter oldDelegate) => false;
}

/// Carafe + Circular Water Ring Gauge Painter from Screen 4
class WaterCarafeWidget extends StatelessWidget {
  final double currentLiters;
  final double targetLiters;

  const WaterCarafeWidget({
    super.key,
    required this.currentLiters,
    required this.targetLiters,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (targetLiters > 0 ? currentLiters / targetLiters : 0.0).clamp(0.0, 1.0);

    return SizedBox(
      height: 210,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background subtle botanical and ring
          CustomPaint(
            size: const Size(200, 200),
            painter: _CarafeRingPainter(
              progress: progress,
              trackColor: const Color(0xFFE4F1EB),
              progressColor: AppColors.forestGreen,
            ),
          ),
          // Carafe outline & fluid drawing
          CustomPaint(
            size: const Size(90, 140),
            painter: _CarafeOutlinePainter(fillPercent: progress),
          ),
          // Center Text: 1.8 L / of 2.5 L
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 35),
              Text(
                '${currentLiters.toStringAsFixed(1)} L',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.forestGreen,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'of ${targetLiters.toStringAsFixed(1)} L',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CarafeRingPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;

  _CarafeRingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.45;
    const strokeWidth = 8.0;

    // Track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    // Active progress
    if (progress > 0.01) {
      final progressPaint = Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CarafeRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _CarafeOutlinePainter extends CustomPainter {
  final double fillPercent;

  _CarafeOutlinePainter({required this.fillPercent});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Carafe bottle silhouette
    final bottlePath = Path();
    bottlePath.moveTo(w * 0.35, 0);
    bottlePath.lineTo(w * 0.65, 0);
    bottlePath.lineTo(w * 0.62, h * 0.25);
    bottlePath.cubicTo(w * 0.75, h * 0.45, w * 0.95, h * 0.70, w * 0.90, h * 0.92);
    bottlePath.quadraticBezierTo(w * 0.85, h, w * 0.50, h);
    bottlePath.quadraticBezierTo(w * 0.15, h, w * 0.10, h * 0.92);
    bottlePath.cubicTo(w * 0.05, h * 0.70, w * 0.25, h * 0.45, w * 0.38, h * 0.25);
    bottlePath.close();

    // Subtle water fluid fill
    if (fillPercent > 0.05) {
      canvas.save();
      canvas.clipPath(bottlePath);
      final waterTop = h * (1.0 - fillPercent * 0.85);
      final waterPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            const Color(0xFFC7E6F5).withValues(alpha: 0.8),
            const Color(0xFFA6D6F0).withValues(alpha: 0.9),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(0, waterTop, w, h - waterTop));

      final waterPath = Path();
      waterPath.moveTo(0, waterTop);
      waterPath.quadraticBezierTo(w * 0.5, waterTop - 4, w, waterTop);
      waterPath.lineTo(w, h);
      waterPath.lineTo(0, h);
      waterPath.close();

      canvas.drawPath(waterPath, waterPaint);
      canvas.restore();
    }

    // Bottle outline stroke
    final outlinePaint = Paint()
      ..color = AppColors.forestGreen.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(bottlePath, outlinePaint);
  }

  @override
  bool shouldRepaint(covariant _CarafeOutlinePainter oldDelegate) =>
      oldDelegate.fillPercent != fillPercent;
}

/// Smooth cubic sparkline curve for Health Metrics cards
class HealthSparklinePainter extends CustomPainter {
  final List<double> data;
  final Color lineColor;

  HealthSparklinePainter({required this.data, required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final path = Path();
    final stepX = size.width / (data.length - 1);

    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final y = size.height - (data[i] * (size.height - 4)) - 2;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        final prevX = (i - 1) * stepX;
        final prevY = size.height - (data[i - 1] * (size.height - 4)) - 2;
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
  bool shouldRepaint(covariant HealthSparklinePainter oldDelegate) => true;
}
