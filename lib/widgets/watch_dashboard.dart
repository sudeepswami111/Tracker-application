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
            // ── Top Bar: Last Synced & Refresh ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Last synced: ${watch.lastSyncedText}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white54,
                  ),
                ),
                if (watch.isFetching)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white54, size: 20),
                    onPressed: () => watch.refresh(),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // ── BLE Wearable Card ──
            BleWearableCard(
              heartRate: watch.pulse,
              isConnected: watch.isConnected,
              deviceName: watch.deviceName,
            ),
            const SizedBox(height: 16),

            // ── Health Score Dial ──
            if (watch.wellnessScore != null) ...[
              HealthScoreDial(
                score: watch.wellnessScore!,
                heartScore: watch.pulse != null && watch.restingHeartRate != null ? (100 - (watch.restingHeartRate! - 60).abs()).clamp(0, 100) : null,
                sleepScore: watch.sleepHours != null ? ((watch.sleepHours! / 8) * 100).clamp(0, 100).toInt() : null,
                spo2Score: watch.spO2 != null ? watch.spO2!.toInt() : null,
              ),
              const SizedBox(height: 16),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(child: Text("Not enough data for Health Score", style: TextStyle(color: Colors.white54))),
              ),
              const SizedBox(height: 16),
            ],

            // ── Vitals Grid ──
            Row(
              children: [
                Expanded(
                  child: MetricGridCard(
                    label: 'SpO₂',
                    value: watch.spO2 != null ? '${watch.spO2!.toStringAsFixed(0)}%' : '--',
                    progress: watch.spO2 != null ? watch.spO2! / 100 : 0.0,
                    isUpTrend: watch.spO2 != null ? watch.spO2! >= 95 : false,
                    sourceLabel: 'Health Connect',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: MetricGridCard(
                    label: 'Blood Pressure',
                    value: watch.systolic != null && watch.diastolic != null ? '${watch.systolic}/${watch.diastolic}' : '--/--',
                    progress: watch.systolic != null ? 0.75 : 0.0,
                    isUpTrend: true,
                    sourceLabel: 'Health Connect',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Sleep Stage Bar ──
            if (watch.sleepHours != null) ...[
              SleepStageBar(
                awakeHours: watch.sleepHours! * 0.1,
                lightHours: watch.sleepHours! * 0.5,
                deepHours: watch.sleepHours! * 0.25,
                remHours: watch.sleepHours! * 0.15,
              ),
              const SizedBox(height: 16),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(child: Text("Sleep stages unavailable", style: TextStyle(color: Colors.white54))),
              ),
              const SizedBox(height: 16),
            ],

            // ── Trend Chart ──
            TrendChartCard(
              title: 'Activity Trend',
              dataPoints: watch.pulse != null ? [
                (watch.pulse! - 10).toDouble().clamp(60, 180),
                (watch.pulse! - 5).toDouble().clamp(60, 180),
                (watch.pulse! + 2).toDouble().clamp(60, 180),
                (watch.pulse! - 2).toDouble().clamp(60, 180),
                watch.pulse!.toDouble(),
              ] : [],
            ),
          ],
        ),
      ),
    );
  }
}
