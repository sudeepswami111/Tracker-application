import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/weather_model.dart';
import '../services/weather_fitness_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/weather_widgets.dart';

class WeatherForecastScreen extends StatelessWidget {
  final WeatherModel weather;

  const WeatherForecastScreen({
    super.key,
    required this.weather,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0F1D) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          '7-Day Biomet Forecast',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            letterSpacing: -0.2,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.chevronLeft, size: 18),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        children: [
          // ── Location & Summary Hero Banner ──
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: isDark
                  ? const LinearGradient(
                      colors: [Color(0xFF0F1729), Color(0xFF131F3A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : const LinearGradient(
                      colors: [Color(0xFFEEF2FF), Color(0xFFE0E7FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              border: Border.all(
                color: AppColors.voltCyan.withValues(alpha: 0.25),
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.voltCyan.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.cloudSun, size: 24, color: AppColors.voltCyan),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        weather.cityName,
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Weekly Biometeorological Conditioning Outlook',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          Text(
            'DAILY BIOMET TIMELINE',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: isDark ? Colors.white38 : Colors.black45,
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          ...weather.daily.asMap().entries.map((entry) {
            final index = entry.key;
            final day = entry.value;
            final isToday = index == 0;

            String fitnessPlan = WeatherFitnessService.getDailyFitnessPlan(day);
            Color badgeColor;
            IconData planIcon;

            if (fitnessPlan == 'Avoid Outdoor') {
              badgeColor = const Color(0xFFFF4D6D);
              planIcon = LucideIcons.shieldAlert;
            } else if (fitnessPlan == 'Indoor Strength' || fitnessPlan == 'Recovery Day') {
              badgeColor = const Color(0xFFF59E0B);
              planIcon = LucideIcons.dumbbell;
            } else if (fitnessPlan == 'Best for Run' || fitnessPlan == 'Swim Day') {
              badgeColor = AppColors.voltCyan;
              planIcon = fitnessPlan == 'Swim Day' ? LucideIcons.waves : LucideIcons.zap;
            } else {
              badgeColor = const Color(0xFF22C55E);
              planIcon = LucideIcons.activity;
            }

            final dateStr = isToday ? "TODAY" : DateFormat('EEEE, MMM d').format(day.date).toUpperCase();

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F1729) : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isToday
                      ? AppColors.voltCyan.withValues(alpha: 0.45)
                      : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.06)),
                  width: isToday ? 1.5 : 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isToday
                        ? AppColors.voltCyan.withValues(alpha: isDark ? 0.08 : 0.12)
                        : Colors.black.withValues(alpha: isDark ? 0.06 : 0.03),
                    blurRadius: isToday ? 12 : 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Weather Icon
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: badgeColor.withValues(alpha: 0.12),
                          border: Border.all(
                            color: badgeColor.withValues(alpha: 0.25),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          DashboardWeatherSection.getConditionIcon(day.condition),
                          size: 22,
                          color: badgeColor,
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Day info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  dateStr,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: isToday ? AppColors.voltCyan : (isDark ? Colors.white : Colors.black87),
                                  ),
                                ),
                                if (isToday) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.voltCyan.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'CURRENT',
                                      style: GoogleFonts.inter(
                                        fontSize: 8,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.voltCyan,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              day.condition,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: isDark ? Colors.white54 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Athletic directive tag
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: badgeColor.withValues(alpha: 0.35)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(planIcon, size: 12, color: badgeColor),
                            const SizedBox(width: 6),
                            Text(
                              fitnessPlan,
                              style: GoogleFonts.inter(
                                color: badgeColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 10,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),
                  Divider(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                    height: 1,
                  ),
                  const SizedBox(height: 12),

                  // Metrics telemetry grid
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMetricStrip(
                        'TEMPERATURE',
                        '${day.maxTemp.round()}° / ${day.minTemp.round()}°',
                        LucideIcons.thermometer,
                        AppColors.solarAmber,
                        isDark,
                      ),
                      _buildMetricStrip(
                        'RAIN RISK',
                        '${day.precipitationProbabilityMax.round()}%',
                        LucideIcons.droplets,
                        AppColors.voltCyan,
                        isDark,
                      ),
                      _buildMetricStrip(
                        'UV INDEX',
                        '${day.uvIndexMax.round()} Max',
                        LucideIcons.sun,
                        const Color(0xFFF59E0B),
                        isDark,
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMetricStrip(String label, String val, IconData icon, Color color, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 5),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              val,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 7,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white38 : Colors.black45,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
