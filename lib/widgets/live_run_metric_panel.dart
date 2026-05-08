import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class LiveRunMetricPanel extends StatelessWidget {
  final String pace;
  final String distance;
  final int bpm;
  final String duration;

  const LiveRunMetricPanel({
    super.key,
    required this.pace,
    required this.distance,
    required this.bpm,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.backgroundDeep.withValues(alpha: 0.7),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.screenMargin),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag Handle
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.textSecondary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // 2x2 Grid
                  Row(
                    children: [
                      Expanded(
                        child: _MetricCell(
                          label: 'PACE',
                          value: pace,
                          unit: '/km',
                          theme: theme,
                          isMono: true,
                        ),
                      ),
                      Expanded(
                        child: _MetricCell(
                          label: 'DISTANCE',
                          value: distance,
                          unit: 'km',
                          theme: theme,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    children: [
                      Expanded(
                        child: _BpmCell(
                          bpm: bpm,
                          theme: theme,
                        ),
                      ),
                      Expanded(
                        child: _MetricCell(
                          label: 'DURATION',
                          value: duration,
                          unit: '',
                          theme: theme,
                          isMono: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricCell extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final ThemeData theme;
  final bool isMono;

  const _MetricCell({
    required this.label,
    required this.value,
    required this.unit,
    required this.theme,
    this.isMono = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: const Color(0xFF8E8E9E), // Per spec: #8E8E9E
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: (isMono ? theme.textTheme.displaySmall : theme.textTheme.displayMedium)?.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            if (unit.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(
                unit,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF8E8E9E),
                ),
              ),
            ]
          ],
        ),
      ],
    );
  }
}

class _BpmCell extends StatefulWidget {
  final int bpm;
  final ThemeData theme;

  const _BpmCell({
    required this.bpm,
    required this.theme,
  });

  @override
  State<_BpmCell> createState() => _BpmCellState();
}

class _BpmCellState extends State<_BpmCell> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Color _getZoneColor() {
    if (widget.bpm < 120) return AppColors.voltCyan;
    if (widget.bpm < 150) return AppColors.solarAmber;
    return AppColors.pulseRed;
  }

  @override
  Widget build(BuildContext context) {
    final zoneColor = _getZoneColor();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'HEART RATE',
              style: widget.theme.textTheme.labelSmall?.copyWith(
                color: const Color(0xFF8E8E9E),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(width: 8),
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _pulseAnimation.value,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: zoneColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: zoneColor.withValues(alpha: 0.5),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '${widget.bpm}',
              style: widget.theme.textTheme.displaySmall?.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              'bpm',
              style: widget.theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF8E8E9E),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class ElevationStripWidget extends StatelessWidget {
  final List<double> data;
  final ThemeData theme;

  const ElevationStripWidget({super.key, required this.data, required this.theme});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox();
    
    final currentElev = data.last;

    return SizedBox(
      height: 48,
      width: double.infinity,
      child: Stack(
        children: [
          CustomPaint(
            size: const Size(double.infinity, 48),
            painter: _ElevationChartPainter(data: data, color: AppColors.solarAmber),
          ),
          Positioned(
            right: 16,
            top: 0,
            bottom: 0,
            child: Center(
              child: Text(
                '${currentElev.toStringAsFixed(0)}m',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    const Shadow(blurRadius: 4, color: Colors.black87),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ElevationChartPainter extends CustomPainter {
  final List<double> data;
  final Color color;

  _ElevationChartPainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    final maxVal = data.reduce(max);
    final minVal = data.reduce(min);
    final range = (maxVal - minVal) == 0 ? 1 : (maxVal - minVal);

    final dx = size.width / (data.length - 1);

    for (var i = 0; i < data.length; i++) {
      final x = i * dx;
      final y = size.height - ((data[i] - minVal) / range) * size.height;

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }

      if (i == data.length - 1) {
        fillPath.lineTo(x, size.height);
      }
    }

    fillPath.close();
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ElevationChartPainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.color != color;
  }
}
