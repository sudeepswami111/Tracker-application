import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../models/weather_model.dart';
import '../providers/weather_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/botanical_decorations.dart';
import 'running/running_screen.dart';
import 'workout/fitness_screen.dart';

class WeatherForecastScreen extends StatelessWidget {
  final WeatherModel? weather;

  const WeatherForecastScreen({super.key, this.weather});

  @override
  Widget build(BuildContext context) {
    final weatherProvider = context.watch<WeatherProvider>();
    final activeWeather = weather ?? weatherProvider.weather;
    final city = activeWeather != null ? activeWeather.cityName : 'Bengaluru';
    final currentTemp = activeWeather != null ? activeWeather.currentTemp.round() : 24;

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
              'Weather Forecast',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            Row(
              children: [
                const Icon(LucideIcons.mapPin, size: 12, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  city,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: SizedBox(
              width: 32,
              height: 32,
              child: CustomPaint(
                painter: BotanicalBranchPainter(
                  color: AppColors.sageGreen,
                  leafScale: 0.7,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 8),

            // ── 1. Current Weather Hero ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.cardBorder),
                boxShadow: AppColors.cardShadow,
              ),
              child: Column(
                children: [
                  // Sun Graphic
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFFF7E6),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF4A261).withValues(alpha: 0.3),
                          blurRadius: 20,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.wb_sunny_rounded,
                      size: 44,
                      color: Color(0xFFF4A261),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 24°C Sunny
                  Text(
                    '$currentTemp°C',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -1,
                    ),
                  ),
                  Text(
                    'Sunny',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Pill Badge: Best day for workout!
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5F3E8),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Best day for workout!',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.sageGreen,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // ↑ 26° / 16°
                  Text(
                    '↑ ${currentTemp + 2}° / ${currentTemp - 8}°',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── 2. 5-Day Forecast Row ──
            _buildWeeklyForecastStrip(),
            const SizedBox(height: 24),

            // ── 3. Ideal For Section ──
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Ideal for',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildIdealForCard(
                    context: context,
                    icon: LucideIcons.footprints,
                    iconColor: AppColors.sageGreen,
                    bgColor: AppColors.mintLight,
                    label: 'Running',
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const RunningScreen()));
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildIdealForCard(
                    context: context,
                    icon: LucideIcons.mountain,
                    iconColor: AppColors.skyBlue,
                    bgColor: AppColors.skyLight,
                    label: 'Outdoor',
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const RunningScreen()));
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildIdealForCard(
                    context: context,
                    icon: LucideIcons.heartPulse,
                    iconColor: AppColors.lavender,
                    bgColor: AppColors.lavenderLight,
                    label: 'Yoga',
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const FitnessScreen()));
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── 4. Cityscape Botanical Illustration Banner at Bottom ──
            _buildCityscapeBanner(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyForecastStrip() {
    final days = [
      {'day': 'Mon', 'icon': Icons.wb_sunny_rounded, 'temp': '24°', 'active': true},
      {'day': 'Tue', 'icon': Icons.wb_cloudy_rounded, 'temp': '22°', 'active': false},
      {'day': 'Wed', 'icon': Icons.grain_rounded, 'temp': '21°', 'active': false},
      {'day': 'Thu', 'icon': Icons.wb_sunny_rounded, 'temp': '23°', 'active': false},
      {'day': 'Fri', 'icon': Icons.wb_sunny_rounded, 'temp': '24°', 'active': false},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: days.map((d) {
          final isToday = d['active'] == true;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: isToday ? const Color(0xFFF3F7F4) : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Text(
                  d['day'] as String,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                    color: isToday ? AppColors.forestGreen : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Icon(
                  d['icon'] as IconData,
                  size: 20,
                  color: isToday ? const Color(0xFFF4A261) : AppColors.textSecondary,
                ),
                const SizedBox(height: 8),
                Text(
                  d['temp'] as String,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildIdealForCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCityscapeBanner() {
    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFFE8D5C4), Color(0xFF7BAE96), Color(0xFF2E533F)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            Positioned(
              left: 20,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Clean air & gentle breeze',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Perfect time for an outdoor walk',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
