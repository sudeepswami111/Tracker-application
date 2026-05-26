import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../models/weather_model.dart';
import '../providers/weather_provider.dart';
import '../screens/weather_forecast_screen.dart';
import '../services/weather_fitness_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class DashboardWeatherSection extends StatelessWidget {
  const DashboardWeatherSection({super.key});

  @override
  Widget build(BuildContext context) {
    final weatherProvider = context.watch<WeatherProvider>();
    final weather = weatherProvider.weather;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (weatherProvider.isLoading && weather == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (weather == null) {
      return _buildErrorState(context, theme, isDark);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(weather.cityName, style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 2),
                  Text('Last updated: ${DateFormat('h:mm a').format(weather.lastFetched)}', style: theme.textTheme.labelSmall?.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(LucideIcons.refreshCw, size: 18, color: AppColors.textSecondary),
              onPressed: () => context.read<WeatherProvider>().refreshWeather(),
              tooltip: 'Force refresh weather',
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _buildWeatherInsightCard(context, weather, theme, isDark),
        const SizedBox(height: AppSpacing.xl),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text("7-Day Forecast", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WeatherForecastScreen(weather: weather),
                  ),
                );
              },
              child: const Text('View All', style: TextStyle(color: AppColors.voltCyan, fontSize: 13)),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildForecastList(weather, theme, isDark),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, ThemeData theme, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        children: [
          const Icon(LucideIcons.cloudOff, size: 32, color: AppColors.textSecondary),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Weather Unavailable',
            style: theme.textTheme.titleMedium?.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            'Please enable location services and internet.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: () => context.read<WeatherProvider>().fetchWeather(),
            child: const Text('Retry', style: TextStyle(color: AppColors.voltCyan)),
          ),
        ],
      ),
    );
  }

  IconData _getIcon(String cond, {bool isDay = true}) {
    final c = cond.toLowerCase();
    // WeatherAPI keyword matching (order matters — most specific first)
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

  Color _getAqiColor(int aqi) {
    if (aqi <= 50) return Colors.green; // Good
    if (aqi <= 100) return Colors.lightGreen; // Satisfactory
    if (aqi <= 200) return Colors.yellow; // Moderate
    if (aqi <= 300) return Colors.orange; // Poor
    if (aqi <= 400) return Colors.red; // Very Poor
    return Colors.red[900] ?? Colors.red; // Severe
  }

  Widget _buildWeatherInsightCard(BuildContext context, WeatherModel weather, ThemeData theme, bool isDark) {
    final fitnessScore = WeatherFitnessService.calculateReadiness(weather);
    final bestWindow = WeatherFitnessService.getBestWorkoutWindow(weather.hourly);
    final activities = WeatherFitnessService.getActivityChips(weather, fitnessScore);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Ring Score
              SizedBox(
                height: 70,
                width: 70,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: fitnessScore.score / 100,
                      strokeWidth: 6,
                      backgroundColor: isDark ? Colors.white12 : Colors.black12,
                      color: _getScoreColor(fitnessScore.score),
                      strokeCap: StrokeCap.round,
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${fitnessScore.score}', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        Text('Score', style: theme.textTheme.labelSmall?.copyWith(fontSize: 8)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${weather.currentTemp.round()}° ${weather.condition}', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(fitnessScore.status, style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Icon(_getIcon(weather.condition, isDay: weather.isDay), size: 36, color: AppColors.textSecondary.withValues(alpha: 0.5)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          
          // Activity Chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: activities.map((act) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.voltCyan.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(act, style: theme.textTheme.labelSmall?.copyWith(color: AppColors.voltCyan, fontWeight: FontWeight.bold)),
            )).toList(),
          ),

          const SizedBox(height: AppSpacing.md),
          
          // Should I Run Now Button
          InkWell(
            onTap: () => _showRunNowSheet(context, fitnessScore, theme, isDark),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              alignment: Alignment.center,
              child: const Text('Should I run now?', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
            ),
          ),

          const SizedBox(height: AppSpacing.md),
          Divider(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05), height: 1),
          const SizedBox(height: AppSpacing.md),

          // Risk Indicators Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildRiskIndicator(fitnessScore.heatRisk, theme),
              _buildRiskIndicator(fitnessScore.uvRisk, theme),
              _buildRiskIndicator(fitnessScore.aqiRisk, theme),
              _buildRiskIndicator(fitnessScore.rainRisk, theme),
              _buildRiskIndicator(fitnessScore.windRisk, theme),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),
          Divider(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05), height: 1),
          const SizedBox(height: AppSpacing.sm),

          // Best Window
          Row(
            children: [
              const Icon(LucideIcons.clock, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Text('Best Window: $bestWindow', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
            ],
          )
        ],
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 50) return AppColors.solarAmber;
    return AppColors.coral;
  }

  Widget _buildRiskIndicator(RiskIndicator risk, ThemeData theme) {
    Color color;
    switch(risk.level) {
      case RiskLevel.low: color = Colors.green; break;
      case RiskLevel.moderate: color = AppColors.solarAmber; break;
      case RiskLevel.high: color = AppColors.coral; break;
      case RiskLevel.extreme: color = Colors.red; break;
    }
    
    return Column(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(height: 4),
        Text(risk.label, style: theme.textTheme.labelSmall?.copyWith(fontSize: 10)),
      ],
    );
  }

  void _showRunNowSheet(BuildContext context, WeatherFitnessScore score, ThemeData theme, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Should I run now?', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Text('Answer:', style: theme.textTheme.labelMedium?.copyWith(color: AppColors.textSecondary)),
              Text(score.runRecommendation, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: _getScoreColor(score.score))),
              const SizedBox(height: 12),
              Text('Reason:', style: theme.textTheme.labelMedium?.copyWith(color: AppColors.textSecondary)),
              Text(score.runReason, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 12),
              Text('Recommended Alternatives:', style: theme.textTheme.labelMedium?.copyWith(color: AppColors.textSecondary)),
              Text(score.alternativeActivity, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Got it', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildForecastList(WeatherModel weather, ThemeData theme, bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.hardEdge,
      child: Row(
        children: weather.daily.take(4).map((day) {
          String fitnessPlan = WeatherFitnessService.getDailyFitnessPlan(day);
          Color badgeColor = AppColors.primary;
          if (fitnessPlan == 'Avoid Outdoor') {
            badgeColor = AppColors.coral;
          } else if (fitnessPlan == 'Indoor Strength' || fitnessPlan == 'Recovery Day') {
            badgeColor = AppColors.solarAmber;
          } else if (fitnessPlan == 'Best for Run' || fitnessPlan == 'Swim Day') {
            badgeColor = AppColors.voltCyan;
          } else {
            badgeColor = Colors.green;
          }

          return Container(
            width: 110,
            margin: const EdgeInsets.only(right: AppSpacing.sm),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.04),
              ),
              boxShadow: isDark ? [] : [
                BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2))
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(DateFormat('EEE').format(day.date), style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Icon(_getIcon(day.condition), size: 24, color: badgeColor),
                const SizedBox(height: 8),
                Text(
                  '${day.minTemp.round()}° / ${day.maxTemp.round()}°',
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.visible,
                ),
                const SizedBox(height: 2),
                Text(
                  '${day.precipitationProbabilityMax.round()}% Rain',
                  style: theme.textTheme.bodySmall?.copyWith(color: AppColors.voltCyan, fontSize: 10, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: badgeColor.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    fitnessPlan,
                    style: theme.textTheme.labelSmall?.copyWith(color: badgeColor, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
