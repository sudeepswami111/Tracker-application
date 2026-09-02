import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/weather_model.dart';
import '../providers/weather_provider.dart';
import '../screens/weather_forecast_screen.dart';
import '../services/weather_fitness_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class DashboardWeatherSection extends StatefulWidget {
  const DashboardWeatherSection({super.key});

  static IconData getConditionIcon(String cond, {bool isDay = true}) {
    final c = cond.toLowerCase();
    if (c.contains('thunder') || c.contains('lightning')) return LucideIcons.cloudLightning;
    if (c.contains('blizzard') || c.contains('sleet') || c.contains('ice pellet')) return LucideIcons.snowflake;
    if (c.contains('snow') || c.contains('flurr')) return LucideIcons.snowflake;
    if (c.contains('drizzle')) return LucideIcons.cloudDrizzle;
    if (c.contains('shower') || c.contains('rain')) return LucideIcons.cloudRain;
    if (c.contains('fog') || c.contains('mist') || c.contains('freezing fog')) return LucideIcons.cloudFog;
    if (c.contains('haz') || c.contains('smoke') || c.contains('dust') || c.contains('sand')) return LucideIcons.cloudFog;
    if (c.contains('overcast')) return LucideIcons.cloud;
    if (c.contains('cloud') || c.contains('partly') || c.contains('mostly')) {
      return isDay ? LucideIcons.cloudSun : LucideIcons.cloudMoon;
    }
    if (c.contains('clear') || c.contains('sunny')) return isDay ? LucideIcons.sun : LucideIcons.moon;
    return isDay ? LucideIcons.sun : LucideIcons.moon;
  }

  @override
  State<DashboardWeatherSection> createState() => _DashboardWeatherSectionState();
}

class _DashboardWeatherSectionState extends State<DashboardWeatherSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _refreshController;

  @override
  void initState() {
    super.initState();
    _refreshController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  void _triggerRefresh(BuildContext context) {
    _refreshController.forward(from: 0);
    context.read<WeatherProvider>().refreshWeather();
  }

  @override
  Widget build(BuildContext context) {
    final weatherProvider = context.watch<WeatherProvider>();
    final weather = weatherProvider.weather;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (weatherProvider.isLoading && weather == null) {
      return _buildLoadingSkeleton(isDark);
    }

    if (weather == null) {
      return _buildErrorState(context, theme, isDark);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Location & Telemetry Header ──
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.voltCyan.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.voltCyan.withValues(alpha: 0.35),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      LucideIcons.mapPin,
                      size: 15,
                      color: AppColors.voltCyan,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          weather.cityName,
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : Colors.black87,
                            letterSpacing: -0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: AppColors.voltCyan,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.voltCyan.withValues(alpha: 0.7),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Updated ${DateFormat('h:mm a').format(weather.lastFetched)}',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.white38 : Colors.black45,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => _triggerRefresh(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08),
                  ),
                ),
                child: RotationTransition(
                  turns: _refreshController,
                  child: const Icon(
                    LucideIcons.refreshCw,
                    size: 16,
                    color: AppColors.voltCyan,
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.md),

        // ── Main Biometeorology Command Deck ──
        _buildWeatherInsightCard(context, weather, theme, isDark),

        const SizedBox(height: AppSpacing.xl),

        // ── 7-Day Forecast Runway Header ──
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              children: [
                Container(
                  width: 3,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppColors.voltCyan,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "7-Day Biomet Forecast",
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black87,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WeatherForecastScreen(weather: weather),
                  ),
                );
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Full Deck',
                    style: GoogleFonts.inter(
                      color: AppColors.voltCyan,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(LucideIcons.chevronRight, size: 14, color: AppColors.voltCyan),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildForecastRunway(context, weather, theme, isDark),
      ],
    );
  }

  Widget _buildLoadingSkeleton(bool isDark) {
    return Container(
      width: double.infinity,
      height: 260,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F1729) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation(AppColors.voltCyan),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Acquiring Biometeorology Telemetry...',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, ThemeData theme, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F1729) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.coral.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.coral.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.cloudOff, size: 28, color: AppColors.coral),
          ),
          const SizedBox(height: 12),
          Text(
            'Weather Telemetry Offline',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Enable location services & connectivity to access biometeorological data.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: () => context.read<WeatherProvider>().fetchWeather(),
            icon: const Icon(LucideIcons.refreshCw, size: 14),
            label: const Text('Re-establish Link'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.voltCyan,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherInsightCard(BuildContext context, WeatherModel weather, ThemeData theme, bool isDark) {
    final fitnessScore = WeatherFitnessService.calculateReadiness(weather);
    final bestWindow = WeatherFitnessService.getBestWorkoutWindow(weather.hourly);
    final activities = WeatherFitnessService.getActivityChips(weather, fitnessScore);
    final scoreColor = _getScoreColor(fitnessScore.score);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: isDark
            ? const LinearGradient(
                colors: [Color(0xFF0F1729), Color(0xFF090E1A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [Color(0xFFF9FAFD), Color(0xFFEEF2FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        border: Border.all(
          color: scoreColor.withValues(alpha: isDark ? 0.2 : 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: scoreColor.withValues(alpha: isDark ? 0.08 : 0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // Top neon velocity stripe
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 3,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      scoreColor.withValues(alpha: 0.1),
                      scoreColor,
                      AppColors.voltCyan,
                      scoreColor.withValues(alpha: 0.1),
                    ],
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Top Telemetry Sub-strip ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: scoreColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: scoreColor.withValues(alpha: 0.35),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.radio, size: 10, color: scoreColor),
                            const SizedBox(width: 5),
                            Text(
                              'BIOMET INTEL',
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                                color: scoreColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          weather.isDay ? '☀️ DAYTIME' : '🌙 NIGHT',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                            color: isDark ? Colors.white54 : Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // ── Dual Instrument Matrix: Score Gauge + Temp/Condition HUD ──
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Radial Score Gauge
                      SizedBox(
                        width: 86,
                        height: 86,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CustomPaint(
                              size: const Size(86, 86),
                              painter: _WeatherScoreArcPainter(
                                score: fitnessScore.score,
                                color: scoreColor,
                                isDark: isDark,
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${fitnessScore.score}',
                                  style: GoogleFonts.inter(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900,
                                    color: isDark ? Colors.white : Colors.black87,
                                    height: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'SCORE',
                                  style: GoogleFonts.inter(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.2,
                                    color: scoreColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 18),

                      // Weather Readout Column
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${weather.currentTemp.round()}°',
                                  style: GoogleFonts.inter(
                                    fontSize: 38,
                                    fontWeight: FontWeight.w900,
                                    color: isDark ? Colors.white : Colors.black87,
                                    height: 1.0,
                                    letterSpacing: -1,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: AppColors.voltCyan.withValues(alpha: 0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      DashboardWeatherSection.getConditionIcon(weather.condition, isDay: weather.isDay),
                                      size: 22,
                                      color: AppColors.voltCyan,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              weather.condition,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Feels like ${weather.currentApparentTemp.round()}° • Wind ${weather.windSpeed.round()} km/h',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: isDark ? Colors.white38 : Colors.black45,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ── AI Atmosphere Status Banner ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: scoreColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: scoreColor.withValues(alpha: 0.25),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(LucideIcons.sparkles, size: 14, color: scoreColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            fitnessScore.status,
                            style: GoogleFonts.inter(
                              color: scoreColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ── Activity Recommendation Chips ──
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: activities.map((act) {
                        return Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.12),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_getActivityEmoji(act), style: const TextStyle(fontSize: 12)),
                              const SizedBox(width: 6),
                              Text(
                                act,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white70 : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Futuristic "Run Intel Radar" Action Hero ──
                  GestureDetector(
                    onTap: () => _showRunNowSheet(context, fitnessScore, theme, isDark),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.voltCyan.withValues(alpha: 0.2),
                            AppColors.voltCyan.withValues(alpha: 0.08),
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.voltCyan.withValues(alpha: 0.4),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.voltCyan.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              LucideIcons.compass,
                              size: 16,
                              color: AppColors.voltCyan,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'RUN INTEL ADVISOR',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.2,
                                    color: AppColors.voltCyan,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Should I run now? • Tap for AI biometric diagnosis',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? Colors.white70 : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            LucideIcons.chevronRight,
                            size: 18,
                            color: AppColors.voltCyan,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  Divider(
                    color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06),
                    height: 1,
                  ),
                  const SizedBox(height: 14),

                  // ── 5-Sensor Atmospheric Vitals Matrix ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSensorCell('Heat', fitnessScore.heatRisk, LucideIcons.flame, isDark),
                      _buildSensorCell('UV', fitnessScore.uvRisk, LucideIcons.sunMedium, isDark),
                      _buildSensorCell('AQI', fitnessScore.aqiRisk, LucideIcons.wind, isDark),
                      _buildSensorCell('Rain', fitnessScore.rainRisk, LucideIcons.cloudRain, isDark),
                      _buildSensorCell('Wind', fitnessScore.windRisk, LucideIcons.gauge, isDark),
                    ],
                  ),

                  const SizedBox(height: 14),
                  Divider(
                    color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06),
                    height: 1,
                  ),
                  const SizedBox(height: 12),

                  // ── Chrono Best Workout Window ──
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(LucideIcons.clock, size: 14, color: AppColors.primary),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'BEST WORKOUT WINDOW',
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                                color: isDark ? Colors.white38 : Colors.black45,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              bestWindow,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (bestWindow != 'Try tomorrow' && bestWindow != 'No data')
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF22C55E).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: const Color(0xFF22C55E).withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'OPTIMAL',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF22C55E),
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getActivityEmoji(String act) {
    final a = act.toLowerCase();
    if (a.contains('swim')) return '🏊‍♂️';
    if (a.contains('run') || a.contains('jog')) return '🏃‍♂️';
    if (a.contains('walk')) return '🚶‍♂️';
    if (a.contains('gym') || a.contains('strength')) return '🏋️‍♂️';
    if (a.contains('cycl') || a.contains('bike')) return '🚴‍♂️';
    if (a.contains('yoga') || a.contains('stretch')) return '🧘‍♂️';
    return '⚡';
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return const Color(0xFF22C55E); // Emerald
    if (score >= 50) return const Color(0xFFF59E0B); // Amber
    return const Color(0xFFFF4D6D); // Coral
  }

  Widget _buildSensorCell(String title, RiskIndicator risk, IconData icon, bool isDark) {
    Color color;
    String levelText;
    switch (risk.level) {
      case RiskLevel.low:
        color = const Color(0xFF22C55E);
        levelText = 'Low';
        break;
      case RiskLevel.moderate:
        color = const Color(0xFFF59E0B);
        levelText = 'Mod';
        break;
      case RiskLevel.high:
        color = const Color(0xFFFF4D6D);
        levelText = 'High';
        break;
      case RiskLevel.extreme:
        color = const Color(0xFFEF4444);
        levelText = 'Ext';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.2 : 0.25),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 14, color: isDark ? Colors.white54 : Colors.black54),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white38 : Colors.black45,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              levelText,
              style: GoogleFonts.inter(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRunNowSheet(BuildContext context, WeatherFitnessScore score, ThemeData theme, bool isDark) {
    final scoreColor = _getScoreColor(score.score);

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF0F1729) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: scoreColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(LucideIcons.compass, size: 20, color: scoreColor),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Biometeorology Diagnosis',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'AI VERDICT',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: isDark ? Colors.white38 : Colors.black45,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                score.runRecommendation,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: scoreColor,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'PHYSIOLOGICAL RATIONALE',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: isDark ? Colors.white38 : Colors.black45,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                score.runReason,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: isDark ? Colors.white70 : Colors.black87,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'RECOMMENDED ALTERNATIVES',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: isDark ? Colors.white38 : Colors.black45,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                score.alternativeActivity,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.voltCyan,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.voltCyan,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    'ACKNOWLEDGE',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Redesigned Interactive 7-Day Forecast Runway ──
  Widget _buildForecastRunway(BuildContext context, WeatherModel weather, ThemeData theme, bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: weather.daily.asMap().entries.map((entry) {
          final index = entry.key;
          final day = entry.value;
          final isToday = index == 0;
          final isTomorrow = index == 1;

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

          final dayLabel = isToday
              ? 'TODAY'
              : (isTomorrow ? 'TMRW' : DateFormat('EEE').format(day.date).toUpperCase());
          final dateNumber = DateFormat('d MMM').format(day.date);

          return GestureDetector(
            onTap: () => _showDayDetailSheet(context, day, fitnessPlan, badgeColor, isDark),
            child: Container(
              width: 122,
              margin: const EdgeInsets.only(right: 12, top: 4, bottom: 6),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: isDark
                    ? LinearGradient(
                        colors: isToday
                            ? [const Color(0xFF131F3A), const Color(0xFF0C1426)]
                            : [const Color(0xFF0F1729), const Color(0xFF0A0F1D)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : LinearGradient(
                        colors: isToday
                            ? [const Color(0xFFEFF6FF), const Color(0xFFDBEAFE)]
                            : [Colors.white, const Color(0xFFF8FAFC)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                border: Border.all(
                  color: isToday
                      ? AppColors.voltCyan.withValues(alpha: 0.5)
                      : (isDark ? Colors.white.withValues(alpha: 0.07) : Colors.black.withValues(alpha: 0.07)),
                  width: isToday ? 1.5 : 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isToday
                        ? AppColors.voltCyan.withValues(alpha: isDark ? 0.12 : 0.18)
                        : Colors.black.withValues(alpha: isDark ? 0.1 : 0.04),
                    blurRadius: isToday ? 14 : 6,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. Day Tag & Date
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        dayLabel,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                          color: isToday ? AppColors.voltCyan : (isDark ? Colors.white70 : Colors.black87),
                        ),
                      ),
                      Text(
                        dateNumber,
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white38 : Colors.black45,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // 2. Glowing Weather Icon
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
                      boxShadow: [
                        BoxShadow(
                          color: badgeColor.withValues(alpha: 0.2),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Icon(
                      DashboardWeatherSection.getConditionIcon(day.condition),
                      size: 22,
                      color: badgeColor,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // 3. Thermal Bar & Range
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${day.maxTemp.round()}°',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '/',
                        style: TextStyle(
                          color: isDark ? Colors.white30 : Colors.black26,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${day.minTemp.round()}°',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // Thermal gradient visual micro-bar
                  Container(
                    height: 4,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF38BDF8),
                          badgeColor,
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // 4. Precipitation Risk Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.droplets, size: 10, color: AppColors.voltCyan),
                        const SizedBox(width: 4),
                        Text(
                          '${day.precipitationProbabilityMax.round()}% Rain',
                          style: GoogleFonts.inter(
                            color: AppColors.voltCyan,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // 5. Athletic Protocol Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: badgeColor.withValues(alpha: 0.35)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(planIcon, size: 10, color: badgeColor),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            fitnessPlan,
                            style: GoogleFonts.inter(
                              color: badgeColor,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showDayDetailSheet(BuildContext context, DailyForecast day, String fitnessPlan, Color badgeColor, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF0F1729) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('EEEE, MMMM d').format(day.date),
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        day.condition,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(DashboardWeatherSection.getConditionIcon(day.condition), size: 24, color: badgeColor),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Metric HUD matrix
              Row(
                children: [
                  Expanded(
                    child: _buildDetailTile(
                      'HIGH / LOW',
                      '${day.maxTemp.round()}° / ${day.minTemp.round()}°',
                      LucideIcons.thermometer,
                      AppColors.solarAmber,
                      isDark,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildDetailTile(
                      'PRECIPITATION',
                      '${day.precipitationProbabilityMax.round()}%',
                      LucideIcons.cloudRain,
                      AppColors.voltCyan,
                      isDark,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildDetailTile(
                      'UV INDEX',
                      '${day.uvIndexMax.round()}',
                      LucideIcons.sun,
                      const Color(0xFFF59E0B),
                      isDark,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Text(
                'AI ATHLETIC RECOMMENDATION',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: isDark ? Colors.white38 : Colors.black45,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.sparkles, size: 16, color: badgeColor),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '$fitnessPlan — Optimal conditions for this day\'s training window.',
                        style: GoogleFonts.inter(
                          color: badgeColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.voltCyan,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    'CLOSE PROTOCOL',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailTile(String label, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 8,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white38 : Colors.black45,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Custom Circular Arc Painter for Weather Score ──
class _WeatherScoreArcPainter extends CustomPainter {
  final int score;
  final Color color;
  final bool isDark;

  _WeatherScoreArcPainter({
    required this.score,
    required this.color,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 10) / 2;
    final progress = (score / 100).clamp(0.0, 1.0);

    // Track
    final trackPaint = Paint()
      ..color = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    // Active Glow
    if (progress > 0.01) {
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        2 * pi * progress,
        false,
        glowPaint,
      );

      // Main Arc
      final arcPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        2 * pi * progress,
        false,
        arcPaint,
      );

      // Arc Head Dot
      final angle = -pi / 2 + 2 * pi * progress;
      final dotPos = Offset(center.dx + radius * cos(angle), center.dy + radius * sin(angle));
      canvas.drawCircle(dotPos, 4, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant _WeatherScoreArcPainter oldDelegate) =>
      oldDelegate.score != score || oldDelegate.color != color || oldDelegate.isDark != isDark;
}
