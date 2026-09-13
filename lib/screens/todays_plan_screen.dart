import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/scenic_banner.dart';
import '../widgets/device_scanner_sheet.dart';
import 'running/running_screen.dart';
import 'running/plan_route_screen.dart';
import 'hydration_hub_screen.dart';
import 'study_screen.dart';
import 'workout/fitness_screen.dart';

class TodaysPlanScreen extends StatefulWidget {
  const TodaysPlanScreen({super.key});

  @override
  State<TodaysPlanScreen> createState() => _TodaysPlanScreenState();
}

class _TodaysPlanScreenState extends State<TodaysPlanScreen> {
  // Local plan check states
  bool _walkDone = true;
  bool _workoutDone = false;
  bool _hydrationDone = false;
  bool _studyDone = false;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final formattedDate = DateFormat('EEE, d MMM').format(DateTime.now());

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      appBar: AppBar(
        backgroundColor: AppColors.lightBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: AppColors.textPrimary, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Today's Plan",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              formattedDate,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. Plan Items List ──
            _buildPlanCard(
              title: 'Morning Walk',
              subtitle: '20 min • 5.2 km',
              icon: LucideIcons.footprints,
              iconColor: AppColors.sageGreen,
              iconBgColor: AppColors.mintLight,
              isCompleted: _walkDone,
              onToggle: () {
                HapticFeedback.selectionClick();
                setState(() => _walkDone = !_walkDone);
              },
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const RunningScreen()));
              },
            ),
            const SizedBox(height: 12),

            _buildPlanCard(
              title: '30 min Workout',
              subtitle: 'Strength + Cardio',
              icon: LucideIcons.dumbbell,
              iconColor: AppColors.accentOrange,
              iconBgColor: const Color(0xFFFEF3E8),
              isCompleted: _workoutDone,
              onToggle: () {
                HapticFeedback.selectionClick();
                setState(() => _workoutDone = !_workoutDone);
              },
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const FitnessScreen()));
              },
            ),
            const SizedBox(height: 12),

            _buildPlanCard(
              title: '2.5 L Hydration',
              subtitle: '${app.waterIntake > 0 ? app.waterIntake.toStringAsFixed(1) : "1.8"} / 2.5 L',
              icon: LucideIcons.droplets,
              iconColor: AppColors.skyBlue,
              iconBgColor: AppColors.skyLight,
              isCompleted: _hydrationDone,
              onToggle: () {
                HapticFeedback.selectionClick();
                setState(() => _hydrationDone = !_hydrationDone);
              },
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const HydrationHubScreen()));
              },
            ),
            const SizedBox(height: 12),

            _buildPlanCard(
              title: '45 min Study',
              subtitle: 'Deep Work',
              icon: LucideIcons.bookOpen,
              iconColor: AppColors.lavender,
              iconBgColor: AppColors.lavenderLight,
              isCompleted: _studyDone,
              onToggle: () {
                HapticFeedback.selectionClick();
                setState(() => _studyDone = !_studyDone);
              },
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const StudyScreen()));
              },
            ),
            const SizedBox(height: 22),

            // ── 2. Motivational Banner ──
            const MotivationalCard(
              quote: 'Discipline today\nbuilds the freedom tomorrow.',
              hasLeaf: true,
            ),
            const SizedBox(height: 26),

            // ── 3. Quick Actions ──
            Text(
              'Quick Actions',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 14),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildQuickActionButton(
                  icon: LucideIcons.mapPin,
                  iconColor: const Color(0xFFC48B68),
                  label: 'Plan Route',
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const PlanRouteScreen()));
                  },
                ),
                _buildQuickActionButton(
                  icon: LucideIcons.personStanding,
                  iconColor: AppColors.sageGreen,
                  label: 'Start Run',
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const RunningScreen()));
                  },
                ),
                _buildQuickActionButton(
                  icon: LucideIcons.watch,
                  iconColor: AppColors.skyBlue,
                  label: 'Connect\nWatch',
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const DeviceScannerSheet(),
                    );
                  },
                ),
                _buildQuickActionButton(
                  icon: LucideIcons.layoutGrid,
                  iconColor: AppColors.textSecondary,
                  label: 'More',
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required bool isCompleted,
    required VoidCallback onToggle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: AppColors.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: onToggle,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted ? AppColors.sageGreen : Colors.transparent,
                  border: Border.all(
                    color: isCompleted ? AppColors.sageGreen : const Color(0xFFD4DDD6),
                    width: 2,
                  ),
                ),
                child: isCompleted
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required Color iconColor,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.cardBorder),
              boxShadow: AppColors.cardShadow,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
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
}
