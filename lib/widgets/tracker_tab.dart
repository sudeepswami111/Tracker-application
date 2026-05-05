import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../providers/running_provider.dart';
import '../services/routing_service.dart';
import '../widgets/glass_card.dart';
import '../theme/app_colors.dart';

class TrackerTab extends StatefulWidget {
  final RunningProvider run;
  final bool isDark;
  final ThemeData theme;
  final VoidCallback? onToggleFullscreen;
  final bool isFullscreen;
  const TrackerTab({super.key, required this.run, required this.isDark, required this.theme, this.onToggleFullscreen, this.isFullscreen = false});
  @override State<TrackerTab> createState() => _TrackerTabState();
}

class _TrackerTabState extends State<TrackerTab> with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  late AnimationController _pulseController;
  final _startCtrl = TextEditingController();
  final _destCtrl = TextEditingController();
  List<RouteResult> _routes = [];
  bool _isSearching = false;
  bool _showRouteInputs = true;
  LatLng? _startLatLng;
  LatLng? _destLatLng;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _startCtrl.dispose();
    _destCtrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant TrackerTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.run.isTracking && widget.run.currentPosition != null && !widget.run.isPaused) {
      try { _mapController.move(LatLng(widget.run.currentPosition!.latitude, widget.run.currentPosition!.longitude), _mapController.camera.zoom); } catch (_) {}
    }
    if (oldWidget.run.isTracking && !widget.run.isTracking && widget.run.routeCoordinates.length > 1) {
      _fitBounds(widget.run.routeCoordinates.map((c) => LatLng(c.latitude, c.longitude)).toList());
    }
  }

  void _fitBounds(List<LatLng> pts) {
    if (pts.length < 2) return;
    try { _mapController.fitCamera(CameraFit.bounds(bounds: LatLngBounds.fromPoints(pts), padding: const EdgeInsets.all(50))); } catch (_) {}
  }

  Future<void> _searchRoute() async {
    if (_startCtrl.text.isEmpty || _destCtrl.text.isEmpty) return;
    setState(() => _isSearching = true);
    try {
      final startResults = await RoutingService.geocode(_startCtrl.text);
      final destResults = await RoutingService.geocode(_destCtrl.text);
      if (startResults.isEmpty || destResults.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not find one or both locations.')));
        setState(() => _isSearching = false);
        return;
      }
      _startLatLng = startResults.first.location;
      _destLatLng = destResults.first.location;
      final routes = await RoutingService.getRoutes(_startLatLng!, _destLatLng!);
      setState(() { _routes = routes; _isSearching = false; _showRouteInputs = false; });
      if (routes.isNotEmpty) {
        final allPts = routes.expand((r) => r.points).toList();
        _fitBounds(allPts);
      }
    } catch (e) {
      setState(() => _isSearching = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Routing error: $e')));
    }
  }

  void _selectRoute(int idx) {
    setState(() { for (int i = 0; i < _routes.length; i++) _routes[i].isSelected = (i == idx); });
  }

  void _clearRoutes() {
    setState(() { _routes = []; _showRouteInputs = true; _startLatLng = null; _destLatLng = null; _startCtrl.clear(); _destCtrl.clear(); });
  }

  @override
  Widget build(BuildContext context) {
    final run = widget.run;
    final isDark = widget.isDark;
    final theme = widget.theme;
    final center = run.currentPosition != null ? LatLng(run.currentPosition!.latitude, run.currentPosition!.longitude) : const LatLng(20.5937, 78.9629);
    final gpsPoints = run.routeCoordinates.map((c) => LatLng(c.latitude, c.longitude)).toList();
    final mapHeight = widget.isFullscreen ? MediaQuery.of(context).size.height : 320.0;

    return SingleChildScrollView(padding: widget.isFullscreen ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 16), child: Column(children: [
      // Route inputs
      if (_showRouteInputs && !widget.isFullscreen) ...[
        _buildInput(isDark, theme, _startCtrl, 'Starting Point', LucideIcons.mapPin, AppColors.green),
        const SizedBox(height: 8),
        _buildInput(isDark, theme, _destCtrl, 'Destination', LucideIcons.flag, AppColors.coral),
        const SizedBox(height: 8),
        SizedBox(width: double.infinity, height: 44, child: ElevatedButton.icon(
          onPressed: _isSearching ? null : _searchRoute,
          icon: _isSearching ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(LucideIcons.navigation, size: 16),
          label: Text(_isSearching ? 'Searching...' : 'Search Route'),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
        )),
        const SizedBox(height: 12),
      ],
      // Route info chips
      if (_routes.isNotEmpty && !widget.isFullscreen) ...[
        SizedBox(height: 36, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: _routes.length + 1,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            if (i == _routes.length) return ActionChip(label: const Text('Clear', style: TextStyle(fontSize: 11)), avatar: const Icon(LucideIcons.x, size: 14), onPressed: _clearRoutes);
            final r = _routes[i];
            return ChoiceChip(
              label: Text('${r.distanceKm.toStringAsFixed(1)} km · ${r.durationMin.toStringAsFixed(0)} min', style: TextStyle(fontSize: 11, color: r.isSelected ? Colors.white : null)),
              selected: r.isSelected, onSelected: (_) => _selectRoute(i),
              selectedColor: AppColors.primary, avatar: Icon(i == 0 ? LucideIcons.zap : LucideIcons.navigation, size: 14, color: r.isSelected ? Colors.white : null),
            );
          },
        )),
        const SizedBox(height: 12),
      ],
      // Map
      ClipRRect(borderRadius: BorderRadius.circular(widget.isFullscreen ? 0 : 20), child: SizedBox(height: mapHeight, child: Stack(children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(initialCenter: center, initialZoom: 15, interactionOptions: const InteractionOptions(flags: InteractiveFlag.all)),
          children: [
            TileLayer(
              urlTemplate: isDark ? 'https://a.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}@2x.png' : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.lifepulse.app', maxZoom: 19,
            ),
            // Planned routes (alternatives in grey, selected in neon blue)
            if (_routes.isNotEmpty) PolylineLayer(polylines: [
              ..._routes.where((r) => !r.isSelected).map((r) => Polyline(points: r.points, strokeWidth: 4, color: Colors.grey.withValues(alpha: 0.5))),
              ..._routes.where((r) => r.isSelected).map((r) => Polyline(points: r.points, strokeWidth: 6, color: const Color(0xFF00D4FF), borderStrokeWidth: 2, borderColor: Colors.black.withValues(alpha: 0.3))),
            ]),
            // GPS tracked path (neon green over the planned route)
            if (gpsPoints.length > 1) PolylineLayer(polylines: [
              Polyline(points: gpsPoints, strokeWidth: 5, color: const Color(0xFF39FF14), borderStrokeWidth: 2, borderColor: Colors.black.withValues(alpha: 0.5)),
            ]),
            // Markers
            MarkerLayer(markers: [
              if (_startLatLng != null) Marker(point: _startLatLng!, width: 28, height: 28, child: Container(decoration: BoxDecoration(color: AppColors.green, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2.5), boxShadow: [BoxShadow(color: AppColors.green.withValues(alpha: 0.5), blurRadius: 8)]), child: const Icon(Icons.flag, size: 14, color: Colors.white))),
              if (_destLatLng != null) Marker(point: _destLatLng!, width: 28, height: 28, child: Container(decoration: BoxDecoration(color: AppColors.coral, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2.5), boxShadow: [BoxShadow(color: AppColors.coral.withValues(alpha: 0.5), blurRadius: 8)]), child: const Icon(LucideIcons.flag, size: 14, color: Colors.white))),
              if (run.startPosition != null && run.isTracking) Marker(point: LatLng(run.startPosition!.latitude, run.startPosition!.longitude), width: 24, height: 24, child: Container(decoration: BoxDecoration(color: AppColors.green, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2.5)))),
              if (run.currentPosition != null) Marker(point: LatLng(run.currentPosition!.latitude, run.currentPosition!.longitude), width: 40, height: 40, child: AnimatedBuilder(animation: _pulseController, builder: (_, __) {
                final s = 1.0 + (_pulseController.value * 0.5); final o = 1.0 - _pulseController.value;
                final c = isDark ? const Color(0xFF39FF14) : AppColors.primary;
                return Stack(alignment: Alignment.center, children: [
                  Transform.scale(scale: s, child: Container(width: 36, height: 36, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: c.withValues(alpha: o * 0.6), width: 2)))),
                  Container(width: 16, height: 16, decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2.5), boxShadow: [BoxShadow(color: c.withValues(alpha: 0.6), blurRadius: 12, spreadRadius: 2)])),
                ]);
              })),
            ]),
          ],
        ),
        // Fullscreen toggle
        Positioned(top: 12, right: 12, child: GestureDetector(onTap: widget.onToggleFullscreen, child: Container(width: 36, height: 36, decoration: BoxDecoration(color: (isDark ? AppColors.darkSurfaceContainer : Colors.white).withValues(alpha: 0.9), shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 6)]),
          child: Icon(widget.isFullscreen ? LucideIcons.minimize2 : LucideIcons.maximize2, size: 16, color: isDark ? AppColors.secondary : AppColors.primary)))),
        // Attribution
        Positioned(bottom: 4, right: 8, child: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.7), borderRadius: BorderRadius.circular(4)),
          child: Text('© OpenStreetMap', style: TextStyle(fontSize: 8, color: isDark ? Colors.white70 : Colors.black54)))),
        // GPS error
        if (!run.hasLocationPermission && run.currentPosition == null)
          Positioned(top: 0, left: 0, right: 0, child: Container(padding: const EdgeInsets.all(12), color: AppColors.coral.withValues(alpha: 0.9),
            child: const Row(children: [Icon(Icons.location_off, color: Colors.white, size: 18), SizedBox(width: 8), Expanded(child: Text('GPS permission required.', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)))]))),
        // Recenter
        if (run.currentPosition != null)
          Positioned(bottom: 12, left: 12, child: GestureDetector(onTap: () { _mapController.move(LatLng(run.currentPosition!.latitude, run.currentPosition!.longitude), 16); },
            child: Container(width: 36, height: 36, decoration: BoxDecoration(color: (isDark ? AppColors.darkSurfaceContainer : Colors.white).withValues(alpha: 0.9), shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 6)]),
              child: Icon(LucideIcons.crosshair, size: 18, color: isDark ? AppColors.secondary : AppColors.primary)))),
      ]))),
      if (!widget.isFullscreen) ...[
        const SizedBox(height: 12),
        // Live stats
        Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: isDark ? AppColors.darkSurfaceContainer.withValues(alpha: 0.55) : AppColors.lightSurface, borderRadius: BorderRadius.circular(20), border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06))),
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
        // Controls
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (!run.isTracking) GestureDetector(onTap: () async {
            var status = await Permission.location.status;
            if (!status.isGranted) status = await Permission.location.request();
            if (status.isGranted) { run.startRun(); } else if (status.isPermanentlyDenied) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permission permanently denied.'))); await openAppSettings(); } else { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permission required.'))); }
          }, child: Container(width: 72, height: 72, decoration: BoxDecoration(gradient: AppColors.gradientPrimary, shape: BoxShape.circle, boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.5), blurRadius: 24, offset: const Offset(0, 6))]), child: const Icon(LucideIcons.play, color: Colors.white, size: 30)))
          else ...[
            GestureDetector(onTap: () => run.isPaused ? run.resumeRun() : run.pauseRun(), child: Container(width: 56, height: 56, decoration: BoxDecoration(gradient: AppColors.gradientPrimary, shape: BoxShape.circle), child: Icon(run.isPaused ? LucideIcons.play : LucideIcons.pause, color: Colors.white, size: 24))),
            const SizedBox(width: 20),
            GestureDetector(onTap: () { run.stopRun(); run.resetRun(); }, child: Container(width: 56, height: 56, decoration: const BoxDecoration(gradient: AppColors.gradientCoral, shape: BoxShape.circle), child: const Icon(LucideIcons.square, color: Colors.white, size: 24))),
          ],
        ]),
        const SizedBox(height: 16),
        GlassCard(child: Column(children: [
          Row(children: [Icon(LucideIcons.zap, size: 18, color: AppColors.secondary), const SizedBox(width: 8), Text('Current Speed', style: theme.textTheme.titleMedium)]),
          const SizedBox(height: 12),
          RichText(text: TextSpan(children: [
            TextSpan(text: run.currentSpeed.toStringAsFixed(1), style: theme.textTheme.displayLarge?.copyWith(fontSize: 48, color: AppColors.secondary)),
            TextSpan(text: ' km/h', style: theme.textTheme.bodyMedium),
          ])),
        ])),
        const SizedBox(height: 16),
        GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Icon(LucideIcons.trophy, size: 18, color: AppColors.yellow), const SizedBox(width: 8), Text('Personal Records', style: theme.textTheme.titleMedium)]),
          const SizedBox(height: 12),
          ...run.personalRecords.entries.map((e) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02), borderRadius: BorderRadius.circular(10)),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(e.key, style: theme.textTheme.bodySmall), Text(e.value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700, color: AppColors.secondary))])))),
        ])),
        const SizedBox(height: 100),
      ],
    ]));
  }

  Widget _buildInput(bool isDark, ThemeData theme, TextEditingController ctrl, String hint, IconData icon, Color iconColor) {
    return Container(
      decoration: BoxDecoration(color: isDark ? AppColors.darkSurfaceContainer.withValues(alpha: 0.7) : Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08))),
      child: TextField(controller: ctrl, style: theme.textTheme.bodyMedium, decoration: InputDecoration(
        hintText: hint, hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 13),
        prefixIcon: Icon(icon, size: 18, color: iconColor), border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
      )),
    );
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
