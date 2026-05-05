import re

with open('lib/screens/running_screen.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# 1. Update imports
code = code.replace(
    "import 'package:flutter_map/flutter_map.dart';\nimport 'package:latlong2/latlong.dart';", 
    "import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';"
)
code = code.replace("import '../utils/cached_tile_provider.dart';\n", "")

# 2. Add mapbox token configuration
token_config = """// ─── MAPBOX CONFIGURATION ───
// REPLACE 'YOUR_MAPBOX_ACCESS_TOKEN' with your actual token from https://account.mapbox.com/
const String _mapboxToken = 'YOUR_MAPBOX_ACCESS_TOKEN';
"""
code = re.sub(
    r"// ─── FREE PREMIUM MAP TILES.*?String _lightTileUrl.*?\.png';",
    token_config,
    code,
    flags=re.DOTALL
)

# 3. Replace _TrackerTabState and build method
tracker_tab_state_old = """class _TrackerTabState extends State<_TrackerTab> with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();"""

tracker_tab_state_new = """class _TrackerTabState extends State<_TrackerTab> with SingleTickerProviderStateMixin {
  MapboxMap? _mapboxMap;
  PointAnnotationManager? _pointAnnotationManager;
  PolylineAnnotationManager? _polylineAnnotationManager;"""

code = code.replace(tracker_tab_state_old, tracker_tab_state_new)

# Update didUpdateWidget
did_update_old = """    // Auto-pan map to current position while tracking
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
  }"""

did_update_new = """    // Auto-pan map to current position while tracking
    if (widget.run.isTracking && widget.run.currentPosition != null && !widget.run.isPaused) {
      _mapboxMap?.setCamera(CameraOptions(
        center: Point(coordinates: Position(widget.run.currentPosition!.longitude, widget.run.currentPosition!.latitude)),
        zoom: 15.0,
      ));
    }
  }

  _onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
    _pointAnnotationManager = await mapboxMap.annotations.createPointAnnotationManager();
    _polylineAnnotationManager = await mapboxMap.annotations.createPolylineAnnotationManager();
  }"""

code = code.replace(did_update_old, did_update_new)

# Replace build
build_old = """    final center = run.currentPosition != null
        ? LatLng(run.currentPosition!.latitude, run.currentPosition!.longitude)
        : const LatLng(20.5937, 78.9629); // Default to India center

    // Build route polyline points
    final routePoints = run.routeCoordinates
        .map((c) => LatLng(c.latitude, c.longitude))
        .toList();"""

build_new = """    final centerPosition = run.currentPosition != null
        ? Position(run.currentPosition!.longitude, run.currentPosition!.latitude)
        : Position(78.9629, 20.5937); // Default to India center"""

code = code.replace(build_old, build_new)

# Replace FlutterMap
flutter_map_old = """FlutterMap(
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
        )"""

flutter_map_new = """MapWidget(
          key: const ValueKey("mapWidget"),
          resourceOptions: ResourceOptions(accessToken: _mapboxToken),
          cameraOptions: CameraOptions(
            center: Point(coordinates: centerPosition),
            zoom: 15.0,
          ),
          styleUri: isDark ? MapboxStyles.NAVIGATION_NIGHT : MapboxStyles.MAPBOX_STREETS,
          onMapCreated: _onMapCreated,
        )"""

code = code.replace(flutter_map_old, flutter_map_new)

# Replace attribution
code = code.replace("© Mapbox © OpenStreetMap", "© Mapbox")

# Replace recenter
recenter_old = """                  _mapController.move(
                    LatLng(run.currentPosition!.latitude, run.currentPosition!.longitude),
                    16,
                  );"""

recenter_new = """                  _mapboxMap?.setCamera(CameraOptions(
                    center: Point(coordinates: Position(run.currentPosition!.longitude, run.currentPosition!.latitude)),
                    zoom: 16.0,
                  ));"""

code = code.replace(recenter_old, recenter_new)

with open('lib/screens/running_screen.dart', 'w', encoding='utf-8') as f:
    f.write(code)
