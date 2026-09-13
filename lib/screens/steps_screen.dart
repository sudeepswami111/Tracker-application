import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../providers/step_tracker_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/botanical_decorations.dart';
import '../widgets/scenic_banner.dart';

class StepsScreen extends StatefulWidget {
  const StepsScreen({super.key});

  @override
  State<StepsScreen> createState() => _StepsScreenState();
}

class _StepsScreenState extends State<StepsScreen> {
  int _selectedTab = 0; // 0: Day, 1: Week, 2: Month

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final stepTracker = context.watch<StepTrackerProvider>();

    final steps = stepTracker.steps > 0 ? stepTracker.steps : 7842;
    final goal = app.stepsGoal > 0 ? app.stepsGoal : 10000;
    final progress = (steps / goal).clamp(0.0, 1.0);
    final pct = (progress * 100).round();
    final distance = (app.distance > 0 ? app.distance : (steps * 0.00075)).toStringAsFixed(1);
    final calories = (steps * 0.045).round().clamp(100, 2000);
    final activeMinutes = stepTracker.activeMinutes > 0 ? stepTracker.activeMinutes : 68;

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
          'Steps',
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. Segmented Tabs: Day | Week | Month ──
            Center(
              child: SegmentedPillTabs(
                tabs: const ['Day', 'Week', 'Month'],
                selectedIndex: _selectedTab,
                onTabSelected: (index) {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedTab = index);
                },
              ),
            ),
            const SizedBox(height: 22),

            // ── 2. Top Metric Row & Circular Progress Gauge ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '$steps ',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          TextSpan(
                            text: 'steps',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Goal: $goal',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                // Circular percentage badge
                SizedBox(
                  width: 58,
                  height: 58,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 5,
                        backgroundColor: const Color(0xFFE4F0E7),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.sageGreen),
                        strokeCap: StrokeCap.round,
                      ),
                      Text(
                        '$pct%',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.forestGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── 3. Step Activity Histogram Bar Chart ──
            _buildStepHistogram(),
            const SizedBox(height: 22),

            // ── 4. 3-Stat Metric Box: Distance, Calories, Active Time ──
            MetricStatCard(
              distance: '$distance km',
              calories: '$calories kcal',
              activeTime: '$activeMinutes min',
            ),
            const SizedBox(height: 18),

            // ── 5. Motivational Card with Leaf Branch ──
            MotivationalCard(
              quote: "You're doing great!\nYou're $pct% towards your goal.",
            ),
            const SizedBox(height: 18),

            // ── 6. Scenic Runner Nature Banner ──
            const ScenicRunnerBanner(
              title: 'Every step\nbrings you closer\nto your goals.',
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStepHistogram() {
    final List<double> hourlyRatios = [
      0.05, 0.05, 0.03, 0.02, 0.04, 0.12,
      0.30, 0.55, 0.70, 0.85, 0.60, 0.72,
      0.90, 1.00, 0.88, 0.65, 0.40, 0.25,
      0.20, 0.15, 0.10, 0.08, 0.05, 0.05,
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        children: [
          SizedBox(
            height: 100,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(hourlyRatios.length, (i) {
                final ratio = hourlyRatios[i];
                final isPeak = ratio > 0.8;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1.5),
                    child: Container(
                      height: 100 * ratio,
                      decoration: BoxDecoration(
                        color: isPeak ? AppColors.sageGreen : AppColors.sageGreen.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('12 AM', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppColors.textSecondary)),
              Text('6 AM', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppColors.textSecondary)),
              Text('12 PM', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppColors.textSecondary)),
              Text('6 PM', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppColors.textSecondary)),
              Text('12 AM', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}
