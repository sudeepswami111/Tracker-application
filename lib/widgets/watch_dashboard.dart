import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/watch_metrics_provider.dart';
import 'health_components.dart';

class WatchDashboard extends StatefulWidget {
  const WatchDashboard({super.key});

  @override
  State<WatchDashboard> createState() => _WatchDashboardState();
}

class _WatchDashboardState extends State<WatchDashboard>
    with TickerProviderStateMixin {
  late AnimationController _entryController;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

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

    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final watch = context.watch<WatchMetricsProvider>();

    return FadeTransition(
      opacity: _fadeIn,
      child: SlideTransition(
        position: _slideUp,
        child: Column(
          children: [
            // ── BLE Wearable Card ──
            BleWearableCard(
              heartRate: watch.pulse,
              isConnected: watch.isConnected,
            ),
            const SizedBox(height: 16),

            // ── Health Score Dial ──
            HealthScoreDial(
              score: watch.wellnessScore > 0 ? watch.wellnessScore : 85,
              heartScore: watch.pulse > 0 ? (100 - (watch.restingHeartRate - 60).abs()).clamp(0, 100) : 80,
              sleepScore: watch.sleepHours > 0 ? ((watch.sleepHours / 8) * 100).clamp(0, 100).toInt() : 75,
              spo2Score: watch.spO2 > 0 ? watch.spO2.toInt() : 98,
            ),
            const SizedBox(height: 16),

            // ── Vitals Grid ──
            Row(
              children: [
                Expanded(
                  child: MetricGridCard(
                    label: 'SpO₂',
                    value: '${watch.spO2 > 0 ? watch.spO2.toStringAsFixed(0) : "98"}%',
                    progress: watch.spO2 > 0 ? watch.spO2 / 100 : 0.98,
                    isUpTrend: watch.spO2 >= 95,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: MetricGridCard(
                    label: 'Blood Pressure',
                    value: '${watch.systolic}/${watch.diastolic}',
                    progress: 0.75,
                    isUpTrend: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Sleep Stage Bar ──
            SleepStageBar(
              awakeHours: watch.sleepHours > 0 ? watch.sleepHours * 0.1 : 0.8,
              lightHours: watch.sleepHours > 0 ? watch.sleepHours * 0.5 : 4.0,
              deepHours: watch.sleepHours > 0 ? watch.sleepHours * 0.25 : 2.0,
              remHours: watch.sleepHours > 0 ? watch.sleepHours * 0.15 : 1.2,
            ),
            const SizedBox(height: 16),

            // ── Trend Chart ──
            TrendChartCard(
              title: 'Activity Trend',
              dataPoints: [
                if (watch.pulse > 0) ...[
                  (watch.pulse - 10).toDouble().clamp(60, 180),
                  (watch.pulse - 5).toDouble().clamp(60, 180),
                  (watch.pulse + 2).toDouble().clamp(60, 180),
                  (watch.pulse - 2).toDouble().clamp(60, 180),
                  watch.pulse.toDouble(),
                ] else ...[
                  65.0, 70.0, 68.0, 74.0, 72.0
                ]
              ],
            ),
          ],
        ),
      ),
    );
  }
}
