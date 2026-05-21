import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/watch_metrics_provider.dart';
import '../theme/app_colors.dart';
import 'device_scanner_sheet.dart';

class PermissionRequestSheet extends StatelessWidget {
  const PermissionRequestSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final watchProvider =
        Provider.of<WatchMetricsProvider>(context, listen: true);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF12162E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 48,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 28),

          // Watch icon with glow
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.15),
                  AppColors.blue.withValues(alpha: 0.1),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(LucideIcons.watch,
                size: 40, color: AppColors.primary),
          ),
          const SizedBox(height: 20),

          Text(
            'Connect Smartwatch',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Connect your Mi Band, Apple Watch, or any Bluetooth fitness device to sync health data.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? Colors.white60 : Colors.black54,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),

          // Permission items
          _PermissionItem(
            icon: LucideIcons.bluetooth,
            title: 'Bluetooth & Location',
            description: 'Find and connect to your device nearby.',
            isDark: isDark,
          ),
          const SizedBox(height: 14),
          _PermissionItem(
            icon: LucideIcons.heartPulse,
            title: 'Health Connect',
            description: 'Read heart rate, SpOâ‚‚, sleep from Mi Fitness / Zepp Life.',
            isDark: isDark,
          ),
          const SizedBox(height: 14),
          _PermissionItem(
            icon: LucideIcons.footprints,
            title: 'Activity & Sensors',
            description: 'Track steps and body sensor data.',
            isDark: isDark,
          ),
          const SizedBox(height: 32),

          // Scan button - opens the device scanner
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: () {
                if (watchProvider.permissionStatus ==
                    WatchPermissionStatus.permanentlyDenied) {
                  openAppSettings();
                } else {
                  // Close this sheet and open the scanner
                  Navigator.pop(context);
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const DeviceScannerSheet(),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.search, size: 18),
                  const SizedBox(width: 10),
                  Text(
                    watchProvider.permissionStatus ==
                            WatchPermissionStatus.permanentlyDenied
                        ? 'Open Settings'
                        : 'Scan for Devices',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          TextButton(
            onPressed: () {
              watchProvider.resetPermissionStatus();
              Navigator.pop(context);
            },
            child: Text(
              'Maybe Later',
              style: TextStyle(
                color: isDark ? Colors.white38 : Colors.black38,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _PermissionItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isDark;

  const _PermissionItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, size: 20, color: AppColors.primary),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.black45,
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        Icon(
          LucideIcons.checkCircle,
          size: 18,
          color: isDark
              ? Colors.white.withValues(alpha: 0.15)
              : Colors.black.withValues(alpha: 0.1),
        ),
      ],
    );
  }
}
