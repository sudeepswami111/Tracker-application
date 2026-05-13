import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../models/weather_model.dart';
import '../providers/weather_provider.dart';
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
        // 1. Combined Weather + Insights Card
        Text("Weather & Activity", style: theme.textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.md),
        _buildWeatherInsightCard(weather, theme, isDark),
        const SizedBox(height: AppSpacing.xl),

        // 2. 7-Day Forecast (Horizontal Carousel)
        Text("7-Day Forecast", style: theme.textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.md),
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

  IconData _getIcon(String cond) {
    final c = cond.toLowerCase();
    if (c.contains('thunder')) return LucideIcons.cloudLightning;
    if (c.contains('snow')) return LucideIcons.snowflake;
    if (c.contains('rain') || c.contains('drizzle')) return LucideIcons.cloudRain;
    if (c.contains('cloud')) return LucideIcons.cloud;
    return LucideIcons.sun;
  }

  Color _getAqiColor(int aqi) {
    if (aqi <= 50) return AppColors.primary; // Good
    if (aqi <= 100) return AppColors.solarAmber; // Moderate
    return AppColors.coral; // Unhealthy
  }

  Widget _buildWeatherInsightCard(WeatherModel weather, ThemeData theme, bool isDark) {
    // ── Insight Logic ──
    final bool isHot = weather.currentTemp > 30;
    final bool isRainy = weather.condition.toLowerCase().contains('rain');
    final bool isBadAir = weather.aqi > 100;

    String insightTitle = "Perfect weather for a run!";
    IconData insightIcon = LucideIcons.checkCircle;
    Color insightColor = AppColors.primary;
    String bestTime = "Anytime";
    String intensity = "High";
    String hydration = "Normal | Drink to thirst";

    if (isHot) {
      insightTitle = "Hot outside. Swim or light jog.";
      insightIcon = LucideIcons.alertTriangle;
      insightColor = AppColors.solarAmber;
      bestTime = "After 7 PM";
      intensity = "Moderate";
      hydration = "High Risk | Drink 500ml/hr";
    } else if (isBadAir) {
      insightTitle = "Poor air quality. Train indoors.";
      insightIcon = LucideIcons.alertTriangle;
      insightColor = AppColors.coral;
      bestTime = "Indoor Gym";
      intensity = "Moderate";
      hydration = "Normal";
    } else if (isRainy) {
      insightTitle = "Rain expected. Bring a jacket.";
      insightIcon = LucideIcons.cloudRain;
      insightColor = AppColors.voltCyan;
      bestTime = "Indoor";
      intensity = "Variable";
      hydration = "Normal";
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: insightColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          // ── TOP: Weather Row ──
          Row(
            children: [
              Icon(_getIcon(weather.condition), size: 38, color: AppColors.textSecondary),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${weather.currentTemp.round()}°', style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold, height: 1)),
                    Text(weather.condition, style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getAqiColor(weather.aqi).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
                  border: Border.all(color: _getAqiColor(weather.aqi).withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Text('AQI', style: theme.textTheme.labelSmall?.copyWith(color: _getAqiColor(weather.aqi), fontSize: 10)),
                    Text('${weather.aqi}', style: theme.textTheme.titleMedium?.copyWith(color: _getAqiColor(weather.aqi), fontWeight: FontWeight.bold, height: 1.1)),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),
          Divider(color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06), height: 1),
          const SizedBox(height: AppSpacing.md),

          // ── BOTTOM: Insights Row ──
          Row(
            children: [
              Icon(insightIcon, color: insightColor, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(insightTitle, style: theme.textTheme.bodyMedium?.copyWith(color: insightColor, fontWeight: FontWeight.bold)),
                    Text('Based on ${weather.currentTemp.round()}° & AQI ${weather.aqi}', style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(child: _buildInsightDetail(LucideIcons.clock, 'Best Time', bestTime, theme)),
              Expanded(child: _buildInsightDetail(LucideIcons.activity, 'Intensity', intensity, theme)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildInsightDetail(LucideIcons.droplets, 'Hydration', hydration, theme),
        ],
      ),
    );
  }

  Widget _buildInsightDetail(IconData icon, String label, String value, ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.labelSmall?.copyWith(color: AppColors.textSecondary, fontSize: 10)),
              Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildForecastList(WeatherModel weather, ThemeData theme, bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: weather.daily.map((day) {
          final bool isBad = day.weatherCode >= 61 || day.maxTemp > 35; // Rain or very hot
          final bool isCaution = day.maxTemp > 30 || day.minTemp < 5;
          
          Color badgeColor = AppColors.primary;
          String badgeText = "Safe";
          
          if (isBad) {
            badgeColor = AppColors.coral;
            badgeText = "Avoid";
          } else if (isCaution) {
            badgeColor = AppColors.solarAmber;
            badgeText = "Caution";
          }

          return Container(
            width: 100,
            margin: const EdgeInsets.only(right: AppSpacing.sm),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
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
                Text(DateFormat('EEE').format(day.date), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Icon(_getIcon(day.condition), size: 28, color: badgeColor),
                const SizedBox(height: 12),
                Text(
                  '${day.minTemp.round()}° / ${day.maxTemp.round()}°',
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  day.condition,
                  style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary, fontSize: 10),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: badgeColor.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    badgeText,
                    style: theme.textTheme.labelSmall?.copyWith(color: badgeColor, fontSize: 10, fontWeight: FontWeight.bold),
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
