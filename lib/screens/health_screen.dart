import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../providers/watch_metrics_provider.dart';
import '../providers/step_tracker_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/botanical_decorations.dart';

class HealthScreen extends StatefulWidget {
  const HealthScreen({super.key});

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen> {
  int _selectedTab = 0; // 0: Overview, 1: Trends, 2: Details

  @override
  Widget build(BuildContext context) {
    final watch = context.watch<WatchMetricsProvider>();
    final stepTracker = context.watch<StepTrackerProvider>();

    final hr = (watch.pulse != null && watch.pulse! > 0) ? watch.pulse! : 72;
    final spo2 = (watch.spO2 != null && watch.spO2! > 0) ? watch.spO2!.toInt() : 98;
    final calories = (stepTracker.steps * 0.045).round().clamp(100, 2000);
    final sleepHours = watch.sleepHours != null && watch.sleepHours! > 0 ? watch.sleepHours! : 7.7;
    final sleepH = sleepHours.floor();
    final sleepM = ((sleepHours - sleepH) * 60).round();

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      appBar: AppBar(
        backgroundColor: AppColors.lightBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: AppColors.textPrimary, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Health Metrics',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── 1. Segmented Tabs: Overview | Trends | Details ──
            SegmentedPillTabs(
              tabs: const ['Overview', 'Trends', 'Details'],
              selectedIndex: _selectedTab,
              onTabSelected: (index) {
                HapticFeedback.selectionClick();
                setState(() => _selectedTab = index);
              },
            ),
            const SizedBox(height: 22),

            // ── 2. Heart Rate Card ──
            _buildMetricSparklineCard(
              icon: LucideIcons.heart,
              iconColor: AppColors.accentPeach,
              iconBgColor: const Color(0xFFFDECE6),
              title: 'Heart Rate',
              value: '$hr',
              unit: 'bpm',
              status: 'Normal',
              sparklineColor: AppColors.accentPeach,
              sparklineData: const [0.3, 0.5, 0.4, 0.8, 0.45, 0.7, 0.55, 0.9, 0.65],
            ),
            const SizedBox(height: 12),

            // ── 3. SpO2 Card ──
            _buildMetricSparklineCard(
              icon: LucideIcons.droplets,
              iconColor: AppColors.skyBlue,
              iconBgColor: AppColors.skyLight,
              title: 'SpO2',
              value: '$spo2',
              unit: '%',
              status: 'Normal',
              sparklineColor: AppColors.skyBlue,
              sparklineData: const [0.7, 0.75, 0.7, 0.85, 0.8, 0.9, 0.85, 0.95, 0.9],
            ),
            const SizedBox(height: 12),

            // ── 4. Calories Card ──
            _buildMetricSparklineCard(
              icon: LucideIcons.flame,
              iconColor: AppColors.accentOrange,
              iconBgColor: const Color(0xFFFEF3E8),
              title: 'Calories',
              value: '$calories',
              unit: 'kcal',
              status: 'Today',
              sparklineColor: AppColors.accentOrange,
              sparklineData: const [0.2, 0.35, 0.5, 0.4, 0.65, 0.6, 0.8, 0.75, 0.85],
            ),
            const SizedBox(height: 12),

            // ── 5. Sleep Card ──
            _buildMetricSparklineCard(
              icon: LucideIcons.moon,
              iconColor: AppColors.lavender,
              iconBgColor: AppColors.lavenderLight,
              title: 'Sleep',
              value: '${sleepH}h ${sleepM}m',
              unit: '',
              status: 'Good',
              sparklineColor: AppColors.lavender,
              sparklineData: const [0.4, 0.45, 0.6, 0.55, 0.7, 0.75, 0.65, 0.85, 0.8],
            ),
            const SizedBox(height: 18),

            // ── 6. Status Banner: Your health is on track! ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFE5F3E8),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFD2E8D7)),
              ),
              child: Row(
                children: [
                  const BotanicalLeafIcon(size: 26, color: AppColors.sageGreen),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your health is on track!',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.forestGreen,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Keep it up.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.sageGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricSparklineCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String value,
    required String unit,
    required String status,
    required Color sparklineColor,
    required List<double> sparklineData,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          // Left: Icon + Title & Value
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 16, color: iconColor),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    value,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  if (unit.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Text(
                      unit,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 3),
              Text(
                status,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Right: Sparkline Curve
          SizedBox(
            width: 110,
            height: 48,
            child: CustomPaint(
              painter: HealthSparklinePainter(
                data: sparklineData,
                lineColor: sparklineColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
