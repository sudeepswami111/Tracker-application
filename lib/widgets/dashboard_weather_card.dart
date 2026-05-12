import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../providers/weather_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'animated_card_enter.dart';

class DashboardWeatherCard extends StatefulWidget {
  const DashboardWeatherCard({super.key});

  @override
  State<DashboardWeatherCard> createState() => _DashboardWeatherCardState();
}

class _DashboardWeatherCardState extends State<DashboardWeatherCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final weather = context.watch<WeatherProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (weather.isLoading && !weather.hasData) {
      return _buildSkeleton(theme, isDark);
    }

    if (!weather.hasData) {
      return const SizedBox.shrink();
    }

    final data = weather.data!;
    final current = data.current;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Unsafe Weather Alert
        if (current.isUnsafeForOutdoor)
          _buildAlertBanner(theme),

        // 2. Main Weather Card
        GestureDetector(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.06),
              ),
              boxShadow: isDark
                  ? []
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // Weather Icon
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.solarAmber.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        current.emoji,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    
                    // Temp & Condition
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '${current.tempC.round()}°',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _buildAqiChip(theme, isDark),
                            ],
                          ),
                          Text(
                            current.conditionLabel,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Expand Arrow
                    Icon(
                      _isExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),

                // 3. Activity Suggestion
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          current.activitySuggestion,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 4. Expanded Forecast
                if (_isExpanded) ...[
                  const SizedBox(height: AppSpacing.lg),
                  const Divider(height: 1),
                  const SizedBox(height: AppSpacing.md),
                  _buildForecastRow(data.forecast),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAqiChip(ThemeData theme, bool isDark) {
    // Mocking AQI for now as requested
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.green.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.wind, size: 10, color: AppColors.green),
          const SizedBox(width: 4),
          Text(
            'AQI 42',
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.green,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertBanner(ThemeData theme) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.pulseRed.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.pulseRed.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.alertTriangle, color: AppColors.pulseRed, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Unsafe outdoor conditions detected. Stay hydrated and cautious.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.pulseRed,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForecastRow(List<dynamic> forecast) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: forecast.map((day) => Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Column(
            children: [
              Text(
                day.dayName,
                style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 4),
              Text(day.emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 4),
              Text(
                '${day.tempMax.round()}°',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              Text(
                '${day.tempMin.round()}°',
                style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
              ),
            ],
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildSkeleton(ThemeData theme, bool isDark) {
    return Container(
      height: 100,
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: const Center(child: CircularProgressIndicator.adaptive()),
    );
  }
}
