import 'dart:async';
import 'dart:math';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geocoding/geocoding.dart';
import '../services/geocoding_service.dart';
import '../services/route_service.dart';
import '../services/exceptions.dart';
import '../models/geocoding_result.dart';
import '../models/route_result.dart';
import '../models/route_option.dart';

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import 'package:lucide_icons_flutter/lucide_icons.dart';
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
import '../services/challenge_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/notification_service.dart';

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
  String? _routeError;
  bool _isRetryableError = false;
  List<List<LatLng>> _alternativeRoutes = [];
  int _selectedRouteIndex = 0;

  final GeocodingService _geocodingService = GeocodingService();
  final RouteService _routeService = RouteService();

  String _selectedRunType = 'Outdoor Run';
  String _selectedSportCategory = 'Cardio';
  RoutePreference _routePreference = RoutePreference.fastest;
  int _fastestRouteIndex = 0;
  int _shortestRouteIndex = 0;
  int _routeReadinessScore = 0;
  String _routeAdvice = '';
  double _routeDistance = 0.0;
  double _routeElevation = 0.0;
  int _routeDuration = 0;
  bool _audioPrompts = true;
  bool _isFullScreenMap = false;

  // Custom target variables (editable)
  double _customTargetPaceMin = 5.5; // default 5:30 /km
  double _customTargetDistanceKm = 5.0;
  int _customTargetDurationMin = 30;
  int _customTargetCalories = 350;

  double _mapRotation = 0.0;
  double _heading = 0.0;
  bool _isDrawerCollapsed = false;
  String _selectedMusicPlaylist = 'LifePulse Cardio Boost';


  // Pre-run target inputs
  String _targetLeftLabel = 'Target Pace';
  String _targetLeftValue = '5:30 /km';
  String _targetRightLabel = 'Distance';
  String _targetRightValue = '5.0 km';

  // Map layer selection
  int _selectedMapLayer = 0;
  bool? _mapIsDark;
  RouteResult? _lastRouteResult; // Store full result for alternative selection
  final List<Map<String, String>> _mapLayers = [
    {'name': 'Standard', 'dark': 'https://a.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}@2x.png', 'light': 'https://a.basemaps.cartocdn.com/light_all/{z}/{x}/{y}@2x.png'},
    {'name': 'Streets', 'dark': 'https://a.basemaps.cartocdn.com/dark_nolabels/{z}/{x}/{y}@2x.png', 'light': 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'},
    {'name': 'Voyager', 'dark': 'https://a.basemaps.cartocdn.com/rastertiles/dark_all/{z}/{x}/{y}@2x.png', 'light': 'https://a.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}@2x.png'},
    {'name': 'Topo', 'dark': 'https://a.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}@2x.png', 'light': 'https://tile.opentopomap.org/{z}/{x}/{y}.png'},
  ];

  final GlobalKey _mapKey = GlobalKey();

  Future<void> _findRoute() async {
    if (_startLocCtrl.text.isEmpty || _destLocCtrl.text.isEmpty) return;

    setState(() {
      _isLoadingRoute = true;
      _routeError = null;
      _alternativeRoutes.clear();
      _mockPreRunRoute.clear();
      _startRoutePos = null;
      _endRoutePos = null;
      _routeDistance = 0.0;
      _routeDuration = 0;
      _routeReadinessScore = 0;
    });

    try {
      final startRes = await _geocodingService.geocode(_startLocCtrl.text);
      await Future.delayed(const Duration(milliseconds: 1100)); // Respect Nominatim limits
      final destRes = await _geocodingService.geocode(_destLocCtrl.text);

      setState(() {
        _startRoutePos = startRes.coordinates;
        _endRoutePos = destRes.coordinates;
      });

      debugPrint('Geocoded Start: ${startRes.coordinates.latitude}, ${startRes.coordinates.longitude}');
      debugPrint('Geocoded Destination: ${destRes.coordinates.latitude}, ${destRes.coordinates.longitude}');

      // Initially center between the two points while waiting for route
      final center = LatLng(
        (startRes.coordinates.latitude + destRes.coordinates.latitude) / 2,
        (startRes.coordinates.longitude + destRes.coordinates.longitude) / 2,
      );
      _mapCtrl.move(center, 12);

      final routeRes = await _routeService.getRoute(startRes.coordinates, destRes.coordinates);

      if (routeRes.alternatives.isNotEmpty) {
        // Classify alternatives: find fastest (lowest duration) and shortest (lowest distance)
        int fastestIdx = 0;
        int shortestIdx = 0;
        for (int i = 1; i < routeRes.alternatives.length; i++) {
          if (routeRes.durations[i] < routeRes.durations[fastestIdx]) fastestIdx = i;
          if (routeRes.distances[i] < routeRes.distances[shortestIdx]) shortestIdx = i;
        }

        // Pick the route based on user's selected preference
        int selectedIdx = 0;
        if (_routePreference == RoutePreference.shortest) {
          selectedIdx = shortestIdx;
        } else {
          selectedIdx = fastestIdx;
        }

        setState(() {
          _lastRouteResult = routeRes;
          _alternativeRoutes = routeRes.alternatives;
          _fastestRouteIndex = fastestIdx;
          _shortestRouteIndex = shortestIdx;
          _selectedRouteIndex = selectedIdx;
          _mockPreRunRoute = routeRes.alternatives[selectedIdx];

          _routeDistance = routeRes.distances[selectedIdx];
          _routeDuration = routeRes.durations[selectedIdx].round();
          _routeElevation = 0; // OSRM doesn't provide elevation

          _updateTargetUI();
        });
        _calculateReadiness();
        _fitMapToRoute();
        debugPrint('Route plotted. Fastest idx=$fastestIdx, Shortest idx=$shortestIdx, Selected=$selectedIdx, Alternatives: ${_alternativeRoutes.length}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (e is GeocodingException) {
            _routeError = e.userMessage;
            _isRetryableError = e.retryable;
          } else if (e is RouteException) {
            _routeError = e.userMessage;
            _isRetryableError = e.retryable;
          } else {
            _routeError = 'An unexpected error occurred. Please try again.';
            _isRetryableError = true;
          }
        });
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

  void _swapLocations() {
    setState(() {
      final tempText = _startLocCtrl.text;
      _startLocCtrl.text = _destLocCtrl.text;
      _destLocCtrl.text = tempText;

      if (_startRoutePos != null || _endRoutePos != null) {
        final tempPos = _startRoutePos;
        _startRoutePos = _endRoutePos;
        _endRoutePos = tempPos;
        
        // Clear route since start/end swapped
        _mockPreRunRoute.clear();
        _alternativeRoutes.clear();
        _routeDistance = 0.0;
        _routeDuration = 0;
        _routeReadinessScore = 0;
      }
    });

    if (_startLocCtrl.text.isNotEmpty && _destLocCtrl.text.isNotEmpty) {
      _findRoute();
    }
  }

  void _calculateReadiness() {
    int score = 100;
    String advice = "Great conditions for a run!";

    if (_routeDistance > 20) {
      score -= 20;
      advice = "Long route: hydrate and pace yourself.";
    } else if (_routeDistance > 10) {
      score -= 10;
      advice = "Moderate distance: keep a steady pace.";
    } else if (_routeDistance < 3) {
      advice = "Good route for a short quick run.";
    }

    if (mounted) {
      final weatherProvider = context.read<WeatherProvider>();
      final weather = weatherProvider.weather;
      if (weather != null) {
        if (weather.currentTemp > 30) {
          score -= 25;
          advice = "Hot weather: carry water and avoid direct sun.";
        } else if (weather.currentTemp < 5) {
          score -= 15;
          advice = "Cold weather: dress in layers.";
        } else if (weather.condition.toLowerCase().contains('rain')) {
          score -= 20;
          advice = "Rainy conditions: watch your step.";
        }
      }
    }
    
    final hour = DateTime.now().hour;
    if (hour > 19 || hour < 5) {
      advice = "Night run: wear reflective gear and stick to lit paths.";
    }

    setState(() {
      _routeReadinessScore = score.clamp(0, 100);
      _routeAdvice = advice;
    });
  }

  void _fitMapToRoute() {
    if (_mockPreRunRoute.length < 2) return;
    try {
      final bounds = LatLngBounds.fromPoints(_mockPreRunRoute);
      _mapCtrl.fitCamera(CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(60.0),
      ));
    } catch (e) {
      debugPrint('Failed to fit camera to route bounds: $e');
    }
  }

  void _selectAlternativeRoute(int index) {
    if (index < 0 || index >= _alternativeRoutes.length) return;
    final result = _lastRouteResult;
    setState(() {
      _selectedRouteIndex = index;
      _mockPreRunRoute = _alternativeRoutes[index];
      if (result != null && index < result.distances.length) {
        _routeDistance = result.distances[index];
        _routeDuration = result.durations[index].round();
      }
      _updateTargetUI();
    });
    _calculateReadiness();
    _fitMapToRoute();
  }

  void _onRoutePreferenceSelected(RouteOption option) {
    if (!option.isSupported) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(option.disabledMessage),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    setState(() => _routePreference = option.preference);

    // If we have routes loaded, switch to the right one
    if (_lastRouteResult != null && _alternativeRoutes.isNotEmpty) {
      if (option.preference == RoutePreference.shortest) {
        _selectAlternativeRoute(_shortestRouteIndex);
      } else {
        _selectAlternativeRoute(_fastestRouteIndex);
      }
    }
  }

  Future<void> _fillCurrentLocation() async {
    if (_curPos != null) {
      try {
        final placemarks = await placemarkFromCoordinates(_curPos!.latitude, _curPos!.longitude);
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final name = [p.locality, p.administrativeArea, p.country]
              .where((s) => s != null && s.isNotEmpty)
              .join(', ');
          setState(() {
            _startLocCtrl.text = name.isNotEmpty ? name : '${_curPos!.latitude.toStringAsFixed(4)}, ${_curPos!.longitude.toStringAsFixed(4)}';
            _startRoutePos = _curPos;
          });
        }
      } catch (_) {
        setState(() {
          _startLocCtrl.text = '${_curPos!.latitude.toStringAsFixed(4)}, ${_curPos!.longitude.toStringAsFixed(4)}';
          _startRoutePos = _curPos;
        });
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location not available yet. Make sure GPS is enabled.')),
        );
      }
    }
  }

  void _resetLocation() {
    if (_curPos != null) {
      _mapCtrl.move(_curPos!, 16);
      setState(() => _follow = true);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Locating you... Ensure GPS is enabled.')),
        );
      }
      _initLocation();
    }
  }

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.15).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _updateTargetUI();
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
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('Location services are disabled.');
      return;
    }

    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied) {
        debugPrint('Location permission denied.');
        return;
      }
    }
    if (perm == LocationPermission.deniedForever) {
      debugPrint('Location permission permanently denied.');
      return;
    }

    try {
      final p = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.bestForNavigation));
      if (mounted) {
        setState(() => _curPos = LatLng(p.latitude, p.longitude));
        _mapCtrl.move(_curPos!, _zoom);
      }
    } catch (e) {
      debugPrint('Error getting initial location: $e');
    }

    // Use platform-specific settings for continuous updates
    late LocationSettings locSettings;
    if (Platform.isAndroid) {
      locSettings = AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 3, // At least 3 meters
        intervalDuration: const Duration(seconds: 1),
        forceLocationManager: false,
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'LifePulse Running',
          notificationText: 'Tracking your run',
          enableWakeLock: true,
        ),
      );
    } else if (Platform.isIOS) {
      locSettings = AppleSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 3,
        activityType: ActivityType.fitness,
        pauseLocationUpdatesAutomatically: false,
        allowBackgroundLocationUpdates: true,
        showBackgroundLocationIndicator: true,
      );
    } else {
      locSettings = const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 3,
      );
    }

    _posSub = Geolocator.getPositionStream(
      locationSettings: locSettings,
    ).listen(_onPos);
  }

  void _onPos(Position p) {
    if (!mounted) return;
    
    // Ignore highly inaccurate points
    if (p.accuracy > 30) return;

    final pt = LatLng(p.latitude, p.longitude);
    final speedKmh = p.speed * 3.6; // m/s to km/h
    
    setState(() {
      _curPos = pt;
      _lastSpeed = speedKmh;
      _heading = p.heading;
    });
    
    if (_follow && _curPos != null) {
      _mapCtrl.move(_curPos!, _zoom);
    }

    if (_state == RunState.running) {
      // Accumulate route points and distance
      if (_gpsRoute.isEmpty) {
        _gpsRoute.add(pt);
      } else {
        final lastPt = _gpsRoute.last;
        final distFromLast = const Distance().as(LengthUnit.Meter, lastPt, pt);
        
        // Filter out tiny jitters (<2m) and impossible jumps (>100m in a second)
        if (distFromLast >= 2 && distFromLast < 100) {
          setState(() {
            _gpsRoute.add(pt);
            _distKm += (distFromLast / 1000.0);
            _calories = (_distKm * 65).round();
            _estimatedBpm = _estimateHeartRate(_lastSpeed);
          });
        }
      }
    }
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
      if (!mounted) return;
      setState(() {
        _durSecs = _elapsed().inSeconds;
        // Calculate average pace from accumulated distance and time
        if (_distKm > 0.005 && _durSecs > 0) {
          _paceMin = (_durSecs / 60.0) / _distKm;
        } else {
          _paceMin = 0;
        }
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
    // I1: Update Distance challenge progress after run
    if (_distKm > 0) {
      ChallengeService().updateDistanceChallengesAfterRun(_distKm);
    }
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

  Widget _buildMapWidget(String mapUrl, bool isDark, bool showPreRunRoute) {
    final isActiveRun = _state == RunState.running || _state == RunState.paused;
    return FlutterMap(
      key: _mapKey,
      mapController: _mapCtrl,
      options: MapOptions(
        initialCenter: _curPos ?? const LatLng(20.5937, 78.9629),
        initialZoom: _zoom,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
        onPositionChanged: (pos, gesture) {
          if (gesture && _follow) setState(() => _follow = false);
          _zoom = pos.zoom ?? _zoom;
          final rot = _mapCtrl.camera.rotation;
          if (rot != _mapRotation) {
            setState(() {
              _mapRotation = rot;
            });
          }
        },
      ),
      children: [
        TileLayer(
          urlTemplate: mapUrl, 
          userAgentPackageName: 'com.sudeep.lifepulse',
          maxZoom: 19,
        ),

        // Alternative routes (dimmed gray)
        if (showPreRunRoute && _alternativeRoutes.length > 1)
          PolylineLayer(polylines: [
            for (int i = 0; i < _alternativeRoutes.length; i++)
              if (i != _selectedRouteIndex)
                Polyline(
                  points: _alternativeRoutes[i],
                  strokeWidth: 3,
                  color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.15),
                ),
          ]),
        
        // Pre-run Route (Cyan Glow)
        if (showPreRunRoute && _mockPreRunRoute.isNotEmpty)
          PolylineLayer(polylines: [
            Polyline(
              points: _mockPreRunRoute,
              strokeWidth: 9,
              color: AppColors.voltCyan.withValues(alpha: 0.25),
            ),
            Polyline(
              points: _mockPreRunRoute,
              strokeWidth: 4,
              color: AppColors.voltCyan,
              borderStrokeWidth: 1.5,
              borderColor: Colors.white.withValues(alpha: 0.8),
            ),
          ]),

        // Active Live Route (Cyan Glow)
        if (_gpsRoute.length >= 2)
          PolylineLayer(polylines: [
            Polyline(
              points: List.from(_gpsRoute),
              strokeWidth: 10,
              color: AppColors.voltCyan.withValues(alpha: 0.25),
            ),
            Polyline(
              points: List.from(_gpsRoute),
              strokeWidth: 5,
              color: AppColors.voltCyan,
              borderStrokeWidth: 2,
              borderColor: Colors.white.withValues(alpha: 0.9),
            )
          ]),

        // Markers
        MarkerLayer(markers: [
          if (_startRoutePos != null && showPreRunRoute)
            Marker(
              point: _startRoutePos!,
              width: 44,
              height: 44,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.green.shade600,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                  boxShadow: [
                    BoxShadow(color: Colors.green.withValues(alpha: 0.5), blurRadius: 10, spreadRadius: 2)
                  ],
                ),
                child: const Icon(Icons.play_arrow, color: Colors.white, size: 22),
              ),
            ),
          if (_endRoutePos != null && showPreRunRoute)
            Marker(
              point: _endRoutePos!,
              width: 44,
              height: 44,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.pulseRed,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                  boxShadow: [
                    BoxShadow(color: AppColors.pulseRed.withValues(alpha: 0.5), blurRadius: 10, spreadRadius: 2)
                  ],
                ),
                child: const Icon(LucideIcons.flag, color: Colors.white, size: 18),
              ),
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
                    if (_lastSpeed > 1 && _heading != 0)
                      Transform.rotate(
                        angle: _heading * pi / 180,
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: Colors.black26, blurRadius: 2)
                              ],
                            ),
                          ),
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

  Widget _routeInput({
    required TextEditingController ctrl,
    required String hint,
    required IconData icon,
    required Color iconColor,
    required bool isDark,
    required bool isTop,
  }) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(isTop ? 12 : 4),
          topRight: Radius.circular(isTop ? 12 : 4),
          bottomLeft: Radius.circular(isTop ? 4 : 12),
          bottomRight: Radius.circular(isTop ? 4 : 12),
        ),
      ),
      child: TextField(
        controller: ctrl,
        maxLines: 1,
        style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 13),
        onChanged: (v) => setState(() {}),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(fontSize: 13, color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.5)),
          prefixIcon: Icon(icon, color: iconColor, size: 16),
          suffixIcon: ctrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 16),
                  onPressed: () => setState(() {
                    ctrl.clear();
                    if (isTop) _startRoutePos = null;
                    else _endRoutePos = null;
                  }),
                )
              : (isTop ? IconButton(
                  icon: const Icon(Icons.my_location, size: 16),
                  onPressed: _fillCurrentLocation,
                ) : null),
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildRoutePlannerUI(bool isDark) {
    bool canSearch = _startLocCtrl.text.isNotEmpty && _destLocCtrl.text.isNotEmpty;
    String statusText = "No route selected";
    if (_isLoadingRoute) statusText = "Finding route...";
    else if (_alternativeRoutes.isNotEmpty) statusText = "Route ready";
    else if (_routeError != null) statusText = "Route unavailable";

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
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
              const Spacer(),
              Text(statusText, style: TextStyle(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.5), fontSize: 11)),
            ],
          ),
          const SizedBox(height: 12),
          Stack(
            alignment: Alignment.centerRight,
            children: [
              Column(
                children: [
                  _routeInput(
                    ctrl: _startLocCtrl,
                    hint: 'Start location',
                    icon: LucideIcons.mapPin,
                    iconColor: AppColors.voltCyan,
                    isDark: isDark,
                    isTop: true,
                  ),
                  const SizedBox(height: 2),
                  _routeInput(
                    ctrl: _destLocCtrl,
                    hint: 'Destination',
                    icon: LucideIcons.flag,
                    iconColor: AppColors.pulseRed,
                    isDark: isDark,
                    isTop: false,
                  ),
                ],
              ),
              Positioned(
                right: 16,
                child: GestureDetector(
                  onTap: _swapLocations,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4),
                      ],
                      border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1)),
                    ),
                    child: Icon(Icons.swap_vert, size: 18, color: isDark ? Colors.white : Colors.black),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Route preference chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: kRouteOptions.map((option) {
                final isActive = _routePreference == option.preference;
                final isSupported = option.isSupported;
                final textColor = isDark ? Colors.white : Colors.black;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => _onRoutePreferenceSelected(option),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.voltCyan.withValues(alpha: 0.2)
                            : textColor.withValues(alpha: isSupported ? 0.05 : 0.03),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isActive
                              ? AppColors.voltCyan
                              : textColor.withValues(alpha: isSupported ? 0.1 : 0.06),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            option.icon,
                            size: 14,
                            color: isActive
                                ? AppColors.voltCyan
                                : textColor.withValues(alpha: isSupported ? 0.7 : 0.3),
                          ),
                          const SizedBox(width: 6),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                option.label,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                                  color: isActive
                                      ? AppColors.voltCyan
                                      : textColor.withValues(alpha: isSupported ? 1.0 : 0.4),
                                ),
                              ),
                              if (!isSupported)
                                Text(
                                  'Soon',
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.solarAmber.withValues(alpha: 0.7),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          // Alternative route comparison (if multiple real routes exist)
          if (_alternativeRoutes.length > 1 && _lastRouteResult != null) ...[
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _routeComparisonChip(
                    'Fastest',
                    _lastRouteResult!.distances[_fastestRouteIndex],
                    _lastRouteResult!.durations[_fastestRouteIndex],
                    _routePreference == RoutePreference.fastest,
                    isDark,
                    () => _onRoutePreferenceSelected(kRouteOptions[0]),
                  ),
                  const SizedBox(width: 8),
                  _routeComparisonChip(
                    'Shortest',
                    _lastRouteResult!.distances[_shortestRouteIndex],
                    _lastRouteResult!.durations[_shortestRouteIndex],
                    _routePreference == RoutePreference.shortest,
                    isDark,
                    () => _onRoutePreferenceSelected(kRouteOptions[1]),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (_routeError != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.pulseRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.pulseRed.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppColors.pulseRed, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_routeError!, style: const TextStyle(color: AppColors.pulseRed, fontSize: 12)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: canSearch && !_isLoadingRoute ? _findRoute : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _routeError != null && _isRetryableError ? AppColors.solarAmber : AppColors.voltCyan,
                foregroundColor: Colors.black,
                disabledBackgroundColor: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
                disabledForegroundColor: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.3),
                elevation: 0,
                padding: EdgeInsets.zero,
                alignment: Alignment.center,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoadingRoute
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5))
                  : Text(_alternativeRoutes.isNotEmpty ? 'Route Ready' : (_routeError != null && _isRetryableError ? 'Try Again' : 'Find Routes'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ),
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
                              _buildMapWidget(mapUrl, isDark, true),
                              
                              // Pre-run Map Controls (overlaying the inline map card)
                              Positioned(
                                top: 16,
                                right: 16,
                                child: _buildRightMapControls(
                                  isFullScreen: false,
                                  isRunning: false,
                                  isDark: isDark,
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
              child: _buildMapWidget(mapUrl, isDark, !isRunningPhase && _isFullScreenMap),
            ),
            
            // Map controls for full-screen mode (Top Right)
            if (!isRunningPhase && _isFullScreenMap)
              Positioned(
                top: MediaQuery.of(context).padding.top > 20 ? MediaQuery.of(context).padding.top + 16 : 40,
                right: 16,
                child: _buildRightMapControls(
                  isFullScreen: true,
                  isRunning: false,
                  isDark: isDark,
                ),
              ),

            // Top-Left Theme Toggle (Full Screen)
            if (!isRunningPhase && _isFullScreenMap)
              Positioned(
                top: MediaQuery.of(context).padding.top > 20 ? MediaQuery.of(context).padding.top + 16 : 40,
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

            // Floating drawer in fullscreen planning mode
            if (!isRunningPhase && _isFullScreenMap)
              Positioned(
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).padding.bottom > 20
                    ? MediaQuery.of(context).padding.bottom + 16
                    : 24,
                child: _buildFullscreenDrawer(isDark, theme),
              ),
          ],

          // ── MAP WEATHER OVERLAY & THEME TOGGLE (DURING RUN) ──
          if (isRunningPhase)
            Positioned(
              top: MediaQuery.of(context).padding.top > 20 ? MediaQuery.of(context).padding.top + 16 : 40,
              left: 16,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (weather != null) ...[
                    Container(
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
                    const SizedBox(width: 12),
                  ],
                  _mapControlBtn(
                    icon: mapModeIsDark ? Icons.light_mode : Icons.dark_mode,
                    onTap: () {
                      setState(() {
                        _mapIsDark = !mapModeIsDark;
                      });
                    },
                  ),
                ],
              ),
            ),

          // ── 3. ACTIVE RUN UI ──
          if (_state == RunState.running || _state == RunState.paused) ...[
            // Floating Pause/End Button
            Positioned(
              top: MediaQuery.of(context).padding.top > 20 ? MediaQuery.of(context).padding.top + 16 : 40,
              right: 16,
              child: _buildFloatingPauseBtn(),
            ),

            // MAP CONTROLS (during run) - Placed on the RIGHT side above the elevation strip
            if (_state == RunState.running)
              Positioned(
                bottom: size.height * 0.4 + 60, // 60px above the metric panel (above elevation strip)
                right: 16,
                child: _buildRightMapControls(
                  isFullScreen: true,
                  isRunning: true,
                  isDark: isDark,
                ),
              ),

            // Wind & UV Chips - Placed on the LEFT side above the elevation strip
            if (weather != null && _state == RunState.running)
              Positioned(
                bottom: size.height * 0.4 + 60, // 60px above the metric panel (above elevation strip)
                left: 16,
                child: Row(
                  children: [
                    _smallWeatherBadge(LucideIcons.wind, '${weather.windSpeed} km/h', isDark),
                    const SizedBox(width: 8),
                    _smallWeatherBadge(LucideIcons.sun, 'UV ${weather.uvIndex}', isDark),
                  ],
                ),
              ),

            // Mini Elevation Strip (Anchored directly at the top of metric panel)
            Positioned(
              left: 16,
              right: 16,
              bottom: size.height * 0.4,
              child: ElevationStripWidget(
                data: const [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], // removed mock elevation
                theme: theme,
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
          // Route Summary & Readiness
          if (_mockPreRunRoute.isNotEmpty)
            _buildRouteSummaryCard(isDark)
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.voltCyan.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.voltCyan.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(LucideIcons.info, color: AppColors.voltCyan),
                  SizedBox(width: 12),
                  Expanded(child: Text("Find a route to calculate readiness", style: TextStyle(color: AppColors.voltCyan, fontWeight: FontWeight.w600))),
                ],
              ),
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
                      color: isActive ? AppColors.voltCyan.withValues(alpha: 0.15) : (isDark ? Colors.white10 : Colors.black12).withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isActive ? AppColors.voltCyan : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
                        width: isActive ? 1.5 : 1,
                      ),
                      boxShadow: isActive ? [
                        BoxShadow(
                          color: AppColors.voltCyan.withValues(alpha: 0.25),
                          blurRadius: 6,
                          spreadRadius: 1,
                        )
                      ] : null,
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
              Expanded(
                child: GestureDetector(
                  onTap: () => _onTargetCardTapped(_targetLeftLabel),
                  child: _ghostInput(_targetLeftLabel, _targetLeftValue, isDark),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GestureDetector(
                  onTap: () => _onTargetCardTapped(_targetRightLabel),
                  child: _ghostInput(_targetRightLabel, _targetRightValue, isDark),
                ),
              ),
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
                  final isRainy = h.condition.toLowerCase().contains('rain');
                  final cardGradient = LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isRainy
                        ? [
                            Colors.blueGrey.withValues(alpha: 0.15),
                            Colors.blueGrey.withValues(alpha: 0.03),
                          ]
                        : [
                            Colors.orange.withValues(alpha: 0.12),
                            Colors.orange.withValues(alpha: 0.02),
                          ],
                  );
                  final borderColor = isRainy
                      ? Colors.blueGrey.withValues(alpha: 0.25)
                      : Colors.orange.withValues(alpha: 0.2);

                  return Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: cardGradient,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(DateFormat('HH:mm').format(h.time), style: TextStyle(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.7), fontSize: 11)),
                        const SizedBox(height: 6),
                        Icon(isRainy ? LucideIcons.cloudRain : LucideIcons.sun, size: 20, color: isRainy ? AppColors.voltCyan : AppColors.solarAmber),
                        const SizedBox(height: 6),
                        Text('${h.temp.round()}°', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 13)),
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
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _showMusicSelector,
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
                              Text(_selectedMusicPlaylist, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                              Text('Audio Prompts', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
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
              child: Text(_mockPreRunRoute.isNotEmpty ? 'START PLANNED RUN' : 'START FREE RUN', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text("Safety check: share route with family/friends before starting.", style: TextStyle(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.4), fontSize: 11)),
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

  Widget _buildRouteSummaryCard(bool isDark) {
    Color scoreColor = AppColors.pulseRed;
    if (_routeReadinessScore >= 80) scoreColor = Colors.green;
    else if (_routeReadinessScore >= 50) scoreColor = AppColors.solarAmber;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Route Readiness', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: scoreColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('$_routeReadinessScore/100', style: TextStyle(color: scoreColor, fontWeight: FontWeight.w900, fontSize: 14)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(_routeAdvice, style: TextStyle(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.7), fontSize: 13)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _infoPill('Distance', '${_routeDistance.toStringAsFixed(1)} km', isDark),
              _infoPill('Est. Time', '$_routeDuration min', isDark),
              _infoPill('Elevation', _routeElevation > 0 ? '${_routeElevation.toStringAsFixed(0)} m' : '-- m', isDark),
            ],
          ),
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
                  final icons = [Icons.map, Icons.terrain, Icons.explore, Icons.layers];
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

  Widget _mapControlBtn({required IconData icon, required VoidCallback onTap, Color? color, Widget? iconWidget}) {
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
              border: Border.all(color: (isDark ? AppColors.voltCyan.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.15))),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2))
              ],
            ),
            child: Center(
              child: iconWidget ?? Icon(icon, color: color ?? (isDark ? Colors.white : Colors.black), size: 24),
            ),
          ),
        ),
      ),
    );
  }

  String _formatPaceFromDouble(double paceMinutes) {
    final minutes = paceMinutes.floor();
    final seconds = ((paceMinutes - minutes) * 60).round();
    return '$minutes:${seconds.toString().padLeft(2, '0')} /km';
  }

  void _updateTargetUI() {
    if (_mockPreRunRoute.isNotEmpty) {
      _targetRightLabel = 'Distance';
      _targetRightValue = '${_routeDistance.toStringAsFixed(2)} km';
      final estTimeMin = (_routeDistance * _customTargetPaceMin).round();
      _targetLeftLabel = 'Est. Time';
      _targetLeftValue = '$estTimeMin min';
    } else {
      _targetLeftLabel = 'Target Pace';
      _targetLeftValue = _formatPaceFromDouble(_customTargetPaceMin);
      _targetRightLabel = 'Distance';
      _targetRightValue = '${_customTargetDistanceKm.toStringAsFixed(1)} km';
    }
  }

  void _onTargetCardTapped(String label) {
    final cleanLabel = label.toLowerCase();
    if (cleanLabel.contains('pace') || cleanLabel.contains('est. time')) {
      _showPaceTargetPicker();
    } else if (cleanLabel.contains('distance')) {
      _showDistanceTargetPicker();
    } else if (cleanLabel.contains('duration')) {
      _showDurationTargetPicker();
    } else if (cleanLabel.contains('burn') || cleanLabel.contains('kcal')) {
      _showCaloriesTargetPicker();
    }
  }

  Widget _buildPickerHeader({
    required String title,
    required bool isDark,
    required VoidCallback onCancel,
    required VoidCallback onDone,
  }) {
    final textColor = isDark ? Colors.white : Colors.black;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: textColor.withValues(alpha: 0.1), width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: onCancel,
            child: Text('Cancel', style: TextStyle(color: textColor.withValues(alpha: 0.5), fontSize: 14)),
          ),
          Text(title, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
          TextButton(
            onPressed: onDone,
            child: const Text('Done', style: TextStyle(color: AppColors.voltCyan, fontWeight: FontWeight.bold, fontSize: 14)),
          ),
        ],
      ),
    );
  }

  void _showPaceTargetPicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    int selectedMin = _customTargetPaceMin.floor().clamp(3, 12);
    int selectedSec = (((_customTargetPaceMin - selectedMin) * 60) / 5).round().clamp(0, 11) * 5;
    
    final minScrollCtrl = FixedExtentScrollController(initialItem: selectedMin - 3);
    final secScrollCtrl = FixedExtentScrollController(initialItem: selectedSec ~/ 5);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              height: 320,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1)),
              ),
              child: Column(
                children: [
                  _buildPickerHeader(
                    title: 'Set Target Pace',
                    isDark: isDark,
                    onCancel: () => Navigator.pop(ctx),
                    onDone: () {
                      setState(() {
                        _customTargetPaceMin = minScrollCtrl.selectedItem + 3 + (secScrollCtrl.selectedItem * 5) / 60.0;
                        _updateTargetUI();
                      });
                      Navigator.pop(ctx);
                    },
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 80,
                          child: ListWheelScrollView.useDelegate(
                            controller: minScrollCtrl,
                            itemExtent: 44,
                            physics: const FixedExtentScrollPhysics(),
                            perspective: 0.005,
                            onSelectedItemChanged: (idx) {
                              setSheetState(() {
                                selectedMin = idx + 3;
                              });
                            },
                            childDelegate: ListWheelChildBuilderDelegate(
                              builder: (context, index) {
                                final val = index + 3;
                                if (val < 3 || val > 12) return null;
                                final isSelected = val == selectedMin;
                                return Center(
                                  child: Text(
                                    '$val',
                                    style: TextStyle(
                                      color: isSelected ? AppColors.voltCyan : (isDark ? Colors.white60 : Colors.black54),
                                      fontSize: 22,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                );
                              },
                              childCount: 10,
                            ),
                          ),
                        ),
                        Text(':', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 22, fontWeight: FontWeight.bold)),
                        SizedBox(
                          width: 80,
                          child: ListWheelScrollView.useDelegate(
                            controller: secScrollCtrl,
                            itemExtent: 44,
                            physics: const FixedExtentScrollPhysics(),
                            perspective: 0.005,
                            onSelectedItemChanged: (idx) {
                              setSheetState(() {
                                selectedSec = idx * 5;
                              });
                            },
                            childDelegate: ListWheelChildBuilderDelegate(
                              builder: (context, index) {
                                final val = index * 5;
                                if (val < 0 || val > 55) return null;
                                final isSelected = val == selectedSec;
                                return Center(
                                  child: Text(
                                    val.toString().padLeft(2, '0'),
                                    style: TextStyle(
                                      color: isSelected ? AppColors.voltCyan : (isDark ? Colors.white60 : Colors.black54),
                                      fontSize: 22,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                );
                              },
                              childCount: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('/km', style: TextStyle(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.5), fontSize: 16)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
        );
      },
    );
  }

  void _showDistanceTargetPicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final List<double> distances = List.generate(59, (i) => 1.0 + i * 0.5);
    int selectedIdx = distances.indexOf(_customTargetDistanceKm);
    if (selectedIdx == -1) selectedIdx = 8;
    
    final scrollCtrl = FixedExtentScrollController(initialItem: selectedIdx);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              height: 320,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1)),
              ),
              child: Column(
                children: [
                  _buildPickerHeader(
                    title: 'Set Target Distance',
                    isDark: isDark,
                    onCancel: () => Navigator.pop(ctx),
                    onDone: () {
                      setState(() {
                        _customTargetDistanceKm = distances[scrollCtrl.selectedItem];
                        _updateTargetUI();
                      });
                      Navigator.pop(ctx);
                    },
                  ),
                  Expanded(
                    child: ListWheelScrollView.useDelegate(
                      controller: scrollCtrl,
                      itemExtent: 44,
                      physics: const FixedExtentScrollPhysics(),
                      perspective: 0.005,
                      onSelectedItemChanged: (idx) {
                        setSheetState(() {
                          selectedIdx = idx;
                        });
                      },
                      childDelegate: ListWheelChildBuilderDelegate(
                        builder: (context, index) {
                          if (index < 0 || index >= distances.length) return null;
                          final val = distances[index];
                          final isSelected = index == selectedIdx;
                          return Center(
                            child: Text(
                              '${val.toStringAsFixed(1)} km',
                              style: TextStyle(
                                color: isSelected ? AppColors.voltCyan : (isDark ? Colors.white60 : Colors.black54),
                                fontSize: 22,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          );
                        },
                        childCount: distances.length,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
        );
      },
    );
  }

  void _showDurationTargetPicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final List<int> durations = List.generate(36, (i) => 5 + i * 5);
    int selectedIdx = durations.indexOf(_customTargetDurationMin);
    if (selectedIdx == -1) selectedIdx = 5;
    
    final scrollCtrl = FixedExtentScrollController(initialItem: selectedIdx);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              height: 320,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1)),
              ),
              child: Column(
                children: [
                  _buildPickerHeader(
                    title: 'Set Target Duration',
                    isDark: isDark,
                    onCancel: () => Navigator.pop(ctx),
                    onDone: () {
                      setState(() {
                        _customTargetDurationMin = durations[scrollCtrl.selectedItem];
                        _targetLeftValue = '$_customTargetDurationMin min';
                      });
                      Navigator.pop(ctx);
                    },
                  ),
                  Expanded(
                    child: ListWheelScrollView.useDelegate(
                      controller: scrollCtrl,
                      itemExtent: 44,
                      physics: const FixedExtentScrollPhysics(),
                      perspective: 0.005,
                      onSelectedItemChanged: (idx) {
                        setSheetState(() {
                          selectedIdx = idx;
                        });
                      },
                      childDelegate: ListWheelChildBuilderDelegate(
                        builder: (context, index) {
                          if (index < 0 || index >= durations.length) return null;
                          final val = durations[index];
                          final isSelected = index == selectedIdx;
                          return Center(
                            child: Text(
                              '$val min',
                              style: TextStyle(
                                color: isSelected ? AppColors.voltCyan : (isDark ? Colors.white60 : Colors.black54),
                                fontSize: 22,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          );
                        },
                        childCount: durations.length,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
        );
      },
    );
  }

  void _showCaloriesTargetPicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final List<int> calories = List.generate(40, (i) => 50 + i * 50);
    int selectedIdx = calories.indexOf(_customTargetCalories);
    if (selectedIdx == -1) selectedIdx = 6;
    
    final scrollCtrl = FixedExtentScrollController(initialItem: selectedIdx);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              height: 320,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1)),
              ),
              child: Column(
                children: [
                  _buildPickerHeader(
                    title: 'Set Target Burn',
                    isDark: isDark,
                    onCancel: () => Navigator.pop(ctx),
                    onDone: () {
                      setState(() {
                        _customTargetCalories = calories[scrollCtrl.selectedItem];
                        _targetRightValue = '$_customTargetCalories kcal';
                      });
                      Navigator.pop(ctx);
                    },
                  ),
                  Expanded(
                    child: ListWheelScrollView.useDelegate(
                      controller: scrollCtrl,
                      itemExtent: 44,
                      physics: const FixedExtentScrollPhysics(),
                      perspective: 0.005,
                      onSelectedItemChanged: (idx) {
                        setSheetState(() {
                          selectedIdx = idx;
                        });
                      },
                      childDelegate: ListWheelChildBuilderDelegate(
                        builder: (context, index) {
                          if (index < 0 || index >= calories.length) return null;
                          final val = calories[index];
                          final isSelected = index == selectedIdx;
                          return Center(
                            child: Text(
                              '$val kcal',
                              style: TextStyle(
                                color: isSelected ? AppColors.voltCyan : (isDark ? Colors.white60 : Colors.black54),
                                fontSize: 22,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          );
                        },
                        childCount: calories.length,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
        );
      },
    );
  }

  void _showMusicSelector() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final playlists = [
      {'name': 'LifePulse Cardio Boost', 'genre': 'Upbeat Dance · 130 BPM', 'icon': LucideIcons.zap},
      {'name': 'Sunset Trail Ride', 'genre': 'Chill Acoustic / Lo-Fi · 110 BPM', 'icon': LucideIcons.compass},
      {'name': 'Hardcore Running Mix', 'genre': 'Rock / Metal · 150 BPM', 'icon': LucideIcons.flame},
      {'name': 'Zen Recovery Walk', 'genre': 'Ambient / Meditation · 90 BPM', 'icon': LucideIcons.sprout},
    ];

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
            Text('Select Running Mix', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Choose soundtrack for your workout', style: TextStyle(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.5), fontSize: 13)),
            const SizedBox(height: 20),
            ...playlists.map((pl) {
              final isSelected = _selectedMusicPlaylist == pl['name'];
              return ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.voltCyan.withValues(alpha: 0.15) : (isDark ? Colors.white10 : Colors.black54.withValues(alpha: 0.05)),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(pl['icon'] as IconData, color: isSelected ? AppColors.voltCyan : (isDark ? Colors.white : Colors.black)),
                ),
                title: Text(pl['name'] as String, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
                subtitle: Text(pl['genre'] as String, style: TextStyle(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.5), fontSize: 12)),
                trailing: isSelected ? const Icon(Icons.check_circle, color: AppColors.voltCyan) : null,
                onTap: () {
                  setState(() => _selectedMusicPlaylist = pl['name'] as String);
                  Navigator.pop(ctx);
                },
              );
            }).toList(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildRightMapControls({
    required bool isFullScreen,
    required bool isRunning,
    required bool isDark,
  }) {
    final showCompass = _mapRotation.abs() > 1.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!isRunning) ...[
          _mapControlBtn(
            icon: isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
            onTap: _toggleFullScreen,
          ),
          const SizedBox(height: 8),
        ],
        _mapControlBtn(
          icon: Icons.add,
          onTap: () {
            final newZoom = (_zoom + 1).clamp(1.0, 19.0);
            _mapCtrl.move(_mapCtrl.camera.center, newZoom);
            setState(() => _zoom = newZoom);
          },
        ),
        const SizedBox(height: 8),
        _mapControlBtn(
          icon: Icons.remove,
          onTap: () {
            final newZoom = (_zoom - 1).clamp(1.0, 19.0);
            _mapCtrl.move(_mapCtrl.camera.center, newZoom);
            setState(() => _zoom = newZoom);
          },
        ),
        const SizedBox(height: 8),
        if (showCompass) ...[
          _mapControlBtn(
            icon: Icons.explore,
            iconWidget: Transform.rotate(
              angle: -_mapRotation * pi / 180,
              child: const Icon(LucideIcons.compass, color: AppColors.voltCyan, size: 24),
            ),
            onTap: () {
              _mapCtrl.rotate(0.0);
              setState(() => _mapRotation = 0.0);
            },
          ),
          const SizedBox(height: 8),
        ],
        _mapControlBtn(
          icon: Icons.my_location,
          onTap: _resetLocation,
          color: _follow ? AppColors.voltCyan : null,
        ),
        const SizedBox(height: 8),
        _mapControlBtn(
          icon: Icons.layers,
          onTap: () => _showLayerPicker(context),
        ),
      ],
    );
  }

  Widget _buildFullscreenDrawer(bool isDark, ThemeData theme) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar / Collapse button
            GestureDetector(
              onTap: () => setState(() => _isDrawerCollapsed = !_isDrawerCollapsed),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            if (_isDrawerCollapsed) ...[
              // Collapsed state
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _mockPreRunRoute.isNotEmpty
                          ? '${_routeDistance.toStringAsFixed(1)} km · $_routeDuration min (${_routePreference.name.toUpperCase()})'
                          : 'No route planned',
                      style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _isDrawerCollapsed = false),
                    child: Text(
                      _mockPreRunRoute.isNotEmpty ? 'Details' : 'Plan Route',
                      style: const TextStyle(color: AppColors.voltCyan, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Expanded state
              if (_mockPreRunRoute.isEmpty) ...[
                // Show Route Planner inputs
                _buildRoutePlannerUI(isDark),
              ] else ...[
                // Show Route Summary & targets & Start button
                Row(
                  children: [
                    const Icon(LucideIcons.checkCircle2, color: Colors.green, size: 18),
                    const SizedBox(width: 8),
                    Text('Route Ready', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 15)),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _mockPreRunRoute.clear();
                          _alternativeRoutes.clear();
                          _routeDistance = 0.0;
                          _routeDuration = 0;
                          _routeReadinessScore = 0;
                          _updateTargetUI();
                        });
                      },
                      child: const Text('Edit Locations', style: TextStyle(color: AppColors.voltCyan, fontWeight: FontWeight.w600, fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildRouteSummaryCard(isDark),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: GestureDetector(
                      onTap: () => _onTargetCardTapped(_targetLeftLabel),
                      child: _ghostInput(_targetLeftLabel, _targetLeftValue, isDark),
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: GestureDetector(
                      onTap: () => _onTargetCardTapped(_targetRightLabel),
                      child: _ghostInput(_targetRightLabel, _targetRightValue, isDark),
                    )),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _startCountdown,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.pulseRed,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('START RUN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ],
          ],
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

  Widget _routeComparisonChip(String label, double distKm, double durMin, bool isActive, bool isDark, VoidCallback onTap) {
    final textColor = isDark ? Colors.white : Colors.black;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppColors.voltCyan.withValues(alpha: 0.15) : textColor.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive ? AppColors.voltCyan.withValues(alpha: 0.5) : textColor.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isActive)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(right: 8),
                decoration: const BoxDecoration(
                  color: AppColors.voltCyan,
                  shape: BoxShape.circle,
                ),
              ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isActive ? AppColors.voltCyan : textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${distKm.toStringAsFixed(1)} km · ${durMin.round()} min',
                  style: TextStyle(
                    fontSize: 10,
                    color: isActive ? AppColors.voltCyan.withValues(alpha: 0.8) : textColor.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ],
        ),
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
          color: isActive ? AppColors.pulseRed : surfaceColor.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? AppColors.pulseRed : surfaceColor.withValues(alpha: 0.15)),
          boxShadow: isActive ? [
            BoxShadow(
              color: AppColors.pulseRed.withValues(alpha: 0.3),
              blurRadius: 8,
              spreadRadius: 1,
            )
          ] : null,
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
        color: surfaceColor.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: surfaceColor.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: textColor.withValues(alpha: 0.54), fontSize: 11)),
                const SizedBox(height: 4),
                Text(value, style: TextStyle(color: textColor, fontWeight: FontWeight.w700, fontSize: 16)),
              ],
            ),
          ),
          Icon(Icons.edit, size: 14, color: textColor.withValues(alpha: 0.3)),
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
                      userAgentPackageName: 'com.sudeep.lifepulse',
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
                    onPressed: () async {
                      // Save run notification
                      final uid = Supabase.instance.client.auth.currentUser?.id;
                      if (uid != null && _distKm > 0) {
                        try {
                          await Supabase.instance.client.from('notifications').insert({
                            'user_id': uid,
                            'type': 'run_complete',
                            'title': 'Run Completed! 🏃',
                            'body': 'You ran ${_distKm.toStringAsFixed(2)} km in ${_fmtDur(_durSecs)}',
                            'is_read': false,
                          });
                        } catch (_) {}
                        await NotificationService.showNotification(
                          'Run Completed! 🏃',
                          'You ran ${_distKm.toStringAsFixed(2)} km in ${_fmtDur(_durSecs)}',
                        );
                      }
                      if (mounted) {
                        Navigator.pop(context);
                        _resetRun();
                      }
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
