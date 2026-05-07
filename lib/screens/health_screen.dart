import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/app_provider.dart';
import '../widgets/glass_card.dart';
import '../theme/app_colors.dart';
import '../widgets/watch_connect_banner.dart';
import '../widgets/watch_dashboard.dart';
import '../providers/watch_metrics_provider.dart';

class HealthScreen extends StatefulWidget {
  const HealthScreen({super.key});

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen> {
  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final watch = context.watch<WatchMetricsProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Health Monitor', style: theme.textTheme.displayLarge),
          const SizedBox(height: 4),
          Text('Track your vitals and wellness metrics',
              style: theme.textTheme.bodySmall),
          const SizedBox(height: 20),

          // ── Watch Connection Banner (always visible) ──
          const WatchConnectBanner(),
          const SizedBox(height: 16),

          // ── Conditional UI ──
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.05),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: watch.isConnected
                ? _buildConnectedView(watch, app, theme, isDark)
                : _buildDisconnectedView(theme, isDark),
          ),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  // ── Connected: Show full dashboard with live health metrics ──
  Widget _buildConnectedView(WatchMetricsProvider watch, AppProvider app,
      ThemeData theme, bool isDark) {
    return Column(
      key: const ValueKey('connected_view'),
      children: [
        const WatchDashboard(),

        const SizedBox(height: 16),

        // Water intake card (always available regardless of watch)
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    Icon(LucideIcons.droplets,
                        size: 18, color: AppColors.secondary),
                    const SizedBox(width: 8),
                    Text('Water Intake',
                        style: theme.textTheme.titleLarge)
                  ]),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${app.waterGlasses}/${app.waterGlassGoal}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Center(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(
                    app.waterGlasses > app.waterGlassGoal
                        ? app.waterGlasses
                        : app.waterGlassGoal,
                    (i) => Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: i < app.waterGlasses
                            ? AppColors.secondary.withValues(alpha: 0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: i < app.waterGlasses
                              ? AppColors.secondary
                              : theme.colorScheme.outline
                                  .withValues(alpha: 0.2),
                        ),
                      ),
                      child: Icon(
                        LucideIcons.droplets,
                        size: 16,
                        color: i < app.waterGlasses
                            ? AppColors.secondary
                            : theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton.icon(
                      onPressed: app.removeWater,
                      icon: const Icon(LucideIcons.minus, size: 16),
                      label: const Text('Remove'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            AppColors.coral.withValues(alpha: 0.1),
                        foregroundColor: AppColors.coral,
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: app.addWater,
                      icon: const Icon(LucideIcons.plus, size: 16),
                      label: const Text('Add Glass'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Disconnected: Show ONLY the connect card + empty state ──
  Widget _buildDisconnectedView(ThemeData theme, bool isDark) {
    return Column(
      key: const ValueKey('disconnected_view'),
      children: [
        const SizedBox(height: 40),
        // Premium empty state illustration
        Center(
          child: Column(
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.1),
                      AppColors.blue.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.watch,
                  size: 48,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.3)
                      : Colors.black.withValues(alpha: 0.15),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No Watch Connected',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface
                      .withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 260,
                child: Text(
                  'Connect your Apple Watch or Wear OS device to see live health metrics.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant
                        .withValues(alpha: 0.6),
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Feature list
              _featureItem(
                icon: LucideIcons.heartPulse,
                label: 'Live Heart Rate & Pulse',
                color: AppColors.coral,
                theme: theme,
                isDark: isDark,
              ),
              _featureItem(
                icon: LucideIcons.wind,
                label: 'Blood Oxygen (SpO₂)',
                color: AppColors.blue,
                theme: theme,
                isDark: isDark,
              ),
              _featureItem(
                icon: LucideIcons.moon,
                label: 'Sleep Tracking',
                color: AppColors.primary,
                theme: theme,
                isDark: isDark,
              ),
              _featureItem(
                icon: LucideIcons.thermometer,
                label: 'Body Temperature',
                color: AppColors.orange,
                theme: theme,
                isDark: isDark,
              ),
              _featureItem(
                icon: LucideIcons.activity,
                label: 'Blood Pressure & Wellness',
                color: AppColors.green,
                theme: theme,
                isDark: isDark,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _featureItem({
    required IconData icon,
    required String label,
    required Color color,
    required ThemeData theme,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 32),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 14),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? Colors.white70 : Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
