import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geocoding/geocoding.dart';

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/live_run_metric_panel.dart';
import '../widgets/glass_card.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../providers/weather_provider.dart';
import '../providers/theme_provider.dart';
import 'package:intl/intl.dart';
import '../constants/activity_types.dart' hide ActivityType;
import 'fitness_screen.dart';

enum RunState { planning, countdown, running, paused, finished }

class RunningScreen extends StatefulWidget {
  final ValueChanged<bool>? onFullscreenChanged;
  const RunningScreen({super.key, this.onFullscreenChanged});
  @override State<RunningScreen> createState() => _RunningScreenState();
}

class _RunningScreenState extends State<RunningScreen> with TickerProviderStateMixin {
  final MapController _mapCtrl = MapController();
  double _zoom = 16;
  bool _follow = true;
  LatLng? _curPos;
  final List<LatLng> _gpsRoute = [];
  StreamSubscription<Position>? _posSub;
  
  RunState _state = RunState.planning;
  Timer? _timer;
  DateTime? _startTime;
  Duration _pausedDur = Duration.zero;
  DateTime? _pauseStart;
  
  double _distKm = 0, _paceMin = 0;
  int _calories = 0, _durSecs = 0;
  int _estimatedBpm = 0;
  double _lastSpeed = 0; // km/h from GPS
  
  // Animation for pulsing user dot
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  // Countdown animation
  int _countdown = 3;
  
  // Mock Route for Pre-run
  List<LatLng> _mockPreRunRoute = [];
  LatLng? _startRoutePos;
  LatLng? _endRoutePos;

  // Routing state
  final TextEditingController _startLocCtrl = TextEditingController();
  final TextEditingController _destLocCtrl = TextEditingController();
  bool _isLoadingRoute = false;
  List<List<LatLng>> _alternativeRoutes = [];
  int _selectedRouteIndex = 0;

  String _selectedRunType = 'Outdoor Run';
  String _selectedSportCategory = 'Cardio';
  bool _audioPrompts = true;
  bool _isFullScreenMap = false;

  // Pre-run target inputs
  String _targetLeftLabel = 'Target Pace';
  String _targetLeftValue = '5:30 /km';
  String _targetRightLabel = 'Distance';
  String _targetRightValue = '5.0 km';

  // Map layer selection
  int _selectedMapLayer = 0;
  bool? _mapIsDark;
  final List<Map<String, String>> _mapLayers = [
    {'name': 'Standard', 'dark': 'https://a.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}@2x.png', 'light': 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'},
    {'name': 'Humanitarian', 'dark': 'https://a.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}@2x.png', 'light': 'https://a.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png'},
    {'name': 'Cycling', 'dark': 'https://a.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}@2x.png', 'light': 'https://tile.thunderforest.com/cycle/{z}/{x}/{y}.png?apikey=6170aad10dfd42a38d4d8c709a536f38'},
    {'name': 'Transport', 'dark': 'https://a.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}@2x.png', 'light': 'https://tile.thunderforest.com/transport/{z}/{x}/{y}.png?apikey=6170aad10dfd42a38d4d8c709a536f38'},
    {'name': 'Topo', 'dark': 'https://a.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}@2x.png', 'light': 'https://tile.opentopomap.org/{z}/{x}/{y}.png'},
  ];

  final GlobalKey _mapKey = GlobalKey();

  Future<void> _findRoute() async {
    if (_startLocCtrl.text.isEmpty || _destLocCtrl.text.isEmpty) return;

    setState(() {
      _isLoadingRoute = true;
      _alternativeRoutes.clear();
      _mockPreRunRoute.clear();
    });

    try {
      // 1. Geocode Start and Dest using Nominatim
      final headers = {'User-Agent': 'LifepulseApp/1.0 (contact@example.com)'};
      final startRes = await http.get(Uri.parse('https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(_startLocCtrl.text)}&format=json&limit=1'), headers: headers);
      final destRes = await http.get(Uri.parse('https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(_destLocCtrl.text)}&format=json&limit=1'), headers: headers);

      final startData = jsonDecode(startRes.body) as List;
      final destData = jsonDecode(destRes.body) as List;

      if (startData.isEmpty || destData.isEmpty) throw Exception('Location not found');

      final startLat = double.parse(startData[0]['lat']);
      final startLon = double.parse(startData[0]['lon']);
      final destLat = double.parse(destData[0]['lat']);
      final destLon = double.parse(destData[0]['lon']);

      setState(() {
        _startRoutePos = LatLng(startLat, startLon);
        _endRoutePos = LatLng(destLat, destLon);
      });

      // Move map to center
      final center = LatLng((startLat + destLat) / 2, (startLon + destLon) / 2);
      _mapCtrl.move(center, 13); // Zoom out a bit

      // 2. Fetch OSRM
      final url = 'http://router.project-osrm.org/route/v1/foot/$startLon,$startLat;$destLon,$destLat?geometries=geojson&overview=full&alternatives=true';
      final res = await http.get(Uri.parse(url));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final routes = data['routes'] as List;

        List<List<LatLng>> parsedRoutes = [];

        for (var route in routes) {
          final geometry = route['geometry']['coordinates'] as List;
          List<LatLng> polyline = geometry.map((c) => LatLng(c[1], c[0])).toList();
          parsedRoutes.add(polyline);
        }

        if (parsedRoutes.isNotEmpty) {
          setState(() {
            _alternativeRoutes = parsedRoutes;
            _selectedRouteIndex = 0;
            _mockPreRunRoute = parsedRoutes[0];

            // Update distance target
            final distanceMeters = routes[0]['distance'] as num;
            final distKm = distanceMeters / 1000.0;
            _targetRightLabel = 'Distance';
            _targetRightValue = '${distKm.toStringAsFixed(2)} km';
            
            // Update time estimation
            final durationSecs = routes[0]['duration'] as num;
            final minutes = (durationSecs / 60).round();
            _targetLeftLabel = 'Est. Time';
            _targetLeftValue = '$minutes min';
          });
        }
      } else {
        throw Exception('Routing failed: ${res.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not find route: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingRoute = false);
      }
    }
  }

  void _toggleFullScreen() {
    setState(() {
      _isFullScreenMap = !_isFullScreenMap;
    });
    widget.onFullscreenChanged?.call(_isFullScreenMap || _state != RunState.planning);
  }

  void _resetLocation() {
    if (_curPos != null) {
      _mapCtrl.move(_curPos!, 16);
      setState(() => _follow = true);
    } else {
      _initLocation();
    }
  }

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.15).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _initLocation();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final app = context.read<AppProvider>();
    if (app.activeRunPlan != null && _state == RunState.planning) {
      final plan = app.activeRunPlan!;
      
      String foundCat = 'Cardio';
      for (final cat in kSportsCategories.keys) {
        if (kSportsCategories[cat]!.any((s) => s.label == plan.type)) {
          foundCat = cat;
          break;
        }
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _selectedSportCategory = foundCat;
          _selectedRunType = plan.type;
          _targetLeftLabel = 'Duration';
          _targetLeftValue = plan.duration;
          _targetRightLabel = 'Target Burn';
          _targetRightValue = '${plan.kcal} kcal';
        });
        app.setActiveRunPlan(null);
      });
    }
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

    // Use platform-specific settings for continuous updates
    late LocationSettings locSettings;
    if (Platform.isAndroid) {
      locSettings = AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
        intervalDuration: const Duration(seconds: 1),
        forceLocationManager: false,
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'LifePulse Running',
          notificationText: 'Tracking your run in the background',
          enableWakeLock: true,
        ),
      );
    } else if (Platform.isIOS) {
      locSettings = AppleSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
        activityType: ActivityType.fitness,
        pauseLocationUpdatesAutomatically: false,
        allowBackgroundLocationUpdates: true,
        showBackgroundLocationIndicator: true,
      );
    } else {
      locSettings = const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
      );
    }

    _posSub = Geolocator.getPositionStream(
      locationSettings: locSettings,
    ).listen(_onPos);
  }

  void _onPos(Position p) {
    final pt = LatLng(p.latitude, p.longitude);
    final speedKmh = p.speed * 3.6; // m/s to km/h
    setState(() {
      _curPos = pt;
      _lastSpeed = speedKmh;
    });
    if (_follow && _curPos != null) _mapCtrl.move(_curPos!, _zoom);
    if (_state == RunState.running) {
      // Only add point if it's far enough from last point (avoid GPS jitter)
      if (_gpsRoute.isEmpty) {
        _gpsRoute.add(pt);
      } else {
        final lastPt = _gpsRoute.last;
        final distFromLast = const Distance().as(LengthUnit.Meter, lastPt, pt);
        if (distFromLast >= 2) { // At least 2 meters to avoid jitter
          _gpsRoute.add(pt);
        }
      }
      _updateRunStats();
    }
  }

  void _updateRunStats() {
    double d = 0;
    for (int i = 1; i < _gpsRoute.length; i++) {
      d += const Distance().as(LengthUnit.Kilometer, _gpsRoute[i - 1], _gpsRoute[i]);
    }
    setState(() {
      _distKm = d;
      // Pace from GPS speed (instantaneous)
      if (_lastSpeed > 1.0) {
        _paceMin = 60.0 / _lastSpeed; // min/km
      } else if (_distKm > 0.005 && _durSecs > 0) {
        // Fallback: pace from elapsed time / distance
        _paceMin = (_durSecs / 60.0) / _distKm;
      }
      _calories = (_distKm * 65).round();
      // Estimate heart rate from speed
      _estimatedBpm = _estimateHeartRate(_lastSpeed);
    });
  }

  int _estimateHeartRate(double speedKmh) {
    // Estimate BPM based on running speed
    if (speedKmh < 0.5) return 72;  // Resting
    if (speedKmh < 4) return 90 + (speedKmh * 5).round();   // Walking
    if (speedKmh < 8) return 120 + ((speedKmh - 4) * 8).round();  // Jogging
    if (speedKmh < 12) return 150 + ((speedKmh - 8) * 5).round(); // Running
    return 170 + ((speedKmh - 12) * 3).round().clamp(0, 25);  // Sprinting
  }

  Duration _elapsed() {
    if (_startTime == null) return Duration.zero;
    return DateTime.now().difference(_startTime!) - _pausedDur;
  }

  void _startCountdown() {
    HapticFeedback.heavyImpact();
    setState(() {
      _state = RunState.countdown;
      _countdown = 3;
    });
    
    // Hide bottom nav by triggering callback
    widget.onFullscreenChanged?.call(true);

    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 1) {
        HapticFeedback.heavyImpact();
        setState(() => _countdown--);
      } else {
        HapticFeedback.vibrate();
        timer.cancel();
        _startRun();
      }
    });
  }

  void _startRun() {
    setState(() {
      _state = RunState.running;
      _startTime = DateTime.now();
      _distKm = 0;
      _paceMin = 0;
      _calories = 0;
      _durSecs = 0;
      _gpsRoute.clear();
      if (_curPos != null) _gpsRoute.add(_curPos!);
      _follow = true;
    });
    if (_curPos != null) _mapCtrl.move(_curPos!, 18); // Zoom in and center
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _durSecs = _elapsed().inSeconds;
        // Recalculate distance from route every second
        double d = 0;
        for (int i = 1; i < _gpsRoute.length; i++) {
          d += const Distance().as(LengthUnit.Kilometer, _gpsRoute[i - 1], _gpsRoute[i]);
        }
        _distKm = d;
        // Calculate pace from distance and time as fallback
        if (_distKm > 0.005 && _durSecs > 0 && _lastSpeed < 1.0) {
          _paceMin = (_durSecs / 60.0) / _distKm;
        }
        _calories = (_distKm * 65).round();
        _estimatedBpm = _estimateHeartRate(_lastSpeed);
      });
    });
  }

  void _pauseRun() {
    HapticFeedback.mediumImpact();
    setState(() {
      _state = RunState.paused;
      _pauseStart = DateTime.now();
    });
    _timer?.cancel();
  }

  void _resumeRun() {
    HapticFeedback.lightImpact();
    if (_pauseStart != null) {
      _pausedDur += DateTime.now().difference(_pauseStart!);
      _pauseStart = null;
    }
    setState(() => _state = RunState.running);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _durSecs = _elapsed().inSeconds);
    });
  }

  void _finishRun() {
    HapticFeedback.heavyImpact();
    _timer?.cancel();
    setState(() => _state = RunState.finished);
    _showSummary();
  }

  void _resetRun() {
    widget.onFullscreenChanged?.call(_isFullScreenMap);
    setState(() {
      _state = RunState.planning;
      _gpsRoute.clear();
      _distKm = 0;
      _paceMin = 0;
      _calories = 0;
      _durSecs = 0;
      _estimatedBpm = 0;
      _lastSpeed = 0;
      _pausedDur = Duration.zero;
      _startTime = null;
    });
    if (_curPos != null) _mapCtrl.move(_curPos!, 16); // Reset zoom
  }

  String _fmtDur(int s) {
    final m = s ~/ 60;
    final sec = s % 60;
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  String _fmtPace(double p) {
    if (p <= 0 || p > 60) return '--:--';
    final m = p.floor();
    final s = ((p - m) * 60).round();
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _startLocCtrl.dispose();
    _destLocCtrl.dispose();
    _posSub?.cancel();
    _timer?.cancel();
    _pulseCtrl.dispose();
    widget.onFullscreenChanged?.call(false);
    super.dispose();
  }

  Widget _buildMapWidget(String mapUrl, bool isDark, bool isRunningPhase) {
    return FlutterMap(
      key: _mapKey,
      mapController: _mapCtrl,
      options: MapOptions(
        initialCenter: _curPos ?? const LatLng(20.5937, 78.9629),
        initialZoom: _zoom,
        interactionOptions: InteractionOptions(
          flags: (isRunningPhase || _isFullScreenMap) ? InteractiveFlag.all : (InteractiveFlag.all & ~InteractiveFlag.drag),
        ),
        onPositionChanged: (cam, gesture) {
          if (gesture && _follow) setState(() => _follow = false);
          _zoom = cam.zoom ?? _zoom;
        },
      ),
      children: [
        TileLayer(
          urlTemplate: mapUrl, 
          userAgentPackageName: 'com.example.lifepulse',
          maxZoom: 19,
        ),
        
        // Pre-run Route Suggestion (Cyan)
        if (!isRunningPhase)
          PolylineLayer(polylines: [
            Polyline(
              points: _mockPreRunRoute,
              strokeWidth: 4,
              color: AppColors.voltCyan,
            ),
          ]),

        // Active Live Route (Pulse Red)
        if (_gpsRoute.length >= 2)
          PolylineLayer(polylines: [
            Polyline(
              points: List.from(_gpsRoute),
              strokeWidth: 6,
              color: AppColors.pulseRed,
              borderStrokeWidth: 2,
              borderColor: Colors.white.withValues(alpha: 0.4),
            )
          ]),

        // User Location Marker
        MarkerLayer(markers: [
          if (_startRoutePos != null && !isRunningPhase)
            Marker(
              point: _startRoutePos!,
              width: 32,
              height: 32,
              child: const Icon(LucideIcons.mapPin, color: AppColors.voltCyan, size: 32),
            ),
          if (_endRoutePos != null && !isRunningPhase)
            Marker(
              point: _endRoutePos!,
              width: 32,
              height: 32,
              child: const Icon(LucideIcons.flag, color: AppColors.pulseRed, size: 32),
            ),
          if (_curPos != null)
            Marker(
              point: _curPos!,
              width: 48,
              height: 48,
              child: AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, c) => Transform.scale(
                  scale: _pulseAnim.value,
                  child: c,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.pulseRed.withValues(alpha: 0.2),
                      ),
                    ),
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.pulseRed,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.pulseRed.withValues(alpha: 0.6),
                            blurRadius: 8,
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ]),
      ],
    );
  }

  Widget _buildRoutePlannerUI(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.navigation, color: AppColors.voltCyan, size: 18),
              const SizedBox(width: 8),
              Text('Plan Your Route', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: TextField(
              controller: _startLocCtrl,
              decoration: InputDecoration(
                hintText: 'Start (e.g. Central Park)',
                hintStyle: TextStyle(fontSize: 13, color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.5)),
                prefixIcon: const Icon(LucideIcons.mapPin, color: AppColors.voltCyan, size: 16),
                filled: true,
                fillColor: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
              style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 13),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: TextField(
              controller: _destLocCtrl,
              decoration: InputDecoration(
                hintText: 'Destination (e.g. Times Square)',
                hintStyle: TextStyle(fontSize: 13, color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.5)),
                prefixIcon: const Icon(LucideIcons.flag, color: AppColors.pulseRed, size: 16),
                filled: true,
                fillColor: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
              style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 13),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton(
              onPressed: _isLoadingRoute ? null : _findRoute,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.voltCyan,
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: _isLoadingRoute
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                  : const Text('Find Routes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ),
          if (_alternativeRoutes.length > 1) ...[
            const SizedBox(height: 12),
            Text('Alternative Routes', style: TextStyle(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.7), fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              children: List.generate(_alternativeRoutes.length, (index) {
                final isSelected = _selectedRouteIndex == index;
                return ChoiceChip(
                  label: Text('Route ${index + 1}', style: const TextStyle(fontSize: 11)),
                  selected: isSelected,
                  padding: EdgeInsets.zero,
                  selectedColor: AppColors.voltCyan.withValues(alpha: 0.2),
                  labelStyle: TextStyle(color: isSelected ? AppColors.voltCyan : (isDark ? Colors.white : Colors.black)),
                  onSelected: (val) {
                    setState(() {
                      _selectedRouteIndex = index;
                      _mockPreRunRoute = _alternativeRoutes[index];
                    });
                  },
                );
              }),
            ),
          ]
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isDark = theme.brightness == Brightness.dark;
    
    // Map URL from selected layer
    final mapModeIsDark = _mapIsDark ?? isDark;
    final layer = _mapLayers[_selectedMapLayer];
    final mapUrl = mapModeIsDark ? layer['dark']! : layer['light']!;

    final isRunningPhase = _state == RunState.running || _state == RunState.paused || _state == RunState.countdown;
    final weather = context.watch<WeatherProvider>().weather;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // ── 1. PLANNING VIEW (Scrollable) ──
          if (!isRunningPhase && !_isFullScreenMap)
            Positioned.fill(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: MediaQuery.of(context).padding.top + 16),
                    
                    // Route Planner
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildRoutePlannerUI(isDark),
                    ),
                    const SizedBox(height: 16),
                    
                    // Map Card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SizedBox(
                        height: 260,
                        width: double.infinity,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(32),
                          child: Stack(
                            children: [
                              _buildMapWidget(mapUrl, isDark, false),
                              
                              // Pre-run Map Controls (overlaying the inline map card)
                              Positioned(
                                top: 16,
                                right: 16,
                                child: Column(
                                  children: [
                                    _mapControlBtn(
                                      icon: _isFullScreenMap ? Icons.fullscreen_exit : Icons.fullscreen,
                                      onTap: _toggleFullScreen,
                                    ),
                                    const SizedBox(height: 12),
                                    _mapControlBtn(
                                      icon: Icons.my_location,
                                      onTap: _resetLocation,
                                      color: _follow ? AppColors.voltCyan : null,
                                    ),
                                    const SizedBox(height: 12),
                                    _mapControlBtn(
                                      icon: Icons.layers,
                                      onTap: () => _showLayerPicker(context),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Theme Toggle (Inline Map)
                              Positioned(
                                top: 16,
                                left: 16,
                                child: _mapControlBtn(
                                  icon: mapModeIsDark ? Icons.light_mode : Icons.dark_mode,
                                  onTap: () {
                                    setState(() {
                                      _mapIsDark = !mapModeIsDark;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Pre-run Metrics and Settings
                    _buildPreRunUI(theme, isDark),
                  ],
                ),
              ),
            ),

          // ── 2. RUNNING VIEW (Full-Screen Map) ──
          if (isRunningPhase || _isFullScreenMap) ...[
            Positioned.fill(
              child: _buildMapWidget(mapUrl, isDark, true),
            ),
            
            // Map controls for full-screen mode (Top Right)
            if (!isRunningPhase && _isFullScreenMap)
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                right: 16,
                child: Column(
                  children: [
                    _mapControlBtn(
                      icon: Icons.fullscreen_exit,
                      onTap: _toggleFullScreen,
                    ),
                    const SizedBox(height: 12),
                    _mapControlBtn(
                      icon: Icons.my_location,
                      onTap: _resetLocation,
                      color: _follow ? AppColors.voltCyan : null,
                    ),
                    const SizedBox(height: 12),
                    _mapControlBtn(
                      icon: Icons.layers,
                      onTap: () => _showLayerPicker(context),
                    ),
                  ],
                ),
              ),

            // Top-Left Theme Toggle (Full Screen)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              child: _mapControlBtn(
                icon: mapModeIsDark ? Icons.light_mode : Icons.dark_mode,
                onTap: () {
                  setState(() {
                    _mapIsDark = !mapModeIsDark;
                  });
                },
              ),
            ),
          ],

          // ── MAP CONTROLS (during run) ──
          if (_state == RunState.running)
            Positioned(
              bottom: size.height * 0.4 + 80,
              right: 16,
              child: Column(
                children: [
                  _mapControlBtn(
                    icon: Icons.my_location,
                    onTap: _resetLocation,
                    color: _follow ? AppColors.voltCyan : null,
                  ),
                  const SizedBox(height: 12),
                  _mapControlBtn(
                    icon: Icons.layers,
                    onTap: () => _showLayerPicker(context),
                  ),
                ],
              ),
            ),

          // ── MAP WEATHER OVERLAY ──
          if (isRunningPhase && weather != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.black.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.voltCyan.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(weather.condition.toLowerCase().contains('rain') ? LucideIcons.cloudRain : LucideIcons.cloudSun, size: 16, color: AppColors.voltCyan),
                    const SizedBox(width: 8),
                    Text('${weather.currentTemp.round()}°C', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),

          // ── 3. ACTIVE RUN UI ──
          if (_state == RunState.running || _state == RunState.paused) ...[
            // Floating Pause/End Button
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              child: _buildFloatingPauseBtn(),
            ),

            // Mini Elevation Strip (Anchored above metric panel)
            Positioned(
              left: 16,
              right: 16,
              bottom: size.height * 0.4, // Right above the metric panel
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (weather != null)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _smallWeatherBadge(LucideIcons.wind, '${weather.windSpeed} km/h', isDark),
                        const SizedBox(width: 8),
                        _smallWeatherBadge(LucideIcons.sun, 'UV ${weather.uvIndex}', isDark),
                      ],
                    ),
                  const SizedBox(height: 8),
                  ElevationStripWidget(
                    data: const [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], // removed mock elevation
                    theme: theme,
                  ),
                ],
              ),
            ),

            // Metric Panel (Bottom 40%)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: size.height * 0.4,
              child: LiveRunMetricPanel(
                pace: _fmtPace(_paceMin),
                distance: _distKm.toStringAsFixed(2),
                bpm: _estimatedBpm,
                duration: _fmtDur(_durSecs),
              ),
            ),
            
            // Paused Overlay
            if (_state == RunState.paused)
              Positioned.fill(
                child: Container(
                  color: isDark ? Colors.black.withValues(alpha: 0.7) : Colors.white.withValues(alpha: 0.8),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('PAUSED', style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 4)),
                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _actionBtn(Icons.stop, 'FINISH', AppColors.pulseRed, _finishRun),
                            const SizedBox(width: 32),
                            _actionBtn(Icons.play_arrow, 'RESUME', AppColors.voltCyan, _resumeRun),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ),
          ],

          // ── 4. COUNTDOWN OVERLAY ──
          if (_state == RunState.countdown)
            Positioned.fill(
              child: Container(
                color: theme.scaffoldBackgroundColor.withValues(alpha: 0.85),
                child: Center(
                  child: TweenAnimationBuilder<double>(
                    key: ValueKey(_countdown),
                    tween: Tween(begin: 1.4, end: 1.0),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.elasticOut,
                    builder: (context, scale, child) {
                      return Transform.scale(
                        scale: scale,
                        child: Text(
                          _countdown.toString(),
                          style: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontSize: 120,
                            fontWeight: FontWeight.w900,
                            height: 1,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPreRunUI(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Route info pill row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _infoPill('Distance', '5.2 km', isDark),
              _infoPill('Est. Time', '28:40', isDark),
              _infoPill('Elevation', '42 m', isDark),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          // Category selector
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: kSportsCategories.keys.map((cat) {
                final isActive = _selectedSportCategory == cat;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _selectedSportCategory = cat;
                      _selectedRunType = kSportsCategories[cat]!.first.label;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.voltCyan.withValues(alpha: 0.2) : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isActive ? AppColors.voltCyan : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1)),
                    ),
                    child: Text(cat, style: TextStyle(color: isActive ? AppColors.voltCyan : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.7), fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          // Run type selector chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: kSportsCategories[_selectedSportCategory]!.map((sport) {
                return _typeChip(sport.label, sport.icon, isDark);
              }).toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Target pace / distance input row
          Row(
            children: [
              Expanded(child: _ghostInput(_targetLeftLabel, _targetLeftValue, isDark)),
              const SizedBox(width: 16),
              Expanded(child: _ghostInput(_targetRightLabel, _targetRightValue, isDark)),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          // Hourly Weather Carousel
          if (context.watch<WeatherProvider>().weather != null) ...[
            Text('Hourly Forecast', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: context.watch<WeatherProvider>().weather!.hourly.length,
                itemBuilder: (context, index) {
                  final h = context.watch<WeatherProvider>().weather!.hourly[index];
                  return Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(DateFormat('HH:mm').format(h.time), style: TextStyle(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.7), fontSize: 12)),
                        const SizedBox(height: 4),
                        Icon(h.condition.toLowerCase().contains('rain') ? LucideIcons.cloudRain : LucideIcons.sun, size: 20, color: AppColors.solarAmber),
                        const SizedBox(height: 4),
                        Text('${h.temp.round()}°', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],

          // Music / audio cue row
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: AppColors.irisViolet,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.music, size: 16, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Running Mix 2026', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                      Text('Audio Prompts', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
                    ],
                  ),
                ),
                Switch(
                  value: _audioPrompts,
                  onChanged: (v) => setState(() => _audioPrompts = v),
                  activeTrackColor: AppColors.pulseRed,
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),

          // START RUN button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _startCountdown,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.pulseRed,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.pillRadius)),
              ),
              child: const Text('START RUN', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
            ),
          ),
          const SizedBox(height: 32),
          
          // ── FITNESS SECTION INTEGRATION ──
          const Divider(height: 1, color: Colors.white10),
          const SizedBox(height: 16),
          const FitnessScreen(),
          
          const SizedBox(height: 100), // Padding for bottom nav
        ],
      ),
    );
  }

  void _showLayerPicker(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Map Layers', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Choose a map style', style: TextStyle(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.5), fontSize: 13)),
            const SizedBox(height: 20),
            SizedBox(
              height: 90,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _mapLayers.length,
                itemBuilder: (context, i) {
                  final isActive = _selectedMapLayer == i;
                  final layer = _mapLayers[i];
                  final icons = [Icons.map, Icons.volunteer_activism, Icons.pedal_bike, Icons.directions_bus, Icons.terrain];
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedMapLayer = i);
                      Navigator.pop(ctx);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 80,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: isActive ? AppColors.voltCyan.withValues(alpha: 0.15) : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isActive ? AppColors.voltCyan : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1), width: isActive ? 2 : 1),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(icons[i], color: isActive ? AppColors.voltCyan : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6), size: 28),
                          const SizedBox(height: 8),
                          Text(layer['name']!, style: TextStyle(color: isActive ? AppColors.voltCyan : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.7), fontSize: 11, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _mapControlBtn({required IconData icon, required VoidCallback onTap, Color? color}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1)),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2))
              ],
            ),
            child: Icon(icon, color: color ?? (isDark ? Colors.white : Colors.black), size: 24),
          ),
        ),
      ),
    );
  }

  Widget _infoPill(String label, String value, bool isDark) {
    final surfaceColor = isDark ? Colors.white : Colors.black;
    final textColor = isDark ? Colors.white : Colors.black;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: surfaceColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: surfaceColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(color: textColor, fontWeight: FontWeight.w700, fontSize: 14)),
          Text(label, style: TextStyle(color: textColor.withValues(alpha: 0.54), fontSize: 10)),
        ],
      ),
    );
  }

  Widget _typeChip(String label, IconData icon, bool isDark) {
    final isActive = _selectedRunType == label;
    final textColor = isDark ? Colors.white : Colors.black;
    final surfaceColor = isDark ? Colors.white : Colors.black;
    return GestureDetector(
      onTap: () => setState(() => _selectedRunType = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppColors.pulseRed : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? AppColors.pulseRed : surfaceColor.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isActive ? Colors.white : textColor.withValues(alpha: 0.7)),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: isActive ? Colors.white : textColor.withValues(alpha: 0.7), fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _ghostInput(String label, String value, bool isDark) {
    final textColor = isDark ? Colors.white : Colors.black;
    final surfaceColor = isDark ? Colors.white : Colors.black;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: surfaceColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: textColor.withValues(alpha: 0.54), fontSize: 11)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: textColor, fontWeight: FontWeight.w700, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _smallWeatherBadge(IconData icon, String value, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.black.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.voltCyan.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.voltCyan),
          const SizedBox(width: 4),
          Text(value, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildFloatingPauseBtn() {
    return GestureDetector(
      onLongPress: () {
        // Mock End Run
        _finishRun();
      },
      onTap: () {
        if (_state == RunState.running) _pauseRun();
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Icon(
              _state == RunState.running ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 16, spreadRadius: 4),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 36),
          ),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
        ],
      ),
    );
  }

  void _showSummary() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final summaryLayer = _mapLayers[_selectedMapLayer];
    final mapUrl = isDark ? summaryLayer['dark']! : summaryLayer['light']!;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(child: Text('POST-RUN SUMMARY', style: TextStyle(color: AppColors.pulseRed, fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 14))),
            const SizedBox(height: 24),
            // Replay Map
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1)),
              clipBehavior: Clip.antiAlias,
              child: IgnorePointer(
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: _gpsRoute.isNotEmpty ? _gpsRoute.last : const LatLng(20.5937, 78.9629),
                    initialZoom: 15,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: mapUrl,
                      userAgentPackageName: 'com.example.lifepulse',
                    ),
                    if (_gpsRoute.isNotEmpty)
                      PolylineLayer(polylines: [
                        Polyline(points: _gpsRoute, strokeWidth: 4, color: AppColors.voltCyan),
                      ]),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Stats Grid
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.5,
                children: [
                  _statCard('Distance', '${_distKm.toStringAsFixed(2)} km', AppColors.voltCyan, isDark),
                  _statCard('Duration', _fmtDur(_durSecs), isDark ? Colors.white : Colors.black, isDark),
                  _statCard('Avg Pace', '${_fmtPace(_paceMin)} /km', AppColors.solarAmber, isDark),
                  _statCard('Calories', '$_calories', AppColors.pulseRed, isDark),
                ],
              ),
            ),
            // CTAs
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: AppColors.voltCyan),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('SHARE', style: TextStyle(color: AppColors.voltCyan, fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _resetRun();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.pulseRed,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('SAVE RUN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _resetRun();
                },
                child: const Text('Discard Run', style: TextStyle(color: Colors.white38, decoration: TextDecoration.underline)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, Color color, bool isDark) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: TextStyle(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.54), fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }


}
