import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/watch_metrics_provider.dart';
import '../services/watch_connection_manager.dart';
import '../theme/app_colors.dart';

/// Bottom sheet that scans for nearby BLE devices and lets the user pick one.
class DeviceScannerSheet extends StatefulWidget {
  const DeviceScannerSheet({super.key});

  @override
  State<DeviceScannerSheet> createState() => _DeviceScannerSheetState();
}

class _DeviceScannerSheetState extends State<DeviceScannerSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _scanAnimController;
  bool _hasStartedScan = false;

  @override
  void initState() {
    super.initState();
    _scanAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // Start scan after the sheet is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startScan();
    });
  }

  void _startScan() {
    if (!_hasStartedScan) {
      _hasStartedScan = true;
      context.read<WatchMetricsProvider>().requestPermissionsAndScan();
    }
  }

  @override
  void dispose() {
    _scanAnimController.dispose();
    // Stop scanning if sheet is closed
    final provider = context.read<WatchMetricsProvider>();
    if (provider.isScanning) {
      provider.stopScanning();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final watchProvider = context.watch<WatchMetricsProvider>();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF12162E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
          const SizedBox(height: 20),

          // Header
          Row(
            children: [
              Icon(LucideIcons.bluetooth, color: AppColors.blue, size: 22),
              const SizedBox(width: 10),
              Text(
                'Nearby Devices',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              if (watchProvider.isScanning)
                RotationTransition(
                  turns: _scanAnimController,
                  child: Icon(LucideIcons.loader2,
                      size: 20,
                      color: isDark ? Colors.white54 : Colors.black38),
                )
              else
                IconButton(
                  icon: Icon(LucideIcons.refreshCw,
                      size: 18,
                      color: isDark ? Colors.white54 : Colors.black38),
                  onPressed: () {
                    _hasStartedScan = false;
                    _startScan();
                  },
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            watchProvider.isScanning
                ? 'Scanning for Bluetooth devices...'
                : watchProvider.discoveredDevices.isEmpty
                    ? 'No devices found. Make sure your Mi Band is nearby and Bluetooth is on.'
                    : 'Tap a device to connect',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark ? Colors.white54 : Colors.black45,
            ),
          ),
          const SizedBox(height: 16),

          // Error display
          if (watchProvider.connectError != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.coral.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.coral.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.alertCircle,
                      size: 16, color: AppColors.coral),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      watchProvider.connectError!,
                      style: const TextStyle(
                          color: AppColors.coral, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Connecting indicator
          if (watchProvider.isConnecting) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: AppColors.blue.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(AppColors.blue),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Connecting to device...',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Scanning animation (pulsing dots)
          if (watchProvider.isScanning &&
              watchProvider.discoveredDevices.isEmpty) ...[
            const SizedBox(height: 30),
            _ScanningAnimation(controller: _scanAnimController, isDark: isDark),
            const SizedBox(height: 30),
          ],

          // Device list
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: watchProvider.discoveredDevices.length,
              itemBuilder: (context, index) {
                final device = watchProvider.discoveredDevices[index];
                return _DeviceTile(
                  device: device,
                  isDark: isDark,
                  theme: theme,
                  isConnecting: watchProvider.isConnecting,
                  onTap: () async {
                    await watchProvider.connectToDevice(device);
                    if (context.mounted && watchProvider.isConnected) {
                      Navigator.pop(context);
                    }
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          // Help text
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.03)
                  : Colors.black.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.info,
                        size: 14,
                        color: isDark ? Colors.white38 : Colors.black38),
                    const SizedBox(width: 8),
                    Text(
                      'Mi Band Setup',
                      style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.black45,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '1. Install "Mi Fitness" or "Zepp Life" app\n'
                  '2. Pair your Mi Band 5 in the app\n'
                  '3. Enable Health Connect sync in Mi Fitness\n'
                  '4. Install Google "Health Connect" if needed\n'
                  '5. Connect here to read synced data',
                  style: TextStyle(
                    color: isDark ? Colors.white38 : Colors.black38,
                    fontSize: 11,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: watchProvider.isConnecting
                  ? null
                  : () async {
                      await watchProvider.connectViaHealthConnect();
                      if (context.mounted && watchProvider.isConnected) {
                        Navigator.pop(context);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green.withValues(alpha: 0.15),
                foregroundColor: AppColors.green,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.heartPulse, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Sync directly via Health Connect',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Device Tile ──
class _DeviceTile extends StatelessWidget {
  final DiscoveredDevice device;
  final bool isDark;
  final ThemeData theme;
  final bool isConnecting;
  final VoidCallback onTap;

  const _DeviceTile({
    required this.device,
    required this.isDark,
    required this.theme,
    required this.isConnecting,
    required this.onTap,
  });

  IconData _deviceIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('band') || lower.contains('mi')) {
      return LucideIcons.watch;
    }
    if (lower.contains('buds') || lower.contains('pods') || lower.contains('ear')) {
      return LucideIcons.headphones;
    }
    if (lower.contains('tv') || lower.contains('speaker')) {
      return LucideIcons.speaker;
    }
    return LucideIcons.bluetooth;
  }

  Color _signalColor(int rssi) {
    if (rssi > -50) return AppColors.green;
    if (rssi > -70) return AppColors.yellow;
    return AppColors.coral;
  }

  String _signalText(int rssi) {
    if (rssi > -50) return 'Strong';
    if (rssi > -70) return 'Good';
    if (rssi > -85) return 'Weak';
    return 'Far';
  }

  @override
  Widget build(BuildContext context) {
    final isBandOrWatch = device.name.toLowerCase().contains('band') ||
        device.name.toLowerCase().contains('mi') ||
        device.name.toLowerCase().contains('watch') ||
        device.name.toLowerCase().contains('wear');

    return GestureDetector(
      onTap: isConnecting ? null : onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isBandOrWatch
              ? (isDark
                  ? AppColors.primary.withValues(alpha: 0.08)
                  : AppColors.primary.withValues(alpha: 0.04))
              : (isDark
                  ? Colors.white.withValues(alpha: 0.03)
                  : Colors.black.withValues(alpha: 0.02)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isBandOrWatch
                ? AppColors.primary.withValues(alpha: 0.2)
                : (isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.06)),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isBandOrWatch
                    ? AppColors.primary.withValues(alpha: 0.15)
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.black.withValues(alpha: 0.04)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _deviceIcon(device.name),
                size: 20,
                color: isBandOrWatch
                    ? AppColors.primary
                    : (isDark ? Colors.white54 : Colors.black38),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          device.name,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isBandOrWatch) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.green.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'RECOMMENDED',
                            style: TextStyle(
                              color: AppColors.green,
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _signalColor(device.rssi),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${_signalText(device.rssi)} signal',
                        style: TextStyle(
                          color: isDark ? Colors.white38 : Colors.black38,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        device.id.length > 12
                            ? '${device.id.substring(0, 12)}...'
                            : device.id,
                        style: TextStyle(
                          color: isDark ? Colors.white24 : Colors.black26,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              LucideIcons.chevronRight,
              size: 18,
              color: isDark ? Colors.white24 : Colors.black26,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Scanning animation ──
class _ScanningAnimation extends StatelessWidget {
  final AnimationController controller;
  final bool isDark;

  const _ScanningAnimation({
    required this.controller,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: Center(
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            return Stack(
              alignment: Alignment.center,
              children: [
                // Outer pulsing ring
                Container(
                  width: 60 + (controller.value * 30),
                  height: 60 + (controller.value * 30),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.blue
                          .withValues(alpha: 0.3 - controller.value * 0.3),
                      width: 2,
                    ),
                  ),
                ),
                // Middle ring
                Container(
                  width: 40 + (controller.value * 15),
                  height: 40 + (controller.value * 15),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.blue.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                  ),
                ),
                // Center Bluetooth icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.blue.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.bluetooth,
                    color: AppColors.blue,
                    size: 22,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
