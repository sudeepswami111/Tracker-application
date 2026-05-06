import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/watch_metrics_provider.dart';
import 'permission_request_sheet.dart';

class WatchConnectBanner extends StatelessWidget {
  const WatchConnectBanner({super.key});

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

    if (watchProvider.isConnected) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF16192A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.watch, color: Colors.blueAccent, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Syncing with Watch',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    watchProvider.isStreaming ? 'Receiving live data' : 'Connected',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(LucideIcons.refreshCw, color: Colors.blueAccent, size: 20),
              onPressed: () {
                watchProvider.disconnectWatch();
              },
            ),
          ],
        ),
      );
    }

    final hasError = watchProvider.connectError != null;
    final isDenied = watchProvider.permissionStatus == WatchPermissionStatus.denied || 
                     watchProvider.permissionStatus == WatchPermissionStatus.permanentlyDenied;

    return GestureDetector(
      onTap: () {
        if (isDenied) {
          _showPermissionSheet(context);
        } else {
          _showPermissionSheet(context);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: hasError 
                ? [const Color(0xFF351E1E), const Color(0xFF2A1616)]
                : [const Color(0xFF1E2235), const Color(0xFF16192A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasError 
                ? Colors.redAccent.withValues(alpha: 0.3)
                : Colors.blueAccent.withValues(alpha: 0.3)
          ),
          boxShadow: [
            BoxShadow(
              color: hasError 
                  ? Colors.redAccent.withValues(alpha: 0.1)
                  : Colors.blueAccent.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: hasError 
                    ? Colors.redAccent.withValues(alpha: 0.2)
                    : Colors.blueAccent.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasError ? LucideIcons.alertCircle : LucideIcons.watch, 
                color: Colors.white, 
                size: 24
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasError ? 'Connection Failed' : 'Connect Smartwatch',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasError 
                        ? watchProvider.connectError! 
                        : (isDenied ? 'Permissions required. Tap to fix.' : 'Tap to sync Apple Watch or Android Wear'),
                    style: TextStyle(
                      color: hasError ? Colors.redAccent.withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              hasError ? LucideIcons.refreshCw : LucideIcons.chevronRight, 
              color: Colors.white54, 
              size: 20
            ),
          ],
        ),
      ),
    );
  }
}
