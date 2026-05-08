import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class NutritionArcWidget extends StatelessWidget {
  final double caloriesConsumed;
  final double caloriesTotal;
  final double carbsConsumed;
  final double carbsTotal;
  final double proteinConsumed;
  final double proteinTotal;
  final double fatsConsumed;
  final double fatsTotal;

  const NutritionArcWidget({
    super.key,
    required this.caloriesConsumed,
    required this.caloriesTotal,
    required this.carbsConsumed,
    required this.carbsTotal,
    required this.proteinConsumed,
    required this.proteinTotal,
    required this.fatsConsumed,
    required this.fatsTotal,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final calorieProgress = (caloriesConsumed / caloriesTotal).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderSubtle, width: 1),
      ),
      child: Column(
        children: [
          // Arc Widget
          SizedBox(
            height: 140, // Height is less than width due to arc shape
            width: 180,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                CustomPaint(
                  size: const Size(180, 180), // Uses square space but draws arc in upper half
                  painter: _ArcPainter(
                    progress: calorieProgress,
                    activeColor: AppColors.solarAmber,
                    backgroundColor: AppColors.surfaceElevated,
                    strokeWidth: 12,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${caloriesConsumed.toInt()}',
                      style: theme.textTheme.displayMedium?.copyWith(
                        color: AppColors.textPrimary,
                        height: 1.0,
                      ),
                    ),
                    Text(
                      '/ ${caloriesTotal.toInt()} kcal',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Macro Mini-bars
          _MacroBar(
            label: 'Carbs',
            consumed: carbsConsumed,
            total: carbsTotal,
            color: AppColors.voltCyan,
            theme: theme,
          ),
          const SizedBox(height: 12),
          _MacroBar(
            label: 'Protein',
            consumed: proteinConsumed,
            total: proteinTotal,
            color: AppColors.pulseRed,
            theme: theme,
          ),
          const SizedBox(height: 12),
          _MacroBar(
            label: 'Fats',
            consumed: fatsConsumed,
            total: fatsTotal,
            color: AppColors.solarAmber,
            theme: theme,
          ),
        ],
      ),
    );
  }
}

class _MacroBar extends StatelessWidget {
  final String label;
  final double consumed;
  final double total;
  final Color color;
  final ThemeData theme;

  const _MacroBar({
    required this.label,
    required this.consumed,
    required this.total,
    required this.color,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (consumed / total).clamp(0.0, 1.0);
    return Row(
      children: [
        SizedBox(
          width: 52,
          child: Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 4,
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 52,
          child: Text(
            '${consumed.toInt()}g',
            textAlign: TextAlign.right,
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _ArcPainter extends CustomPainter {
  final double progress;
  final Color activeColor;
  final Color backgroundColor;
  final double strokeWidth;

  _ArcPainter({
    required this.progress,
    required this.activeColor,
    required this.backgroundColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 30);
    final radius = (size.width - strokeWidth) / 2;

    // 240 degree sweep. Start at 150 degrees (5pi/6), sweep 240 (4pi/3)
    const startAngle = pi - (pi / 6); // 150 deg
    const sweepAngle = pi + (pi / 3); // 240 deg

    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final activePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      bgPaint,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle * progress,
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ArcPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}
