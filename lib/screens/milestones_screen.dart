import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_colors.dart';
import '../widgets/botanical_decorations.dart';

class MilestonesScreen extends StatefulWidget {
  const MilestonesScreen({super.key});

  @override
  State<MilestonesScreen> createState() => _MilestonesScreenState();
}

class _MilestonesScreenState extends State<MilestonesScreen> {
  int _selectedTab = 0; // 0: Milestones, 1: Trophies

  @override
  Widget build(BuildContext context) {
    final milestones = [
      {
        'title': '10K Steps',
        'subtitle': 'Completed',
        'isDone': true,
        'icon': LucideIcons.footprints,
        'iconColor': AppColors.sageGreen,
        'iconBgColor': AppColors.mintLight,
      },
      {
        'title': '2.5L Hydration',
        'subtitle': 'Completed',
        'isDone': true,
        'icon': LucideIcons.droplets,
        'iconColor': AppColors.skyBlue,
        'iconBgColor': AppColors.skyLight,
      },
      {
        'title': '7 Day Streak',
        'subtitle': 'Completed',
        'isDone': true,
        'icon': LucideIcons.flame,
        'iconColor': AppColors.accentOrange,
        'iconBgColor': const Color(0xFFFEF3E8),
      },
      {
        'title': '5 km Run',
        'subtitle': 'Next yet',
        'isDone': false,
        'icon': LucideIcons.lock,
        'iconColor': AppColors.textSecondary,
        'iconBgColor': const Color(0xFFF0EBE0),
      },
      {
        'title': 'Study Champion',
        'subtitle': 'Next yet',
        'isDone': false,
        'icon': LucideIcons.lock,
        'iconColor': AppColors.textSecondary,
        'iconBgColor': const Color(0xFFF0EBE0),
      },
    ];

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
          'Milestones & Trophies',
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
            // ── 1. Segmented Tabs: Milestones | Trophies ──
            SegmentedPillTabs(
              tabs: const ['Milestones', 'Trophies'],
              selectedIndex: _selectedTab,
              onTabSelected: (index) {
                HapticFeedback.selectionClick();
                setState(() => _selectedTab = index);
              },
            ),
            const SizedBox(height: 20),

            // ── 2. Glowing Dark Forest Green Hexagon Hero Badge ──
            const HexagonMilestoneBadge(
              count: 8,
              label: 'Total Milestones',
            ),
            const SizedBox(height: 24),

            // ── 3. Milestones List Items ──
            ...milestones.map((m) {
              final isDone = m['isDone'] == true;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
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
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: m['iconBgColor'] as Color,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          m['icon'] as IconData,
                          size: 18,
                          color: m['iconColor'] as Color,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              m['title'] as String,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              m['subtitle'] as String,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDone ? AppColors.sageGreen : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        LucideIcons.chevronRight,
                        size: 18,
                        color: AppColors.neutralGray,
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),

            // ── 4. Motivational Trophy Card in Dark Green ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.forestGreen,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.forestGreen.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.trophy,
                      color: Color(0xFFF4C542),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "You're doing amazing!",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Keep collecting those milestones!',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.8),
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
}
