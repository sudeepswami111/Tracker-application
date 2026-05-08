import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/theme_provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_colors.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final app = context.watch<AppProvider>();
    final theme = Theme.of(context);
    final isDark = themeProvider.isDark;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Appearance ──────────────────────────────────────────────
          _buildSectionHeader('Appearance', theme),
          Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  // Quick toggle row
                  SwitchListTile(
                    title: Text(isDark ? 'Dark Mode' : 'Light Mode'),
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isDark ? LucideIcons.moon : LucideIcons.sun,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    value: isDark,
                    activeColor: AppColors.irisViolet,
                    onChanged: (_) => themeProvider.toggleTheme(),
                  ),
                  Divider(
                    height: 1,
                    indent: 56,
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  ),
                  // Three-way selector (Light / System / Dark)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: _ThemeModeSelector(themeProvider: themeProvider, theme: theme),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── Preferences ─────────────────────────────────────────────
          _buildSectionHeader('Preferences', theme),
          Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.coral.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.ruler, color: AppColors.coral, size: 20),
                  ),
                  title: const Text('Unit System'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        app.isMetric ? 'Metric' : 'Imperial',
                        style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(width: 8),
                      const Icon(LucideIcons.chevronRight, size: 16),
                    ],
                  ),
                  onTap: app.toggleUnitSystem,
                ),
                Divider(
                  height: 1,
                  indent: 56,
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.green.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.lock, color: AppColors.green, size: 20),
                  ),
                  title: const Text('Account Privacy'),
                  trailing: const Icon(LucideIcons.chevronRight, size: 16),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Support ──────────────────────────────────────────────────
          _buildSectionHeader('Support', theme),
          Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.helpCircle, color: AppColors.secondary, size: 20),
              ),
              title: const Text('Help & Support'),
              trailing: const Icon(LucideIcons.chevronRight, size: 16),
              onTap: () async {
                final uri = Uri(scheme: 'mailto', path: 'support@lifepulse.com');
                if (await canLaunchUrl(uri)) await launchUrl(uri);
              },
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8, top: 8),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          letterSpacing: 1.2,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// ── Three-Way Theme Selector ─────────────────────────────────────────────────

class _ThemeModeSelector extends StatelessWidget {
  final ThemeProvider themeProvider;
  final ThemeData theme;

  const _ThemeModeSelector({required this.themeProvider, required this.theme});

  @override
  Widget build(BuildContext context) {
    final modes = [
      (ThemeMode.light, LucideIcons.sun, 'Light'),
      (ThemeMode.system, LucideIcons.monitor, 'System'),
      (ThemeMode.dark, LucideIcons.moon, 'Dark'),
    ];

    return Row(
      children: modes.map((entry) {
        final (mode, icon, label) = entry;
        final isSelected = themeProvider.themeMode == mode;

        return Expanded(
          child: GestureDetector(
            onTap: () => themeProvider.setThemeMode(mode),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.irisViolet.withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? AppColors.irisViolet.withValues(alpha: 0.5)
                      : theme.colorScheme.outline.withValues(alpha: 0.3),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 18,
                    color: isSelected
                        ? AppColors.irisViolet
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isSelected
                          ? AppColors.irisViolet
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
