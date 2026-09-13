import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../providers/step_tracker_provider.dart';
import '../providers/watch_metrics_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/scenic_banner.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/profile_quick_panel.dart';
import 'steps_screen.dart';
import 'hydration_hub_screen.dart';
import 'todays_plan_screen.dart';
import 'running/running_screen.dart';
import 'weather_forecast_screen.dart';
import 'calendar_screen.dart';
import 'study_screen.dart';
import 'notifications_screen.dart';
import 'workout/fitness_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Plan check states
  bool _walkChecked = true;
  bool _workoutChecked = false;
  bool _hydrationChecked = false;
  bool _studyChecked = false;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final stepTracker = context.watch<StepTrackerProvider>();
    final watchProvider = context.watch<WatchMetricsProvider>();

    final steps = stepTracker.steps > 0 ? stepTracker.steps : 7842;
    final distance = (app.distance > 0 ? app.distance : (steps * 0.00075)).toStringAsFixed(1);
    final currentWater = app.waterIntake > 0 ? app.waterIntake.toStringAsFixed(1) : "1.8";
    final streakDays = app.currentStreak > 0 ? app.currentStreak : 12;

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.forestGreen,
          onRefresh: () async {
            await Future.wait([
              stepTracker.refreshSteps(),
              watchProvider.refresh(),
            ]);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(
              left: 20,
              right: 20,
              top: 12,
              bottom: 120, // space for bottom nav
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 1. Top Header: Good Morning, Sudeep ☀️ + Bell & Avatar ──
                _buildGreetingHeader(context, app),
                const SizedBox(height: 18),

                // ── 2. Mountain Sunrise Scenic Hero Banner ──
                ScenicHeroBanner(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const WeatherForecastScreen()));
                  },
                ),
                const SizedBox(height: 18),

                // ── 3. Health Score Card (Circular Score + 3 Metric Rows) ──
                _buildHealthScoreCard(context, steps, currentWater, streakDays),
                const SizedBox(height: 18),

                // ── 4. Today's Journey Card ──
                _buildTodaysJourneyCard(context, steps, distance),
                const SizedBox(height: 18),

                // ── 5. Today's Plan Card ──
                _buildTodaysPlanCard(context),
                const SizedBox(height: 18),

                // ── 6. Daily Thought Motivational Banner ──
                const MotivationalCard(
                  quote: 'Progress,\nnot perfection. 🍃',
                  hasLeaf: true,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGreetingHeader(BuildContext context, AppProvider app) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Good Morning,',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Text(
                  app.userName.isNotEmpty ? app.userName : 'Sudeep',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(width: 6),
                const Text('☀️', style: TextStyle(fontSize: 18)),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'Small steps. Big dreams.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        Row(
          children: [
            // Bell Notification button
            GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.cardBorder),
                  boxShadow: AppColors.cardShadow,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(LucideIcons.bell, size: 18, color: AppColors.textPrimary),
                    if (app.hasUnreadNotifications)
                      Positioned(
                        right: 10,
                        top: 10,
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: AppColors.accentPeach,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Profile avatar
            GestureDetector(
              onTap: () => showProfileQuickPanel(context),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: AppColors.cardShadow,
                ),
                child: ProfileAvatar(
                  imageUrl: app.avatarUrl,
                  name: app.userName.isNotEmpty ? app.userName : 'Sudeep',
                  radius: 19,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHealthScoreCard(BuildContext context, int steps, String water, int streak) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Health Score',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Left: Circular Progress Ring (86 / 100 Great!)
              Column(
                children: [
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          size: const Size(100, 100),
                          painter: _ScoreRingPainter(score: 86),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '86',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                                height: 1.0,
                              ),
                            ),
                            Text(
                              '/100',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              'Great!',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.sageGreen,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '↑ 4 points\nfrom yesterday',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),

              // Right: 3 Metric rows (Steps, Hydration, Streak)
              Expanded(
                child: Column(
                  children: [
                    _buildMetricRow(
                      icon: LucideIcons.footprints,
                      iconColor: AppColors.sageGreen,
                      iconBgColor: AppColors.mintLight,
                      label: 'Steps',
                      value: '$steps',
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const StepsScreen()));
                      },
                    ),
                    Divider(color: AppColors.cardBorder, height: 16),
                    _buildMetricRow(
                      icon: LucideIcons.droplets,
                      iconColor: AppColors.skyBlue,
                      iconBgColor: AppColors.skyLight,
                      label: 'Hydration',
                      value: '$water / 2.5 L',
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const HydrationHubScreen()));
                      },
                    ),
                    Divider(color: AppColors.cardBorder, height: 16),
                    _buildMetricRow(
                      icon: LucideIcons.flame,
                      iconColor: AppColors.accentOrange,
                      iconBgColor: const Color(0xFFFEF3E8),
                      label: 'Streak',
                      value: '$streak days',
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const CalendarScreen()));
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 14, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(LucideIcons.chevronRight, size: 14, color: AppColors.neutralGray),
        ],
      ),
    );
  }

  Widget _buildTodaysJourneyCard(BuildContext context, int steps, String distance) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const RunningScreen()));
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Today's Journey",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Icon(LucideIcons.chevronRight, size: 18, color: AppColors.neutralGray),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _buildJourneyChip(LucideIcons.footprints, AppColors.sageGreen, '$steps\nsteps'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildJourneyChip(LucideIcons.mapPin, AppColors.skyBlue, '$distance km\ndistance'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildJourneyChip(LucideIcons.clock, AppColors.accentOrange, '68 min\ntime'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJourneyChip(IconData icon, Color iconColor, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF9F4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodaysPlanCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Today's Plan",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const TodaysPlanScreen()));
                },
                child: Text(
                  'View all',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildCheckItem(
            'Morning Walk',
            '20 min',
            _walkChecked,
            () => setState(() => _walkChecked = !_walkChecked),
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RunningScreen())),
          ),
          const SizedBox(height: 10),
          _buildCheckItem(
            'Workout',
            '30 min',
            _workoutChecked,
            () => setState(() => _workoutChecked = !_workoutChecked),
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FitnessScreen())),
          ),
          const SizedBox(height: 10),
          _buildCheckItem(
            'Hydration',
            '2.5 L',
            _hydrationChecked,
            () => setState(() => _hydrationChecked = !_hydrationChecked),
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HydrationHubScreen())),
          ),
          const SizedBox(height: 10),
          _buildCheckItem(
            'Study',
            '45 min',
            _studyChecked,
            () => setState(() => _studyChecked = !_studyChecked),
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudyScreen())),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckItem(
    String title,
    String time,
    bool isChecked,
    VoidCallback onToggle,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          GestureDetector(
            onTap: onToggle,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isChecked ? AppColors.sageGreen : Colors.transparent,
                border: Border.all(
                  color: isChecked ? AppColors.sageGreen : const Color(0xFFC8D5CC),
                  width: 1.8,
                ),
              ),
              child: isChecked
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                decoration: isChecked ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          Text(
            time,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 6),
          const Icon(LucideIcons.chevronRight, size: 14, color: AppColors.neutralGray),
        ],
      ),
    );
  }
}

class _ScoreRingPainter extends CustomPainter {
  final int score;

  _ScoreRingPainter({required this.score});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 12) / 2;
    const strokeWidth = 8.0;

    // Track
    final trackPaint = Paint()
      ..color = const Color(0xFFE4F0E8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    // Active progress
    final progress = (score / 100).clamp(0.0, 1.0);
    final arcPaint = Paint()
      ..shader = const SweepGradient(
        colors: [AppColors.skyBlue, AppColors.sageGreen],
        startAngle: 0.0,
        endAngle: 2 * math.pi,
        transform: GradientRotation(-math.pi / 2),
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScoreRingPainter oldDelegate) => oldDelegate.score != score;
}
