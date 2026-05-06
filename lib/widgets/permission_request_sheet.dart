import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/watch_metrics_provider.dart';
import '../theme/app_colors.dart';

class PermissionRequestSheet extends StatelessWidget {
  const PermissionRequestSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final watchProvider = Provider.of<WatchMetricsProvider>(context, listen: false);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16192A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Icon(LucideIcons.watch, size: 48, color: AppColors.primary),
          const SizedBox(height: 16),
          Text(
            'Connect Smartwatch',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We need some permissions to read live heart rate, SpO2, and wellness data from your watch.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(height: 24),
          _PermissionItem(
            icon: LucideIcons.bluetooth,
            title: 'Bluetooth & Location',
            description: 'To find and connect to your watch.',
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _PermissionItem(
            icon: LucideIcons.activity,
            title: 'Health Data',
            description: 'To read your heart rate, SpO2, and sleep.',
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _PermissionItem(
            icon: LucideIcons.footprints,
            title: 'Activity Recognition',
            description: 'To track your steps and movement accurately.',
            isDark: isDark,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () async {
                if (watchProvider.permissionStatus == WatchPermissionStatus.permanentlyDenied) {
                  await openAppSettings();
                  if (context.mounted) Navigator.pop(context);
                } else {
                  await watchProvider.connectWatch();
                  if (context.mounted && watchProvider.isConnected) {
                    Navigator.pop(context);
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                watchProvider.permissionStatus == WatchPermissionStatus.permanentlyDenied
                    ? 'Open Settings'
                    : 'Grant Permissions',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              watchProvider.resetPermissionStatus();
              Navigator.pop(context);
            },
            child: const Text('Maybe Later'),
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
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
            shape: BoxShape.circle,
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
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              Text(
                description,
                style: TextStyle(
                  color: isDark ? Colors.white60 : Colors.black54,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
