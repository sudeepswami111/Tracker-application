import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import 'glass_card.dart';

// ── Health Score Dial ──
class HealthScoreDial extends StatefulWidget {
  final int score;
  final int heartScore;
  final int sleepScore;
  final int spo2Score;

  const HealthScoreDial({
    super.key,
    required this.score,
    required this.heartScore,
    required this.sleepScore,
    required this.spo2Score,
  });

  @override
  State<HealthScoreDial> createState() => _HealthScoreDialState();
}

class _HealthScoreDialState extends State<HealthScoreDial> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutExpo);
    _controller.forward();
  }

  @override
  void didUpdateWidget(HealthScoreDial oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.score != widget.score) {
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GlassCard(
      child: Column(
        children: [
          Text('Health Score', style: theme.textTheme.titleLarge),
          const SizedBox(height: 24),
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return SizedBox(
                width: 180,
                height: 180,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(180, 180),
                      painter: _DialPainter(
                        progress: (widget.score / 100) * _animation.value,
                        color: const Color(0xFF00E5CC), // Cyan
                        bgColor: isDark ? Colors.white10 : Colors.black12,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          (widget.score * _animation.value).toInt().toString(),
                          style: GoogleFonts.inter(
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'Excellent',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF00E5CC),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _MiniMetricRing(label: 'Heart', value: widget.heartScore, color: AppColors.coral),
              _MiniMetricRing(label: 'Sleep', value: widget.sleepScore, color: AppColors.primary),
              _MiniMetricRing(label: 'SpO₂', value: widget.spo2Score, color: AppColors.blue),
            ],
          ),
        ],
      ),
    );
  }
}

class _DialPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color bgColor;

  _DialPainter({required this.progress, required this.color, required this.bgColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    
    final paintBg = Paint()
      ..color = bgColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    final paintFg = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    // Background arc (240 degrees)
    const startAngle = 150 * math.pi / 180;
    const sweepAngle = 240 * math.pi / 180;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepAngle, false, paintBg);

    // Foreground arc
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepAngle * progress, false, paintFg);
  }

  @override
  bool shouldRepaint(_DialPainter oldDelegate) => 
      oldDelegate.progress != progress || oldDelegate.color != color || oldDelegate.bgColor != bgColor;
}

class _MiniMetricRing extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _MiniMetricRing({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Column(
      children: [
        SizedBox(
          width: 48,
          height: 48,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: value / 100,
                backgroundColor: isDark ? Colors.white10 : Colors.black12,
                color: color,
                strokeWidth: 5,
                strokeCap: StrokeCap.round,
              ),
              Text(
                value.toString(),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

// ── BLE Wearable Card ──
class BleWearableCard extends StatefulWidget {
  final int heartRate;
  final bool isConnected;

  const BleWearableCard({super.key, required this.heartRate, required this.isConnected});

  @override
  State<BleWearableCard> createState() => _BleWearableCardState();
}

class _BleWearableCardState extends State<BleWearableCard> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000), // 1 Hz
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(_pulseController);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Color _getZoneColor(int hr) {
    if (hr < 100) return const Color(0xFF8E8E9E); // Rest
    if (hr < 120) return const Color(0xFFF59E0B); // FatBurn
    if (hr < 150) return const Color(0xFF00E5CC); // Cardio
    return const Color(0xFFFF3B5C); // Peak
  }

  String _getZoneLabel(int hr) {
    if (hr < 100) return 'Rest';
    if (hr < 120) return 'Fat Burn';
    if (hr < 150) return 'Cardio';
    return 'Peak';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final zoneColor = _getZoneColor(widget.heartRate);
    final zoneLabel = _getZoneLabel(widget.heartRate);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(LucideIcons.watch, size: 20, color: theme.colorScheme.onSurface),
                  const SizedBox(width: 8),
                  Text('Smart Watch', style: theme.textTheme.titleMedium),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.isConnected ? AppColors.green.withValues(alpha: 0.15) : AppColors.coral.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.isConnected ? 'Connected' : 'Disconnected',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: widget.isConnected ? AppColors.green : AppColors.coral,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: widget.isConnected && widget.heartRate > 0 ? _pulseAnimation.value : 1.0,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Icon(LucideIcons.heartPulse, size: 40, color: zoneColor),
                        const SizedBox(width: 8),
                        Text(
                          widget.heartRate > 0 ? widget.heartRate.toString() : '--',
                          style: GoogleFonts.inter(
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            color: theme.colorScheme.onSurface,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text('BPM', style: theme.textTheme.bodyMedium),
                        ),
                      ],
                    ),
                  );
                },
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: zoneColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: zoneColor.withValues(alpha: 0.5)),
                ),
                child: Text(
                  zoneLabel,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: zoneColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Sleep Stage Bar ──
class SleepStageBar extends StatefulWidget {
  final double awakeHours;
  final double lightHours;
  final double deepHours;
  final double remHours;

  const SleepStageBar({
    super.key,
    required this.awakeHours,
    required this.lightHours,
    required this.deepHours,
    required this.remHours,
  });

  @override
  State<SleepStageBar> createState() => _SleepStageBarState();
}

class _SleepStageBarState extends State<SleepStageBar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = widget.awakeHours + widget.lightHours + widget.deepHours + widget.remHours;
    if (total == 0) return const SizedBox();

    final awakePct = widget.awakeHours / total;
    final lightPct = widget.lightHours / total;
    final deepPct = widget.deepHours / total;
    final remPct = widget.remHours / total;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Sleep Stages', style: theme.textTheme.titleMedium),
              Text('${total.toStringAsFixed(1)}h Total', style: theme.textTheme.bodyMedium),
            ],
          ),
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Container(
                height: 24,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: theme.colorScheme.surfaceContainerHighest,
                ),
                clipBehavior: Clip.antiAlias,
                child: Row(
                  children: [
                    _buildSegment(awakePct * _animation.value, const Color(0xFFFF3B5C)),
                    _buildSegment(lightPct * _animation.value, const Color(0xFF8B5CF6)),
                    _buildSegment(deepPct * _animation.value, const Color(0xFF00E5CC)),
                    _buildSegment(remPct * _animation.value, const Color(0xFFF59E0B)),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildLegend('Awake', const Color(0xFFFF3B5C), theme),
              _buildLegend('Light', const Color(0xFF8B5CF6), theme),
              _buildLegend('Deep', const Color(0xFF00E5CC), theme),
              _buildLegend('REM', const Color(0xFFF59E0B), theme),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSegment(double pct, Color color) {
    if (pct <= 0) return const SizedBox();
    return Expanded(
      flex: (pct * 1000).toInt(),
      child: Container(
        margin: const EdgeInsets.only(right: 2),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  Widget _buildLegend(String label, Color color, ThemeData theme) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: theme.textTheme.labelSmall),
      ],
    );
  }
}

// ── Water Intake Bar ──
class WaterIntakeBar extends StatefulWidget {
  final int current;
  final int goal;
  final VoidCallback onAdd;

  const WaterIntakeBar({super.key, required this.current, required this.goal, required this.onAdd});

  @override
  State<WaterIntakeBar> createState() => _WaterIntakeBarState();
}

class _WaterIntakeBarState extends State<WaterIntakeBar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _oldValue = 0.0;
  double _newValue = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _newValue = (widget.current / widget.goal).clamp(0.0, 1.0);
    _animation = Tween<double>(begin: _oldValue, end: _newValue).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(WaterIntakeBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.current != widget.current || oldWidget.goal != widget.goal) {
      _oldValue = (oldWidget.current / oldWidget.goal).clamp(0.0, 1.0);
      _newValue = (widget.current / widget.goal).clamp(0.0, 1.0);
      _animation = Tween<double>(begin: _oldValue, end: _newValue).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
      );
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
    final theme = Theme.of(context);
    
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(LucideIcons.droplets, size: 20, color: const Color(0xFF00E5CC)),
                  const SizedBox(width: 8),
                  Text('Water Intake', style: theme.textTheme.titleMedium),
                ],
              ),
              IconButton(
                icon: const Icon(LucideIcons.plusCircle, color: Color(0xFF00E5CC), size: 28),
                onPressed: () {
                  widget.onAdd();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Water logged!'),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('${widget.current} / ${widget.goal} Glasses', style: theme.textTheme.bodyMedium),
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Stack(
                children: [
                  Container(
                    height: 20,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: _animation.value,
                    child: Container(
                      height: 20,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00E5CC),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00E5CC).withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Trend Chart ──
class TrendChartCard extends StatelessWidget {
  final List<double> dataPoints;
  final String title;

  const TrendChartCard({super.key, required this.dataPoints, required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    if (dataPoints.isEmpty) return const SizedBox();

    final maxVal = dataPoints.reduce(math.max);
    final minVal = dataPoints.reduce(math.min);
    
    List<FlSpot> spots = [];
    for (int i = 0; i < dataPoints.length; i++) {
      spots.add(FlSpot(i.toDouble(), dataPoints[i]));
    }

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (dataPoints.length - 1).toDouble(),
                minY: minVal - (maxVal - minVal) * 0.2,
                maxY: maxVal + (maxVal - minVal) * 0.2,
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (touchedSpot) => isDark ? Colors.grey[800]! : Colors.white,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((LineBarSpot touchedSpot) {
                        return LineTooltipItem(
                          touchedSpot.y.toStringAsFixed(1),
                          GoogleFonts.inter(
                            color: const Color(0xFF00E5CC),
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: const Color(0xFF00E5CC),
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF00E5CC).withValues(alpha: 0.5),
                          const Color(0xFF00E5CC).withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOut,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Metric Grid Card ──
class MetricGridCard extends StatelessWidget {
  final String label;
  final String value;
  final double progress;
  final bool isUpTrend;

  const MetricGridCard({
    super.key,
    required this.label,
    required this.value,
    required this.progress,
    required this.isUpTrend,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  value: progress,
                  backgroundColor: isDark ? Colors.white10 : Colors.black12,
                  color: const Color(0xFF00E5CC),
                  strokeWidth: 6,
                  strokeCap: StrokeCap.round,
                ),
              ),
              Icon(
                isUpTrend ? LucideIcons.trendingUp : LucideIcons.trendingDown,
                color: isUpTrend ? AppColors.green : AppColors.coral,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
