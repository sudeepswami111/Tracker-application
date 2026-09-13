import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_colors.dart';
import 'steps_screen.dart';
import 'todays_plan_screen.dart';
import 'hydration_hub_screen.dart';
import 'weather_forecast_screen.dart';
import 'running/running_screen.dart';
import 'running/plan_route_screen.dart';
import 'health_screen.dart';
import 'milestones_screen.dart';
import 'calendar_screen.dart';
import 'study_screen.dart';
import 'workout/fitness_screen.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sections = [
      {
        'title': 'Steps & Movement',
        'subtitle': 'Daily step tracker & activity graphs',
        'icon': LucideIcons.footprints,
        'iconColor': AppColors.sageGreen,
        'bgColor': AppColors.mintLight,
        'screen': const StepsScreen(),
      },
      {
        'title': "Today's Plan",
        'subtitle': 'Personal schedule & daily goals',
        'icon': LucideIcons.calendarCheck,
        'iconColor': AppColors.accentOrange,
        'bgColor': const Color(0xFFFEF3E8),
        'screen': const TodaysPlanScreen(),
      },
      {
        'title': 'Hydration Hub',
        'subtitle': 'Water intake logger & tips',
        'icon': LucideIcons.droplets,
        'iconColor': AppColors.skyBlue,
        'bgColor': AppColors.skyLight,
        'screen': const HydrationHubScreen(),
      },
      {
        'title': 'Weather Forecast',
        'subtitle': 'Weather-based workout advice',
        'icon': LucideIcons.sunMedium,
        'iconColor': const Color(0xFFF4A261),
        'bgColor': const Color(0xFFFFF7E6),
        'screen': const WeatherForecastScreen(),
      },
      {
        'title': 'Running & Outdoor',
        'subtitle': 'Live route tracking & GPS maps',
        'icon': LucideIcons.mountain,
        'iconColor': AppColors.forestGreen,
        'bgColor': const Color(0xFFE4F0E8),
        'screen': const RunningScreen(),
      },
      {
        'title': 'Plan Route',
        'subtitle': 'Scenic, fastest & traffic-free routes',
        'icon': LucideIcons.mapPin,
        'iconColor': const Color(0xFFC48B68),
        'bgColor': const Color(0xFFFDF0E6),
        'screen': const PlanRouteScreen(),
      },
      {
        'title': 'Health Metrics',
        'subtitle': 'Heart rate, SpO2, sleep & trends',
        'icon': LucideIcons.heartPulse,
        'iconColor': AppColors.accentPeach,
        'bgColor': const Color(0xFFFDECE6),
        'screen': const HealthScreen(),
      },
      {
        'title': 'Milestones & Trophies',
        'subtitle': 'Unlock badges & celebrate achievements',
        'icon': LucideIcons.trophy,
        'iconColor': AppColors.accentGold,
        'bgColor': const Color(0xFFFFF7E0),
        'screen': const MilestonesScreen(),
      },
      {
        'title': 'Calendar & History',
        'subtitle': 'Monthly activity & routine log',
        'icon': LucideIcons.calendar,
        'iconColor': AppColors.lavender,
        'bgColor': AppColors.lavenderLight,
        'screen': const CalendarScreen(),
      },
      {
        'title': 'Study & Focus Timer',
        'subtitle': 'Deep work sessions & study planner',
        'icon': LucideIcons.bookOpen,
        'iconColor': AppColors.lavender,
        'bgColor': AppColors.lavenderLight,
        'screen': const StudyScreen(),
      },
      {
        'title': 'Fitness & Workouts',
        'subtitle': 'Guided workouts & exercise routines',
        'icon': LucideIcons.dumbbell,
        'iconColor': AppColors.sageGreen,
        'bgColor': AppColors.mintLight,
        'screen': const FitnessScreen(),
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      appBar: AppBar(
        backgroundColor: AppColors.lightBg,
        elevation: 0,
        title: Text(
          'Explore',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        itemCount: sections.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final s = sections[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => s['screen'] as Widget));
            },
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
                      color: s['bgColor'] as Color,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      s['icon'] as IconData,
                      size: 20,
                      color: s['iconColor'] as Color,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s['title'] as String,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          s['subtitle'] as String,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(LucideIcons.chevronRight, size: 16, color: AppColors.neutralGray),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
