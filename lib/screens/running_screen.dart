import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../services/routing_service.dart';
import '../services/places_service.dart';
import '../providers/running_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/live_run_metric_panel.dart';

final List<Map<String, String>> kTiles = [
  {'name': 'OSM Standard', 'url': 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'},
  {'name': 'OSM Humanitarian', 'url': 'https://a.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png'},
  {'name': 'CartoDB Voyager', 'url': 'https://a.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}@2x.png'},
  {'name': 'CartoDB Dark', 'url': 'https://a.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}@2x.png'},
  {'name': 'CyclOSM', 'url': 'https://a.tile-cyclosm.openstreetmap.fr/cyclosm/{z}/{x}/{y}.png'},
];

enum RunState { idle, planning, running, paused, finished }

class RunningScreen extends StatefulWidget {
  final ValueChanged<bool>? onFullscreenChanged;
  const RunningScreen({super.key, this.onFullscreenChanged});
  @override State<RunningScreen> createState() => _RunningScreenState();
}

class _RunningScreenState extends State<RunningScreen> with TickerProviderStateMixin {
  final MapController _mapCtrl = MapController();
  int _tileIdx = 2;
  double _zoom = 16;
  bool _follow = true, _showStyles = false, _isFullscreen = false, _isSearching = false;
  LatLng? _curPos, _startPos;
  final List<LatLng> _gpsRoute = [];
  StreamSubscription<Position>? _posSub;
  RunState _state = RunState.idle;
  Timer? _timer;
  DateTime? _startTime;
  Duration _pausedDur = Duration.zero;
  DateTime? _pauseStart;
  double _distKm = 0, _speedKmh = 0, _paceMin = 0;
  int _calories = 0, _durSecs = 0;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  // Feature 5
  int? _highlightedRouteIdx;

  // Route planning
  final _startCtrl = TextEditingController();
  final _destCtrl = TextEditingController();
  List<RouteResult> _routes = [];
  LatLng? _routeStart, _routeDest;

  // Landmark / Places
  LatLng? _tappedPoint;
  List<NearbyLandmark> _landmarks = [];
  bool _loadingLandmarks = false;
  NearbyLandmark? _selectedLandmark;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.15).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _initLocation();
  }

  void _toggleFullscreen() {
    setState(() => _isFullscreen = !_isFullscreen);
    WidgetsBinding.instance.addPostFrameCallback((_) { widget.onFullscreenChanged?.call(_isFullscreen); });
  }

  Future<void> _initLocation() async {
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.deniedForever) return;
    try {
      final p = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.bestForNavigation));
      setState(() => _curPos = LatLng(p.latitude, p.longitude));
      _mapCtrl.move(_curPos!, _zoom);
    } catch (_) {}
    _posSub = Geolocator.getPositionStream(locationSettings: const LocationSettings(accuracy: LocationAccuracy.bestForNavigation, distanceFilter: 5)).listen(_onPos);
  }

  void _onPos(Position p) {
    final pt = LatLng(p.latitude, p.longitude);
    setState(() => _curPos = pt);
    if (_follow && _curPos != null) _mapCtrl.move(_curPos!, _zoom);
    if (_state == RunState.running) { _gpsRoute.add(pt); _calcStats(p); }
  }

  void _calcStats(Position p) {
    double d = 0;
    for (int i = 1; i < _gpsRoute.length; i++) { d += const Distance().as(LengthUnit.Kilometer, _gpsRoute[i - 1], _gpsRoute[i]); }
    final spd = p.speed * 3.6;
    setState(() { _distKm = d; _speedKmh = spd; _paceMin = spd > 0.5 ? 60.0 / spd : 0; _calories = (d * 65).round(); });
  }

  Duration _elapsed() { if (_startTime == null) return Duration.zero; return DateTime.now().difference(_startTime!) - _pausedDur; }

  // Route planning
  Future<void> _searchRoute() async {
    if (_startCtrl.text.isEmpty || _destCtrl.text.isEmpty) return;
    setState(() => _isSearching = true);
    try {
      final s = await RoutingService.geocode(_startCtrl.text);
      final d = await RoutingService.geocode(_destCtrl.text);
      if (s.isEmpty || d.isEmpty) { _snack('Location not found'); setState(() => _isSearching = false); return; }
      _routeStart = s.first.location; _routeDest = d.first.location;
      _startCtrl.text = s.first.displayName.split(',').take(2).join(',');
      _destCtrl.text = d.first.displayName.split(',').take(2).join(',');
      final routes = await RoutingService.getRoutes(_routeStart!, _routeDest!);
      setState(() { _routes = routes; _isSearching = false; _state = RunState.planning; });
      if (routes.isNotEmpty) { final all = routes.expand((r) => r.points).toList(); _fitBounds(all); }
    } catch (e) { setState(() => _isSearching = false); _snack('Error: $e'); }
  }

  void _selectRoute(int idx) { setState(() { for (int i = 0; i < _routes.length; i++) { _routes[i].isSelected = (i == idx); } }); }

  void _clearRoute() { setState(() { _routes = []; _routeStart = null; _routeDest = null; _startCtrl.clear(); _destCtrl.clear(); _state = RunState.idle; }); }

  void _fitBounds(List<LatLng> pts) {
    if (pts.length < 2) return;
    try { _mapCtrl.fitCamera(CameraFit.bounds(bounds: LatLngBounds.fromPoints(pts), padding: const EdgeInsets.all(60))); } catch (_) {}
  }

  void _startRun() {
    HapticFeedback.heavyImpact();
    setState(() { _state = RunState.running; _startTime = DateTime.now(); _gpsRoute.clear();
      if (_curPos != null) { _startPos = _curPos; _gpsRoute.add(_curPos!); } });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) { final e = _elapsed(); setState(() => _durSecs = e.inSeconds); });
  }

  void _pauseRun() { HapticFeedback.mediumImpact(); setState(() { _state = RunState.paused; _pauseStart = DateTime.now(); }); _timer?.cancel(); }

  void _resumeRun() {
    HapticFeedback.lightImpact();
    if (_pauseStart != null) { _pausedDur += DateTime.now().difference(_pauseStart!); _pauseStart = null; }
    setState(() => _state = RunState.running);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) { final e = _elapsed(); setState(() => _durSecs = e.inSeconds); });
  }

  void _finishRun() { HapticFeedback.heavyImpact(); _timer?.cancel(); setState(() => _state = RunState.finished); _showSummary(); }
  void _resetRun() { setState(() { _state = RunState.idle; _gpsRoute.clear(); _distKm = 0; _speedKmh = 0; _paceMin = 0; _calories = 0; _durSecs = 0; _pausedDur = Duration.zero; _startTime = null; _startPos = null; _routes.clear(); _routeStart = null; _routeDest = null; }); }

  String _fmtDur(int s) { final m = s ~/ 60; final sec = s % 60; return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}'; }
  String _fmtPace(double p) { if (p <= 0) return '--:--'; final m = p.floor(); final s = ((p - m) * 60).round(); return '$m:${s.toString().padLeft(2, '0')}'; }
  void _snack(String msg) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating)); }

  void _showSummary() {
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent, builder: (_) => Container(
      margin: const EdgeInsets.all(12), padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: const Color(0xFF111111), borderRadius: BorderRadius.circular(28), border: Border.all(color: Colors.white10)),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('🏃 RUN COMPLETE!', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _sumStat('Distance', '${_distKm.toStringAsFixed(2)} km'), _sumStat('Time', _fmtDur(_durSecs)),
          _sumStat('Pace', '${_fmtPace(_paceMin)}/km'), _sumStat('Calories', '$_calories kcal'),
        ]),
        const SizedBox(height: 20),
        SizedBox(width: double.infinity, height: 48, child: ElevatedButton(onPressed: () { Navigator.pop(context); _resetRun(); },
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E5FF), foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          child: const Text('SAVE & CLOSE', style: TextStyle(fontWeight: FontWeight.w800)))),
      ])));
  }

  Widget _sumStat(String l, String v) => Column(children: [Text(v, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)), Text(l, style: const TextStyle(color: Colors.white38, fontSize: 10))]);

  @override
  Widget build(BuildContext context) {
    final url = kTiles[_tileIdx]['url']!;
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isDark = theme.brightness == Brightness.dark;

    final isRunning = _state == RunState.running || _state == RunState.paused;
    final mapHeight = isRunning ? size.height * 0.6 : 280.0; // 220px + extra for safe area/padding

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDeep : AppColors.lightBg,
      body: Stack(
        children: [
          // ── MAIN CONTENT ──
          Column(
            children: [
              // 1. Map Section
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOutCubic,
                height: mapHeight,
                width: double.infinity,
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapCtrl,
                      options: MapOptions(
                        initialCenter: _curPos ?? const LatLng(20.5937, 78.9629),
                        initialZoom: _zoom,
                        maxZoom: 19,
                        minZoom: 3,
                        onPositionChanged: (cam, gesture) {
                          if (gesture && _follow) setState(() => _follow = false);
                          _zoom = cam.zoom ?? _zoom;
                        },
                        onTap: (_, latLng) => _onMapTap(latLng),
                      ),
                      children: [
                        TileLayer(urlTemplate: url, userAgentPackageName: 'com.lifepulse.app', maxZoom: 19),
                        // Planned routes
                        if (_routes.isNotEmpty) PolylineLayer(polylines: [
                          ..._routes.where((r) => !r.isSelected).map((r) => Polyline(points: r.points, strokeWidth: 4, color: Colors.grey.withValues(alpha: 0.5))),
                          ..._routes.where((r) => r.isSelected).map((r) => Polyline(points: r.points, strokeWidth: 6, color: AppColors.voltCyan, borderStrokeWidth: 2, borderColor: Colors.black.withValues(alpha: 0.3))),
                        ]),
                        // GPS path
                        if (_gpsRoute.length > 1) PolylineLayer(polylines: [Polyline(points: _gpsRoute, strokeWidth: 5, color: AppColors.voltCyan, borderStrokeWidth: 2, borderColor: Colors.black.withValues(alpha: 0.4))]),
                        // Tapped point marker
                        if (_tappedPoint != null) MarkerLayer(markers: [
                          Marker(point: _tappedPoint!, width: 36, height: 36, child: Container(decoration: BoxDecoration(color: AppColors.pulseRed, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2.5), boxShadow: [BoxShadow(color: AppColors.pulseRed.withValues(alpha: 0.4), blurRadius: 10)]), child: const Icon(Icons.place, size: 18, color: Colors.white))),
                        ]),
                        // Active markers
                        MarkerLayer(markers: [
                          if (_routeStart != null) Marker(point: _routeStart!, width: 28, height: 28, child: Container(decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)), child: const Icon(Icons.my_location, size: 14, color: Colors.white))),
                          if (_routeDest != null) Marker(point: _routeDest!, width: 28, height: 28, child: Container(decoration: BoxDecoration(color: AppColors.pulseRed, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)), child: const Icon(Icons.flag, size: 14, color: Colors.white))),
                          if (_startPos != null && _state == RunState.running) Marker(point: _startPos!, width: 24, height: 24, child: Container(decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2.5)))),
                          if (_curPos != null) Marker(point: _curPos!, width: 48, height: 48, child: AnimatedBuilder(animation: _pulseAnim, builder: (_, c) => Transform.scale(scale: _state == RunState.running ? _pulseAnim.value : 1.0, child: c),
                            child: Stack(alignment: Alignment.center, children: [
                              Container(width: 48, height: 48, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.voltCyan.withValues(alpha: 0.15))),
                              Container(width: 18, height: 18, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.voltCyan, border: Border.all(color: Colors.white, width: 2.5), boxShadow: [BoxShadow(color: AppColors.voltCyan.withValues(alpha: 0.6), blurRadius: 10, spreadRadius: 2)])),
                            ]))),
                        ]),
                      ],
                    ),
                    // Map Controls Overlays
                    Positioned(top: 48, left: 16, child: _mapBtn(Icons.layers, () => setState(() => _showStyles = !_showStyles))),
                    Positioned(bottom: 24, right: 16, child: _mapBtn(_follow ? Icons.my_location : Icons.location_searching, () { if (_curPos != null) { setState(() => _follow = true); _mapCtrl.move(_curPos!, _zoom); } }, color: _follow ? AppColors.voltCyan : null)),
                    Positioned(right: 16, top: 48, child: Column(children: [
                      _mapBtn(Icons.add, () { _zoom = min(_zoom + 1, 19); _mapCtrl.move(_mapCtrl.camera.center, _zoom); }),
                      const SizedBox(height: 8),
                      _mapBtn(Icons.remove, () { _zoom = max(_zoom - 1, 3); _mapCtrl.move(_mapCtrl.camera.center, _zoom); }),
                    ])),
                    // Style Picker
                    if (_showStyles) Positioned(top: 48, left: 64, child: Container(padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white12)),
                      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: kTiles.asMap().entries.map((e) {
                        final sel = e.key == _tileIdx;
                        return GestureDetector(onTap: () => setState(() { _tileIdx = e.key; _showStyles = false; }),
                          child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), margin: const EdgeInsets.only(bottom: 2),
                            decoration: BoxDecoration(color: sel ? AppColors.voltCyan.withValues(alpha: 0.15) : Colors.transparent, borderRadius: BorderRadius.circular(8)),
                            child: Text(e.value['name']!, style: TextStyle(color: sel ? AppColors.voltCyan : Colors.white70, fontSize: 12))));
                      }).toList()))),
                  ],
                ),
              ),

              // 2. Bottom Section (Pre-run UI or Active UI)
              Expanded(
                child: isRunning
                    ? Container(color: Colors.transparent) // Space filled by overlapping panel
                    : _buildPreRunUI(theme, isDark),
              ),
            ],
          ),

          // ── OVERLAYS ──
          
          // Live Run Metric Panel (overlays bottom 40%)
          if (isRunning)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: LiveRunMetricPanel(
                pace: _fmtPace(_paceMin),
                distance: _distKm.toStringAsFixed(2),
                bpm: 142, // Mock BPM for UI spec
                duration: _fmtDur(_durSecs),
                elevationData: const [0, 5, 12, 10, 25, 30, 28, 45, 40, 35, 15, 0], // Mock elevation
              ),
            ),

          // Floating Pause/End Button in Active Run
          if (isRunning)
            Positioned(
              top: 48,
              right: 72,
              child: _buildActiveControls(),
            ),
        ],
      ),
    );
  }

  Widget _buildPreRunUI(ThemeData theme, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenMargin),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.md),
          Text('Plan Your Route', style: theme.textTheme.headlineLarge),
          const SizedBox(height: AppSpacing.md),
          // Route inputs
          _routeInput(_startCtrl, 'Starting Point', Icons.my_location, Colors.green, isDark),
          const SizedBox(height: AppSpacing.sm),
          _routeInput(_destCtrl, 'Destination', Icons.flag, AppColors.pulseRed, isDark),
          const SizedBox(height: AppSpacing.md),
          Row(children: [
            Expanded(child: SizedBox(height: 48, child: ElevatedButton.icon(
              onPressed: _isSearching ? null : _searchRoute,
              icon: _isSearching ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.search, size: 20),
              label: Text(_isSearching ? 'Searching...' : 'Find Route', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.irisViolet, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            ))),
            if (_routes.isNotEmpty) ...[const SizedBox(width: 12),
              SizedBox(height: 48, child: OutlinedButton(onPressed: _clearRoute, style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), side: BorderSide(color: AppColors.borderSubtle)), child: Text('Clear', style: TextStyle(fontSize: 14, color: AppColors.textPrimary))))],
          ]),
          const SizedBox(height: AppSpacing.lg),
          // Start CTA
          SizedBox(
            width: double.infinity,
            height: 64,
            child: ElevatedButton(
              onPressed: _startRun,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.pulseRed,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.pillRadius)),
              ),
              child: const Text('Start Run', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
            ),
          ),
          const SizedBox(height: AppSpacing.navHeight + 20), // Nav clearance
        ],
      ),
    );
  }

  Widget _buildActiveControls() {
    return GestureDetector(
      onLongPress: _finishRun,
      onTap: _state == RunState.running ? _pauseRun : _resumeRun,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Icon(
          _state == RunState.running ? Icons.pause : Icons.play_arrow,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }

  // ── Map tap → fetch nearby landmarks ──────────────────────────────────────
  Future<void> _onMapTap(LatLng point) async {
    if (_state == RunState.running || _state == RunState.paused) return;
    setState(() {
      _tappedPoint = point;
      _landmarks = [];
      _loadingLandmarks = true;
    });
    _mapCtrl.move(point, _zoom);
    setState(() => _follow = false);
    final results = await PlacesService.fetchNearbyLandmarks(point);
    if (!mounted) return;
    setState(() { _landmarks = results; _loadingLandmarks = false; });
    if (results.isEmpty) _snack('No nearby places found at this location');
  }

  // ── Landmark detail bottom sheet ──────────────────────────────────────────
  void _showLandmarkDetail(NearbyLandmark lm) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF111827) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: lm.color.withValues(alpha: 0.3)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 56, height: 56, decoration: BoxDecoration(color: lm.color.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: Icon(lm.icon, size: 28, color: lm.color)),
          const SizedBox(height: 12),
          Text(lm.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18), textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: lm.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
            child: Text(lm.category.replaceAll('_', ' ').toUpperCase(),
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: lm.color, letterSpacing: 1))),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _destCtrl.text = lm.name;
                _routeDest = lm.location;
              },
              icon: const Icon(Icons.flag, size: 16),
              label: const Text('Set as Destination'),
              style: OutlinedButton.styleFrom(foregroundColor: lm.color, side: BorderSide(color: lm.color)),
            )),
            const SizedBox(width: 10),
            Expanded(child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _mapCtrl.move(lm.location, 17);
              },
              icon: const Icon(Icons.zoom_in_map, size: 16),
              label: const Text('Zoom In'),
              style: ElevatedButton.styleFrom(backgroundColor: lm.color, foregroundColor: Colors.white),
            )),
          ]),
        ]),
      ),
    );
  }

  Widget _startButton() => GestureDetector(onTap: _startRun, child: Container(width: 72, height: 72,
    decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF6C5CE7), Color(0xFF8B7CF6)]), shape: BoxShape.circle,
      boxShadow: [BoxShadow(color: const Color(0xFF6C5CE7).withValues(alpha: 0.5), blurRadius: 24, offset: const Offset(0, 6))]),
    child: const Icon(Icons.play_arrow, color: Colors.white, size: 32)));

  Widget _ctrlBtn(IconData icon, String label, Color color, VoidCallback onTap) => GestureDetector(onTap: onTap, child: Column(children: [
    Container(width: 56, height: 56, decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle, border: Border.all(color: color, width: 2)),
      child: Icon(icon, color: color, size: 26)),
    const SizedBox(height: 4), Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
  ]));

  Widget _mapBtn(IconData icon, VoidCallback onTap, {Color? color}) => GestureDetector(onTap: onTap, child: Container(width: 38, height: 38,
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 6)]),
    child: Icon(icon, size: 18, color: color ?? Colors.black87)));

  Widget _routeInput(TextEditingController ctrl, String hint, IconData icon, Color c, bool isDark) => Container(
    decoration: BoxDecoration(color: isDark ? AppColors.surfaceElevated : Colors.white, borderRadius: BorderRadius.circular(14),
      border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08))),
    child: TextField(controller: ctrl, style: const TextStyle(fontSize: 13), decoration: InputDecoration(hintText: hint, hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
      prefixIcon: Icon(icon, size: 18, color: c), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 12))));

  Widget _stat(String v, String l) => Column(mainAxisSize: MainAxisSize.min, children: [
    Text(v, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)), Text(l, style: TextStyle(fontSize: 9, color: Colors.grey[500], letterSpacing: 0.5))]);
  Widget _miniStat(String v, String l) => Column(mainAxisSize: MainAxisSize.min, children: [
    Text(v, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)), Text(l, style: const TextStyle(color: Colors.white38, fontSize: 9))]);
  Widget _divider() => Container(width: 1, height: 36, color: Colors.grey.withValues(alpha: 0.2));

  // ──── Feature 5: Saved Routes Bottom Sheet ────
  void _showSavedRoutes() {
    final rp = context.read<RunningProvider>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(20),
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF111111)
              : Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.route, color: Color(0xFF6C5CE7), size: 20),
              const SizedBox(width: 8),
              Text('My Routes', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black, fontSize: 18, fontWeight: FontWeight.w800)),
            ]),
            const SizedBox(height: 14),
            rp.savedRoutes.isEmpty
              ? const Center(child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('No routes saved yet. Complete a run to auto-save your path!',
                      textAlign: TextAlign.center, style: TextStyle(color: Colors.grey))))
              : Expanded(
                  child: ListView.separated(
                    itemCount: rp.savedRoutes.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final r = rp.savedRoutes[i];
                      String fmtDur(Duration d) {
                        final m = d.inMinutes; final s = d.inSeconds % 60;
                        return '${m}m ${s.toString().padLeft(2, '0')}s';
                      }
                      return GestureDetector(
                        onTap: () {
                          setState(() => _highlightedRouteIdx = i);
                          Navigator.pop(context);
                          if (r.points.isNotEmpty) {
                            final pts = r.points.map((p) => LatLng(p.latitude, p.longitude)).toList();
                            _fitBounds(pts);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                          ),
                          child: Row(children: [
                            Container(width: 40, height: 40, decoration: BoxDecoration(color: const Color(0xFF6C5CE7).withValues(alpha: 0.15), shape: BoxShape.circle),
                              child: const Icon(Icons.route, color: Color(0xFF6C5CE7), size: 20)),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(r.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                              Text('${r.distanceKm} km · ${r.runCount}× run · Best: ${fmtDur(r.bestTime)}',
                                style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                              Text('Avg: ${fmtDur(r.avgTime)}', style: TextStyle(color: Colors.grey[600], fontSize: 10)),
                            ])),
                            const Icon(Icons.chevron_right, color: Colors.white38, size: 20),
                          ]),
                        ),
                      );
                    },
                  )),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() { _posSub?.cancel(); _timer?.cancel(); _pulseCtrl.dispose(); _startCtrl.dispose(); _destCtrl.dispose();
    widget.onFullscreenChanged?.call(false); super.dispose(); }
}
