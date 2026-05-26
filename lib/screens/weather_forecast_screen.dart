import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../models/weather_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class WeatherForecastScreen extends StatelessWidget {
  final WeatherModel weather;

  const WeatherForecastScreen({
    super.key,
    required this.weather,
  });

  IconData _getIcon(String cond, {bool isDay = true}) {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('7-Day Forecast'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        itemCount: weather.daily.length,
        itemBuilder: (context, index) {
          final day = weather.daily[index];
          
          bool isAvoid = false;
          bool isCaution = false;

          if (day.weatherCode == 95 || day.weatherCode == 96 || day.weatherCode == 99) isAvoid = true;
          if (day.maxTemp >= 40) isCaution = true;
          if (day.uvIndexMax >= 8) isCaution = true;
          if (day.precipitationProbabilityMax >= 70) isCaution = true;

          Color badgeColor = AppColors.primary;
          String badgeText = "Great";

          if (isAvoid) {
            badgeColor = AppColors.coral;
            badgeText = "Avoid";
          } else if (isCaution) {
            badgeColor = AppColors.solarAmber;
            badgeText = "Caution";
          } else if (day.maxTemp > 30 || day.precipitationProbabilityMax > 20) {
            badgeColor = AppColors.voltCyan;
            badgeText = "Good";
          } else {
            badgeColor = Colors.green;
            badgeText = "Great";
          }

          final dateStr = index == 0 ? "Today" : DateFormat('EEEE, MMM d').format(day.date);

          return Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            padding: const EdgeInsets.all(AppSpacing.md),
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
            child: Row(
              children: [
                Icon(_getIcon(day.condition), size: 36, color: badgeColor),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(dateStr, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        day.condition,
                        style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 12,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(LucideIcons.thermometer, size: 14, color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Text(
                                '${day.minTemp.round()}° / ${day.maxTemp.round()}°',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(LucideIcons.droplets, size: 14, color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Text(
                                '${day.precipitationProbabilityMax.round()}%',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(LucideIcons.sun, size: 14, color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Text(
                                'UV ${day.uvIndexMax.round()}',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: badgeColor.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    badgeText,
                    style: theme.textTheme.labelMedium?.copyWith(color: badgeColor, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
