import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../providers/running_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/cached_tile_provider.dart';
import '../widgets/glass_card.dart';
import '../theme/app_colors.dart';

class RunningScreen extends StatefulWidget {
  const RunningScreen({super.key});
  @override State<RunningScreen> createState() => _RunningScreenState();
}

class _RunningScreenState extends State<RunningScreen> {
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RunningProvider>().initLocationService();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final run = context.watch<RunningProvider>();

    return Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Running Tracker', style: theme.textTheme.displayLarge),
        const SizedBox(height: 4),
        Text('Track your runs with real-time GPS', style: theme.textTheme.bodySmall),
        const SizedBox(height: 16),
        Row(children: [
          _Tab('Live Tracker', 0, _tabIndex, (i) => setState(() => _tabIndex = i)),
          const SizedBox(width: 8),
          _Tab('History', 1, _tabIndex, (i) => setState(() => _tabIndex = i)),
          const SizedBox(width: 8),
          _Tab('Records', 2, _tabIndex, (i) => setState(() => _tabIndex = i)),
        ]),
      ])),
      const SizedBox(height: 12),
      Expanded(child: _tabIndex == 0 ? _TrackerTab(run: run, isDark: isDark, theme: theme)
        : _tabIndex == 1 ? _HistoryTab(run: run, theme: theme, isDark: isDark)
        : _RecordsTab(run: run, theme: theme)),
    ]);
  }
}

class _Tab extends StatelessWidget {
  final String label; final int index; final int current; final ValueChanged<int> onTap;
  const _Tab(this.label, this.index, this.current, this.onTap);
  @override Widget build(BuildContext context) {
    final active = index == current;
    return GestureDetector(onTap: () => onTap(index), child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: active ? AppColors.primary : Colors.transparent, borderRadius: BorderRadius.circular(20),
        border: active ? null : Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3))),
      child: Text(label, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: active ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13))));
  }
}

// ─── FREE PREMIUM MAP TILES (No API Key Required) ───
// Using CartoDB tiles which provide a beautiful, modern aesthetic similar to Mapbox
// without requiring any API tokens or causing loading errors.

String _darkTileUrl() =>
    'https://a.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}@2x.png';

String _lightTileUrl() =>
    'https://a.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}@2x.png';


class _TrackerTab extends StatefulWidget {
  final RunningProvider run; final bool isDark; final ThemeData theme;
  const _TrackerTab({required this.run, required this.isDark, required this.theme});

  @override State<_TrackerTab> createState() => _TrackerTabState();
}

class _TrackerTabState extends State<_TrackerTab> with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _TrackerTab oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Auto-pan map to current position while tracking
    if (widget.run.isTracking && widget.run.currentPosition != null && !widget.run.isPaused) {
      try {
        _mapController.move(
          LatLng(widget.run.currentPosition!.latitude, widget.run.currentPosition!.longitude),
          _mapController.camera.zoom,
        );
      } catch (_) {}
    }

    // Fit bounds when tracking stops
    if (oldWidget.run.isTracking && !widget.run.isTracking && widget.run.routeCoordinates.length > 1) {
      _fitRouteBounds();
    }
  }

  void _fitRouteBounds() {
    final points = widget.run.routeCoordinates
        .map((c) => LatLng(c.latitude, c.longitude))
        .toList();
    if (points.length < 2) return;

    final bounds = LatLngBounds.fromPoints(points);
    try {
      _mapController.fitCamera(CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(50),
      ));
    } catch (_) {}
  }

  @override Widget build(BuildContext context) {
    final run = widget.run;
    final isDark = widget.isDark;
    final theme = widget.theme;

    final center = run.currentPosition != null
        ? LatLng(run.currentPosition!.latitude, run.currentPosition!.longitude)
        : const LatLng(20.5937, 78.9629); // Default to India center

    // Build route polyline points
    final routePoints = run.routeCoordinates
        .map((c) => LatLng(c.latitude, c.longitude))
        .toList();

    return SingleChildScrollView(padding: const EdgeInsets.symmetric(horizontal: 16), child: Column(children: [
      // ─── Map ───
      ClipRRect(borderRadius: BorderRadius.circular(20), child: SizedBox(height: 320, child: Stack(children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: center,
            initialZoom: 15,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all,
            ),
          ),
          children: [
            // ─── Map Tile Layer (free, no API key) ───
            TileLayer(
              urlTemplate: isDark ? _darkTileUrl() : _lightTileUrl(),
              userAgentPackageName: 'com.lifepulse.app',
              maxZoom: 19,
              tileProvider: CachedTileProvider(),
            ),

            // ─── Route Polyline ───
            if (routePoints.length > 1)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: routePoints,
                    strokeWidth: isDark ? 5.0 : 4.0,
                    color: isDark ? const Color(0xFF39FF14) : AppColors.primary,
                    borderStrokeWidth: isDark ? 2.0 : 0,
                    borderColor: isDark ? Colors.black.withValues(alpha: 0.6) : Colors.transparent,
                  ),
                ],
              ),

            // ─── Markers ───
            MarkerLayer(
              markers: [
                // Start marker
                if (run.startPosition != null && run.isTracking)
                  Marker(
                    point: LatLng(run.startPosition!.latitude, run.startPosition!.longitude),
                    width: 24,
                    height: 24,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: [BoxShadow(color: AppColors.green.withValues(alpha: 0.5), blurRadius: 8)],
                      ),
                      child: const Icon(Icons.flag, size: 12, color: Colors.white),
                    ),
                  ),

                // Current position — pulsing dot
                if (run.currentPosition != null)
                  Marker(
                    point: LatLng(run.currentPosition!.latitude, run.currentPosition!.longitude),
                    width: 40,
                    height: 40,
                    child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (_, __) {
                        final scale = 1.0 + (_pulseController.value * 0.5);
                        final opacity = 1.0 - _pulseController.value;
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            // Pulse ring
                            Transform.scale(
                              scale: scale,
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: (isDark ? const Color(0xFF39FF14) : AppColors.primary)
                                        .withValues(alpha: opacity * 0.6),
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                            // Inner dot
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF39FF14) : AppColors.primary,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: (isDark ? const Color(0xFF39FF14) : AppColors.primary)
                                        .withValues(alpha: 0.6),
                                    blurRadius: 12,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
              ],
            ),
          ],
        ),

        // ─── Map Attribution Overlay ───
        Positioned(
          bottom: 4,
          right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text('© Mapbox © OpenStreetMap',
              style: TextStyle(fontSize: 8, color: isDark ? Colors.white70 : Colors.black54)),
          ),
        ),

        // ─── Location Error Banner ───
        if (!run.hasLocationPermission && run.currentPosition == null)
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.all(12),
              color: AppColors.coral.withValues(alpha: 0.9),
              child: const Row(children: [
                Icon(Icons.location_off, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Expanded(child: Text('GPS permission required. Tap Start to enable.',
                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600))),
              ]),
            ),
          ),

        // ─── Recenter Button ───
        if (run.currentPosition != null)
          Positioned(
            bottom: 12,
            left: 12,
            child: GestureDetector(
              onTap: () {
                if (run.currentPosition != null) {
                  _mapController.move(
                    LatLng(run.currentPosition!.latitude, run.currentPosition!.longitude),
                    16,
                  );
                }
              },
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.darkSurfaceContainer : Colors.white).withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 6)],
                ),
                child: Icon(LucideIcons.crosshair, size: 18,
                  color: isDark ? AppColors.secondary : AppColors.primary),
              ),
            ),
          ),
      ]))),
      const SizedBox(height: 12),

      // ─── Live Stats ───
      Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceContainer.withValues(alpha: 0.55) : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(20), border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06))),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _LiveStat(value: run.currentDistance.toStringAsFixed(2), label: 'km'),
          Container(width: 1, height: 40, color: theme.colorScheme.outline.withValues(alpha: 0.2)),
          _LiveStat(value: run.currentPace, label: 'min/km'),
          Container(width: 1, height: 40, color: theme.colorScheme.outline.withValues(alpha: 0.2)),
          _LiveStat(value: run.formatDuration(run.currentDuration), label: 'time'),
          Container(width: 1, height: 40, color: theme.colorScheme.outline.withValues(alpha: 0.2)),
          _LiveStat(value: '${run.currentCalories}', label: 'kcal'),
        ])),
      const SizedBox(height: 16),

      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        if (!run.isTracking) GestureDetector(onTap: () async {
          var status = await Permission.location.status;
          if (!status.isGranted) {
            status = await Permission.location.request();
          }
          
          if (status.isGranted) {
            run.startRun();
          } else if (status.isPermanentlyDenied) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permission permanently denied. Opening settings...')));
            }
            await openAppSettings();
          } else {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permission is required to track your run.')));
            }
          }
        }, child: Container(width: 72, height: 72, decoration: BoxDecoration(gradient: AppColors.gradientPrimary, shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.5), blurRadius: 24, offset: const Offset(0, 6))]),
          child: const Icon(LucideIcons.play, color: Colors.white, size: 30)))
        else ...[
          GestureDetector(onTap: () => run.isPaused ? run.resumeRun() : run.pauseRun(), child: Container(width: 56, height: 56, decoration: BoxDecoration(gradient: AppColors.gradientPrimary, shape: BoxShape.circle),
            child: Icon(run.isPaused ? LucideIcons.play : LucideIcons.pause, color: Colors.white, size: 24))),
          const SizedBox(width: 20),
          GestureDetector(onTap: () { run.stopRun(); run.resetRun(); }, child: Container(width: 56, height: 56, decoration: const BoxDecoration(gradient: AppColors.gradientCoral, shape: BoxShape.circle),
            child: const Icon(LucideIcons.square, color: Colors.white, size: 24))),
        ],
      ]),
      const SizedBox(height: 16),

      // ─── Speed Card ───
      GlassCard(child: Column(children: [
        Row(children: [Icon(LucideIcons.zap, size: 18, color: AppColors.secondary), const SizedBox(width: 8), Text('Current Speed', style: theme.textTheme.titleMedium)]),
        const SizedBox(height: 12),
        RichText(text: TextSpan(children: [
          TextSpan(text: run.currentSpeed.toStringAsFixed(1), style: theme.textTheme.displayLarge?.copyWith(fontSize: 48, color: AppColors.secondary)),
          TextSpan(text: ' km/h', style: theme.textTheme.bodyMedium),
        ])),
      ])),
      const SizedBox(height: 16),

      // ─── Personal Records ───
      GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(LucideIcons.trophy, size: 18, color: AppColors.yellow), const SizedBox(width: 8), Text('Personal Records', style: theme.textTheme.titleMedium)]),
        const SizedBox(height: 12),
        ...run.personalRecords.entries.map((e) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02), borderRadius: BorderRadius.circular(10)),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(e.key, style: theme.textTheme.bodySmall), Text(e.value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700, color: AppColors.secondary))])))),
      ])),
      const SizedBox(height: 100),
    ]));
  }
}

class _LiveStat extends StatelessWidget {
  final String value; final String label;
  const _LiveStat({required this.value, required this.label});
  @override Widget build(BuildContext context) => Column(mainAxisSize: MainAxisSize.min, children: [
    Text(value, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
    Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 9, letterSpacing: 0.5)),
  ]);
}

class _HistoryTab extends StatelessWidget {
  final RunningProvider run; final ThemeData theme; final bool isDark;
  const _HistoryTab({required this.run, required this.theme, required this.isDark});
  @override Widget build(BuildContext context) {
    return ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 16), itemCount: run.history.length, itemBuilder: (_, i) {
      final r = run.history[i]; final date = DateTime.tryParse(r.date);
      return Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: isDark ? AppColors.darkSurfaceContainer.withValues(alpha: 0.55) : AppColors.lightSurface, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06))),
        child: Row(children: [
          Container(width: 48, padding: const EdgeInsets.symmetric(vertical: 6), decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
            child: Column(children: [
              Text(date != null ? '${date.day}' : '', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              Text(date != null ? ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][date.month] : '', style: theme.textTheme.labelSmall?.copyWith(color: AppColors.primary, fontSize: 9)),
            ])),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(r.route, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
            Text('${r.distance} km · ${r.duration} · ${r.pace} min/km', style: theme.textTheme.bodySmall?.copyWith(fontSize: 11)),
          ])),
          Row(children: [Icon(LucideIcons.flame, size: 14, color: AppColors.coral), const SizedBox(width: 4), Text('${r.calories}', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600, color: AppColors.coral))]),
        ]));
    });
  }
}

class _RecordsTab extends StatelessWidget {
  final RunningProvider run; final ThemeData theme;
  const _RecordsTab({required this.run, required this.theme});
  @override Widget build(BuildContext context) {
    return SingleChildScrollView(padding: const EdgeInsets.symmetric(horizontal: 16), child: Column(children: [
      GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(LucideIcons.trophy, size: 18, color: AppColors.yellow), const SizedBox(width: 8), Text('Personal Bests', style: theme.textTheme.titleLarge)]),
        const SizedBox(height: 16),
        GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), childAspectRatio: 1.8, crossAxisSpacing: 8, mainAxisSpacing: 8,
          children: run.personalRecords.entries.map((e) => Container(decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14)),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(e.value, style: theme.textTheme.headlineMedium?.copyWith(color: AppColors.secondary, fontWeight: FontWeight.w800)),
              Text(e.key, style: theme.textTheme.labelSmall?.copyWith(fontSize: 9)),
            ]))).toList()),
      ])),
      const SizedBox(height: 100),
    ]));
  }
}
