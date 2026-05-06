import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/watch_metrics_provider.dart';
import '../theme/app_colors.dart';
import 'progress_ring.dart';

class WatchDashboard extends StatelessWidget {
  const WatchDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 16),
        _PulseCard(),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _WellnessCard()),
            const SizedBox(width: 16),
            Expanded(child: _SpO2Card()),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _LiveBadge extends StatefulWidget {
  const _LiveBadge();

  @override
  State<_LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<_LiveBadge> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.1),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: _controller.value,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 4),
          const Text(
            'LIVE',
            style: TextStyle(
              color: Colors.redAccent,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _PulseCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final watch = Provider.of<WatchMetricsProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black12,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(LucideIcons.heart, color: AppColors.coral, size: 20),
                  const SizedBox(width: 8),
                  Text('Heart Rate', style: Theme.of(context).textTheme.titleSmall),
                ],
              ),
              if (watch.isStreaming) const _LiveBadge(),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${watch.pulse > 0 ? watch.pulse : "--"}',
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 8),
              const Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: Text(
                  'BPM',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Resting ${watch.restingHeartRate > 0 ? watch.restingHeartRate : "--"}',
                    style: TextStyle(
                      color: isDark ? Colors.white60 : Colors.black54,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    'Max ${watch.maxHeartRate > 0 ? watch.maxHeartRate : "--"}',
                    style: TextStyle(
                      color: isDark ? Colors.white60 : Colors.black54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          _ZoneBar(label: 'Rest', percent: 0.6, color: Colors.blue, hours: '14h'),
          const SizedBox(height: 8),
          _ZoneBar(label: 'Fat Burn', percent: 0.25, color: Colors.green, hours: '6h'),
          const SizedBox(height: 8),
          _ZoneBar(label: 'Cardio', percent: 0.1, color: Colors.orange, hours: '3h'),
          const SizedBox(height: 8),
          _ZoneBar(label: 'Peak', percent: 0.05, color: Colors.red, hours: '1h'),
        ],
      ),
    );
  }
}

class _ZoneBar extends StatelessWidget {
  final String label;
  final double percent;
  final Color color;
  final String hours;

  const _ZoneBar({
    required this.label,
    required this.percent,
    required this.color,
    required this.hours,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white12 : Colors.black12,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              FractionallySizedBox(
                widthFactor: percent,
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.5),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          hours,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.white60 : Colors.black54,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _WellnessCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final watch = Provider.of<WatchMetricsProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(left: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black12,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(LucideIcons.smile, color: AppColors.green, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Wellness',
                  style: Theme.of(context).textTheme.titleSmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ProgressRing(
            size: 100,
            strokeWidth: 8,
            progress: watch.wellnessScore.toDouble(),
            color: AppColors.primary,
            label: watch.wellnessScore > 0 ? '${watch.wellnessScore}' : '--',
            sublabel: 'Score',
          ),
        ],
      ),
    );
  }
}

class _SpO2Card extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final watch = Provider.of<WatchMetricsProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color spo2Color = AppColors.blue;
    if (watch.spO2 > 0 && watch.spO2 < 90) {
      spo2Color = AppColors.coral;
    } else if (watch.spO2 > 0 && watch.spO2 < 95) {
      spo2Color = AppColors.yellow;
    }

    return Container(
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black12,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(LucideIcons.wind, color: AppColors.blue, size: 20),
              const SizedBox(width: 8),
              Text('SpO2', style: Theme.of(context).textTheme.titleSmall),
              const Spacer(),
              if (watch.isStreaming) const _LiveBadge(),
            ],
          ),
          const SizedBox(height: 24),
          ProgressRing(
            size: 100,
            strokeWidth: 8,
            progress: watch.spO2 > 0 ? watch.spO2 : 0,
            color: spo2Color,
            label: watch.spO2 > 0 ? '${watch.spO2.toInt()}%' : '--',
            sublabel: 'Oxygen',
          ),
        ],
      ),
    );
  }
}
