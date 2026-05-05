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
    final isDark = themeProvider.themeMode == ThemeMode.dark;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('Appearance', theme),
          Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: SwitchListTile(
              title: const Text('Dark Mode'),
              secondary: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.2), shape: BoxShape.circle),
                child: Icon(isDark ? LucideIcons.moon : LucideIcons.sun, color: AppColors.primary, size: 20),
              ),
              value: isDark,
              onChanged: (val) => themeProvider.toggleTheme(),
            ),
          ),
          const SizedBox(height: 24),
          
          _buildSectionHeader('Preferences', theme),
          Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppColors.coral.withValues(alpha: 0.2), shape: BoxShape.circle),
                    child: const Icon(LucideIcons.ruler, color: AppColors.coral, size: 20),
                  ),
                  title: const Text('Unit System'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(app.isMetric ? 'Metric' : 'Imperial', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                      const SizedBox(width: 8),
                      const Icon(LucideIcons.chevronRight, size: 16),
                    ],
                  ),
                  onTap: () {
                    app.toggleUnitSystem();
                  },
                ),
                Divider(height: 1, indent: 56, color: theme.colorScheme.outline.withValues(alpha: 0.2)),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppColors.green.withValues(alpha: 0.2), shape: BoxShape.circle),
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
          
          _buildSectionHeader('Support', theme),
          Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.secondary.withValues(alpha: 0.2), shape: BoxShape.circle),
                child: const Icon(LucideIcons.helpCircle, color: AppColors.secondary, size: 20),
              ),
              title: const Text('Help & Support'),
              trailing: const Icon(LucideIcons.chevronRight, size: 16),
              onTap: () async {
                final Uri emailLaunchUri = Uri(
                  scheme: 'mailto',
                  path: 'support@lifepulse.com',
                );
                if (await canLaunchUrl(emailLaunchUri)) {
                  await launchUrl(emailLaunchUri);
                }
              },
            ),
          ),
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
