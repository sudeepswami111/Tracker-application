import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../providers/watch_metrics_provider.dart';
import '../theme/app_colors.dart';
import 'permission_request_sheet.dart';

class WatchConnectBanner extends StatefulWidget {
  const WatchConnectBanner({super.key});

  @override
  State<WatchConnectBanner> createState() => _WatchConnectBannerState();
}

class _WatchConnectBannerState extends State<WatchConnectBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _showPermissionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PermissionRequestSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final watchProvider = Provider.of<WatchMetricsProvider>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (watchProvider.isConnected) {
      return _buildConnectedBanner(context, watchProvider, theme, isDark);
    }

    return _buildDisconnectedBanner(context, watchProvider, theme, isDark);
  }

  Widget _buildConnectedBanner(BuildContext context,
      WatchMetricsProvider watchProvider, ThemeData theme, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: isDark
              ? [
                  const Color(0xFF0D1B2A),
                  const Color(0xFF1B2838),
                ]
              : [
                  const Color(0xFFE8F4FD),
                  const Color(0xFFF0F8FF),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: isDark
              ? AppColors.blue.withValues(alpha: 0.3)
              : AppColors.blue.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.blue.withValues(alpha: isDark ? 0.15 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Subtle gradient glow in top-right
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.blue.withValues(alpha: 0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Animated pulse watch icon
                      ScaleTransition(
                        scale: _pulseAnim,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.blue.withValues(alpha: 0.2),
                                AppColors.secondary.withValues(alpha: 0.15),
                              ],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color:
                                    AppColors.blue.withValues(alpha: 0.3),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          child: const Icon(LucideIcons.watch,
                              color: Colors.white, size: 22),
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
                                    watchProvider.deviceName.isNotEmpty
                                        ? watchProvider.deviceName
                                        : 'Smartwatch',
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white
                                          : AppColors.lightOnSurface,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // LIVE badge
                                if (watchProvider.isStreaming)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.green
                                          .withValues(alpha: 0.15),
                                      borderRadius:
                                          BorderRadius.circular(6),
                                      border: Border.all(
                                        color: AppColors.green
                                            .withValues(alpha: 0.4),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: const BoxDecoration(
                                            color: AppColors.green,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Text(
                                          'LIVE',
                                          style: TextStyle(
                                            color: AppColors.green,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Synced ${watchProvider.lastSyncedText}',
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white54
                                    : AppColors.lightOnSurfaceVariant,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Battery indicator
                      Column(
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                watchProvider.batteryLevel > 20
                                    ? LucideIcons.batteryFull
                                    : LucideIcons.batteryLow,
                                size: 16,
                                color: watchProvider.batteryLevel > 20
                                    ? AppColors.green
                                    : AppColors.coral,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${watchProvider.batteryLevel}%',
                                style: TextStyle(
                                  color: watchProvider.batteryLevel > 20
                                      ? AppColors.green
                                      : AppColors.coral,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap: () => watchProvider.disconnectWatch(),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.06)
                                    : Colors.black.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                LucideIcons.unlink,
                                size: 14,
                                color: isDark
                                    ? Colors.white38
                                    : Colors.black38,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisconnectedBanner(BuildContext context,
      WatchMetricsProvider watchProvider, ThemeData theme, bool isDark) {
    final hasError = watchProvider.connectError != null;
    final isDenied = watchProvider.permissionStatus ==
            WatchPermissionStatus.denied ||
        watchProvider.permissionStatus ==
            WatchPermissionStatus.permanentlyDenied;

    return GestureDetector(
      onTap: () => _showPermissionSheet(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: hasError
                ? [const Color(0xFF351E1E), const Color(0xFF2A1616)]
                : isDark
                    ? [const Color(0xFF1A1F3D), const Color(0xFF12162E)]
                    : [const Color(0xFFF0EEFF), const Color(0xFFE8E4FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: hasError
                ? AppColors.coral.withValues(alpha: 0.3)
                : AppColors.primary.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: hasError
                  ? AppColors.coral.withValues(alpha: 0.1)
                  : AppColors.primary.withValues(alpha: 0.1),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            // Animated icon
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: hasError
                      ? [
                          AppColors.coral.withValues(alpha: 0.2),
                          AppColors.coral.withValues(alpha: 0.1),
                        ]
                      : [
                          AppColors.primary.withValues(alpha: 0.2),
                          AppColors.blue.withValues(alpha: 0.1),
                        ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasError ? LucideIcons.alertCircle : LucideIcons.watch,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    watchProvider.isConnecting
                        ? 'Connecting...'
                        : hasError
                            ? 'Connection Failed'
                            : 'Connect Smartwatch',
                    style: TextStyle(
                      color: isDark
                          ? Colors.white
                          : AppColors.lightOnSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    watchProvider.isConnecting
                        ? 'Scanning for nearby devices...'
                        : hasError
                            ? watchProvider.connectError!
                            : isDenied
                                ? 'Permissions required. Tap to fix.'
                                : 'Tap to sync Apple Watch or Wear OS',
                    style: TextStyle(
                      color: hasError
                          ? AppColors.coral.withValues(alpha: 0.8)
                          : isDark
                              ? Colors.white54
                              : AppColors.lightOnSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (watchProvider.isConnecting)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                      AlwaysStoppedAnimation(AppColors.primary),
                ),
              )
            else
              Icon(
                hasError ? LucideIcons.refreshCw : LucideIcons.chevronRight,
                color: isDark ? Colors.white38 : Colors.black38,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
