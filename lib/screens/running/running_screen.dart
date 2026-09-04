import 'dart:async';
import 'dart:io';
import 'package:geocoding/geocoding.dart';
import '../../services/geocoding_service.dart';
import '../../services/route_service.dart';
import '../../services/exceptions.dart';
import '../../models/route_result.dart';
import '../../models/route_option.dart';
import '../../models/location_suggestion.dart';
import '../../widgets/location_input_field.dart';
import '../../services/audio_coach_service.dart';

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/live_run_metric_panel.dart';
import '../../services/watch_connection_manager.dart';
import '../../widgets/glass_card.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../providers/weather_provider.dart';
import 'package:intl/intl.dart';
import '../../constants/activity_types.dart' hide ActivityType;
import '../workout/fitness_screen.dart';
import '../../services/challenge_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/notification_service.dart';
import '../../models/workout_phase.dart';
import '../../providers/step_tracker_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/weather_model.dart';

enum RunState { planning, countdown, running, paused, finished }

class RunningScreen extends StatefulWidget {
  final ValueChanged<bool>? onFullscreenChanged;
  final List<WorkoutPhase>? phases;
  final DailyPlan? plan;

  const RunningScreen({
    super.key,
    this.onFullscreenChanged,
    this.phases,
    this.plan,
  });

  @override State<RunningScreen> createState() => _RunningScreenState();
}

class _RunningScreenState extends State<RunningScreen> with TickerProviderStateMixin {
  final AudioCoachService _audioCoach = AudioCoachService();
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
  double _lastSpeed = 0; // km/h from GPS
  
  // Real Tracking States
  double _totalDistanceMeters = 0;
  Position? _lastValidPosition;
  int? _heartRate;
  Timer? _hrTimer;
  Timer? _gpsWatchdogTimer;
  
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
  List<RouteAlternative> _routeAlternatives = [];

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
  bool _isFullScreenMap = false;
  String _gpsStatusText = 'Waiting for GPS...';

  // Custom target variables (editable)
  double _customTargetPaceMin = 5.5; // default 5:30 /km
  double _customTargetDistanceKm = 5.0;
  int _customTargetDurationMin = 30;
  int _customTargetCalories = 350;

  double _mapRotation = 0.0;
  double _heading = 0.0;
  bool _isDrawerCollapsed = false;


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
    {'name': 'Standard', 'dark': 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}@2x.png', 'light': 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}@2x.png'},
    {'name': 'Streets', 'dark': 'https://{s}.basemaps.cartocdn.com/dark_nolabels/{z}/{x}/{y}@2x.png', 'light': 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'},
    {'name': 'Voyager', 'dark': 'https://{s}.basemaps.cartocdn.com/rastertiles/dark_all/{z}/{x}/{y}@2x.png', 'light': 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}@2x.png'},
    {'name': 'Topo', 'dark': 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}@2x.png', 'light': 'https://tile.opentopomap.org/{z}/{x}/{y}.png'},
  ];

  final GlobalKey _mapKey = GlobalKey();

  // Keys for LocationInputField widgets (needed so we can force-clear them)
  final GlobalKey<State> _startFieldKey = GlobalKey<State>();
  final GlobalKey<State> _destFieldKey = GlobalKey<State>();

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

      if (!mounted) return;
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

      if (!mounted) return;
      if (routeRes.alternatives.isNotEmpty) {
        // Use the pre-classified indices from RouteService
        final fastestIdx = routeRes.fastestIndex;
        final shortestIdx = routeRes.shortestIndex;

        // Auto-select based on user preference
        int selectedIdx = fastestIdx;
        if (_routePreference == RoutePreference.shortest) {
          selectedIdx = shortestIdx;
        }

        debugPrint('[LifePulse] Routes found: ${routeRes.routeAlternatives.length}');
        for (final alt in routeRes.routeAlternatives) {
          debugPrint('[LifePulse] ${alt.label}: ${alt.distanceText}, ${alt.durationText}, ${alt.points.length} pts');
        }
        debugPrint('[LifePulse] Auto-selected: route_$selectedIdx (${routeRes.routeAlternatives[selectedIdx].label})');

        setState(() {
          _lastRouteResult = routeRes;
          _alternativeRoutes = routeRes.alternatives;
          _routeAlternatives = routeRes.routeAlternatives;
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
        _fitMapToAllRoutes();
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
        _routeAlternatives.clear();
        _lastRouteResult = null;
        _routeDistance = 0.0;
        _routeDuration = 0;
        _routeReadinessScore = 0;
      }
    });

    if (_startLocCtrl.text.isNotEmpty && _destLocCtrl.text.isNotEmpty &&
        _startRoutePos != null && _endRoutePos != null) {
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

  /// Fit map to the selected route only.
  void _fitMapToRoute() {
    if (_mockPreRunRoute.length < 2) return;
    try {
      final bounds = LatLngBounds.fromPoints(_mockPreRunRoute);
      _mapCtrl.fitCamera(CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(60.0),
      ));
    } catch (e) {
      debugPrint('Failed to fit camera to selected route bounds: $e');
    }
  }

  /// Fit map to bounds of ALL alternatives so the user can see the full picture.
  void _fitMapToAllRoutes() {
    if (_alternativeRoutes.isEmpty) return;
    try {
      final allPoints = _alternativeRoutes.expand((pts) => pts).toList();
      if (allPoints.length < 2) return;
      final bounds = LatLngBounds.fromPoints(allPoints);
      _mapCtrl.fitCamera(CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(52.0),
      ));
    } catch (e) {
      debugPrint('Failed to fit camera to all route bounds: $e');
    }
  }

  void _selectAlternativeRoute(int index) {
    if (index < 0 || index >= _alternativeRoutes.length) return;
    final result = _lastRouteResult;
    debugPrint('[LifePulse] Selected route: route_$index (${_routeAlternatives.isNotEmpty ? _routeAlternatives[index].label : "?"}, ${_alternativeRoutes[index].length} points)');
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
        final placemarks = await placemarkFromCoordinates(
            _curPos!.latitude, _curPos!.longitude);
        if (!mounted) return;
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final name = [p.locality, p.administrativeArea, p.country]
              .where((s) => s != null && s.isNotEmpty)
              .join(', ');
          setState(() {
            _startLocCtrl.text = name.isNotEmpty
                ? name
                : '${_curPos!.latitude.toStringAsFixed(4)}, ${_curPos!.longitude.toStringAsFixed(4)}';
            _startRoutePos = _curPos;
            // Clear any stale route since start has changed
            _alternativeRoutes.clear();
            _routeAlternatives.clear();
            _lastRouteResult = null;
            _mockPreRunRoute.clear();
          });
        }
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _startLocCtrl.text =
              '${_curPos!.latitude.toStringAsFixed(4)}, ${_curPos!.longitude.toStringAsFixed(4)}';
          _startRoutePos = _curPos;
        });
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Location not available yet. Make sure GPS is enabled.')),
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
          const SnackBar(content: Text('Locating you… Ensure GPS is enabled.')),
        );
      }
      _initLocation();
    }
  }

  List<WorkoutPhase>? _guidedPhases;
  int _currentPhaseIndex = 0;
  int _phaseTimeElapsedSecs = 0;

  @override
  void initState() {
    super.initState();
    if (widget.phases != null && widget.phases!.isNotEmpty) {
      _guidedPhases = List.from(widget.phases!);
      _currentPhaseIndex = 0;
      _phaseTimeElapsedSecs = 0;
    }
    _audioCoach.initialize();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.15).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _updateTargetUI();
    _initLocation();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final app = context.read<AppProvider>();
    final plan = widget.plan ?? app.activeRunPlan;
    if (plan != null && _state == RunState.planning) {
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
          _targetLeftValue = '${plan.duration} min';
          _targetRightLabel = 'Target Burn';
          _targetRightValue = '${plan.kcal} kcal';
        });
        if (app.activeRunPlan != null) {
          app.setActiveRunPlan(null);
        }
      });
    }
  }

  Future<void> _initLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('LifePulse: Location services are disabled.');
      return;
    }

    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied) {
        debugPrint('LifePulse: Location permission denied.');
        return;
      }
    }
    if (perm == LocationPermission.deniedForever) {
      debugPrint('LifePulse: Location permission permanently denied.');
      return;
    }

    try {
      final p = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.bestForNavigation));
      if (mounted) {
        setState(() => _curPos = LatLng(p.latitude, p.longitude));
        _mapCtrl.move(_curPos!, _zoom);
      }
    } catch (e) {
      debugPrint('LifePulse: Error getting initial location: $e');
    }
  }

  // ─── GPS helpers ─────────────────────────────────────────────────────────

  /// Returns true when location service is enabled and permission granted.
  Future<bool> _ensureLocationReady() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('LifePulse GPS: Location services disabled');
      return false;
    }

    var permission = await Geolocator.checkPermission();
    debugPrint('LifePulse GPS: Current permission: $permission');

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      debugPrint('LifePulse GPS: After request, permission: $permission');
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      debugPrint('LifePulse GPS: Permission not granted: $permission');
      return false;
    }

    debugPrint('LifePulse GPS: Permission OK ($permission)');
    return true;
  }

  /// Adaptive GPS quality filter — accepts up to 100 m for indoor/testing.
  bool _isAcceptableGpsPoint(Position p) {
    if (p.latitude == 0.0 && p.longitude == 0.0) return false;
    if (p.accuracy <= 50) return true;
    if (p.accuracy <= 100) {
      debugPrint('LifePulse GPS: Accepting low-accuracy point for testing: ${p.accuracy.toStringAsFixed(0)}m');
      return true;
    }
    debugPrint('LifePulse GPS: Rejecting point — accuracy too poor: ${p.accuracy.toStringAsFixed(0)}m');
    return false;
  }

  void _startGpsStream() {
    _posSub?.cancel();

    late LocationSettings locSettings;
    if (Platform.isAndroid) {
      locSettings = AndroidSettings(
        accuracy: LocationAccuracy.high, // high is more reliable than bestForNavigation on many Android devices
        distanceFilter: 1,
        intervalDuration: const Duration(seconds: 1),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'LifePulse Running',
          notificationText: 'Tracking your run',
          enableWakeLock: true,
        ),
      );
    } else if (Platform.isIOS) {
      locSettings = AppleSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 2,
        activityType: ActivityType.fitness,
        pauseLocationUpdatesAutomatically: false,
        allowBackgroundLocationUpdates: true,
        showBackgroundLocationIndicator: true,
      );
    } else {
      locSettings = const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 2,
      );
    }

    debugPrint('LifePulse GPS: Starting position stream...');
    _posSub = Geolocator.getPositionStream(
      locationSettings: locSettings,
    ).listen(
      _onPos,
      onError: (e) {
        debugPrint('LifePulse GPS stream error: $e');
        if (!mounted) return;
        setState(() => _gpsStatusText = 'GPS stream error — check permissions');
      },
      onDone: () => debugPrint('LifePulse GPS stream closed'),
    );

    // Watchdog: if no callback after 10 s, remind user to go outdoors
    _gpsWatchdogTimer?.cancel();
    _gpsWatchdogTimer = Timer(const Duration(seconds: 10), () {
      if (!mounted) return;
      if (_state == RunState.running && _gpsRoute.length < 2) {
        setState(() => _gpsStatusText = 'Waiting for GPS — try moving outdoors');
      }
    });
  }

  void _onPos(Position p) {
    if (!mounted) return;

    // Cancel watchdog — we have a GPS callback
    _gpsWatchdogTimer?.cancel();

    debugPrint('LifePulse GPS point received: lat=${p.latitude}, lng=${p.longitude}, accuracy=${p.accuracy}m, state=$_state');

    final pt = LatLng(p.latitude, p.longitude);
    final speedKmh = p.speed * 3.6;

    // Update map marker regardless of run state
    if (!_isAcceptableGpsPoint(p)) {
      setState(() {
        _curPos = pt;
        _gpsStatusText = 'Low GPS accuracy: ${p.accuracy.toStringAsFixed(0)}m';
      });
      return;
    }

    setState(() {
      _curPos = pt;
      _lastSpeed = speedKmh;
      _heading = p.heading;
    });

    if (_follow) {
      try {
        _mapCtrl.move(pt, _zoom);
      } catch (e) {
        debugPrint('LifePulse GPS: map move failed: $e');
      }
    }

    // Only accumulate distance when actively running
    if (_state != RunState.running) return;

    if (_lastValidPosition == null) {
      // First real point after start/resume — seed the route
      setState(() {
        _lastValidPosition = p;
        if (_gpsRoute.isEmpty) _gpsRoute.add(pt);
        _gpsStatusText = p.accuracy <= 50
            ? 'GPS ready'
            : 'Tracking (accuracy: ${p.accuracy.toStringAsFixed(0)}m)';
      });
      debugPrint('LifePulse GPS: First valid point seeded from stream');
      return;
    }

    final segmentMeters = Geolocator.distanceBetween(
      _lastValidPosition!.latitude,
      _lastValidPosition!.longitude,
      p.latitude,
      p.longitude,
    );
    debugPrint('LifePulse GPS segment: ${segmentMeters.toStringAsFixed(1)}m');

    if (segmentMeters < 1.0) {
      // Tiny jitter — update position but don't count distance
      setState(() {
        _curPos = pt;
        _gpsStatusText = 'Tracking movement';
      });
      return;
    }

    if (segmentMeters > 200) {
      // GPS jump — likely a bad fix; ignore for distance but update cursor
      debugPrint('LifePulse GPS: Jump ignored (${segmentMeters.toStringAsFixed(0)}m)');
      setState(() {
        _curPos = pt;
        _gpsStatusText = 'GPS jump ignored';
      });
      return;
    }

    // Valid movement — accumulate
    setState(() {
      _totalDistanceMeters += segmentMeters;
      _distKm = _totalDistanceMeters / 1000.0;
      _calories = (_distKm * 65).round();
      _lastValidPosition = p;
      _gpsRoute.add(pt);

      if (_distKm >= 0.01) {
        final elapsedSecs = _elapsed().inSeconds;
        _paceMin = elapsedSecs > 0 ? elapsedSecs / _distKm : 0.0;
      }

      _gpsStatusText = p.accuracy <= 50
          ? 'GPS ready'
          : 'Tracking (accuracy: ${p.accuracy.toStringAsFixed(0)}m)';
    });

    _audioCoach.announceDistance(_distKm);
    debugPrint('LifePulse total: ${_totalDistanceMeters.toStringAsFixed(1)}m, route pts: ${_gpsRoute.length}, pace: ${_paceMin.toStringAsFixed(0)}s/km');
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

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_countdown > 1) {
        HapticFeedback.heavyImpact();
        setState(() => _countdown--);
      } else {
        HapticFeedback.vibrate();
        timer.cancel();
        _startRun(); // async — fire and forget; errors handled inside
      }
    });
  }

  Future<void> _pollHeartRate() async {
    final watchMgr = WatchConnectionManager();
    final data = await watchMgr.fetchHealthData();
    if (mounted && data['heartRate'] != null) {
      setState(() {
        _heartRate = data['heartRate'] as int;
      });
      _audioCoach.announceHeartRateWarning(_heartRate!);
    }
  }

  Future<void> _startRun() async {
    debugPrint('LifePulse: Start Free Run tapped');

    // 1. Ensure location is available before doing anything
    final ready = await _ensureLocationReady();
    if (!ready) {
      if (!mounted) return;
      setState(() => _gpsStatusText = 'Location permission required');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Location permission is required to track your run.'),
          action: SnackBarAction(
            label: 'Settings',
            onPressed: () => Geolocator.openAppSettings(),
          ),
        ),
      );
      // Revert state back to planning so the user can try again
      if (mounted) setState(() => _state = RunState.planning);
      return;
    }

    // 2. Cancel old subscriptions and reset state
    _posSub?.cancel();
    _gpsWatchdogTimer?.cancel();
    _timer?.cancel();
    _hrTimer?.cancel();

    setState(() {
      _state = RunState.running;
      _startTime = DateTime.now();
      _distKm = 0;
      _paceMin = 0;
      _calories = 0;
      _durSecs = 0;
      _totalDistanceMeters = 0;
      _lastValidPosition = null;
      _heartRate = null;
      _gpsRoute.clear();
      _follow = true;
      _gpsStatusText = 'Getting GPS...';
    });

    // 3. Seed first GPS position immediately so the route point is ready
    debugPrint('LifePulse GPS: Requesting immediate first position...');
    try {
      final firstPos = await Geolocator.getCurrentPosition(
        locationSettings: Platform.isAndroid
            ? AndroidSettings(
                accuracy: LocationAccuracy.high,
                timeLimit: const Duration(seconds: 10),
              )
            : const LocationSettings(
                accuracy: LocationAccuracy.high,
              ),
      );
      final firstPt = LatLng(firstPos.latitude, firstPos.longitude);
      debugPrint('LifePulse GPS: First position obtained: ${firstPos.latitude}, ${firstPos.longitude}, accuracy=${firstPos.accuracy}m');

      if (!mounted) return;
      setState(() {
        _curPos = firstPt;
        _lastValidPosition = firstPos;
        _gpsRoute.add(firstPt);
        _gpsStatusText = 'GPS ready';
      });

      try {
        _mapCtrl.move(firstPt, 18);
      } catch (e) {
        debugPrint('LifePulse GPS: Map move failed after first position: $e');
      }
    } catch (e) {
      debugPrint('LifePulse GPS: First position failed: $e');
      if (mounted) setState(() => _gpsStatusText = 'Waiting for GPS...');
      // Continue anyway — the stream will pick up as soon as GPS is ready
    }

    // 4. Start continuous position stream
    _startGpsStream();
    _audioCoach.announceWorkoutStart(_startRoutePos != null);

    // 5. Duration timer (updates every second)
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _onTimerTick());

    // 6. Heart-rate polling
    _hrTimer = Timer.periodic(const Duration(seconds: 10), (_) => _pollHeartRate());
    _pollHeartRate();
  }

  void _pauseRun() {
    HapticFeedback.mediumImpact();
    _audioCoach.announceWorkoutPaused();
    setState(() {
      _state = RunState.paused;
      _pauseStart = DateTime.now();
    });
    _timer?.cancel();
    _hrTimer?.cancel();
    _posSub?.cancel();
  }

  void _resumeRun() {
    HapticFeedback.lightImpact();
    _audioCoach.announceWorkoutResumed();
    if (_pauseStart != null) {
      _pausedDur += DateTime.now().difference(_pauseStart!);
      _pauseStart = null;
    }

    setState(() {
      _state = RunState.running;
      _lastValidPosition = null; // Reset to avoid a jump segment after pause
      if (_curPos != null) _gpsRoute.add(_curPos!);
      _gpsStatusText = 'Resuming GPS...';
    });

    _startGpsStream();

    _hrTimer?.cancel();
    _hrTimer = Timer.periodic(const Duration(seconds: 10), (_) => _pollHeartRate());

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _onTimerTick());
  }

  void _onTimerTick() {
    if (!mounted) return;
    setState(() {
      _durSecs = _elapsed().inSeconds;
      if (_distKm > 0.01 && _durSecs > 0) {
        _paceMin = _durSecs / _distKm;
      }
      if (_guidedPhases != null) {
        _phaseTimeElapsedSecs++;
        final currentPhaseSecs = _guidedPhases![_currentPhaseIndex].durationMinutes * 60;
        if (_phaseTimeElapsedSecs >= currentPhaseSecs) {
          _advanceGuidedPhase();
        }
      }
    });
    _audioCoach.announcePace(_paceMin / 60.0, _distKm);
    if (mounted) {
      final currentTemp = context.read<WeatherProvider>().weather?.currentTemp ?? 25.0;
      _audioCoach.announceHydrationReminder(currentTemp: currentTemp);
    }
  }

  void _advanceGuidedPhase() {
    HapticFeedback.heavyImpact();
    if (_currentPhaseIndex < _guidedPhases!.length - 1) {
      setState(() {
        _currentPhaseIndex++;
        _phaseTimeElapsedSecs = 0;
      });
    } else {
      _finishRun();
    }
  }

  void _skipGuidedPhase() {
    HapticFeedback.mediumImpact();
    _advanceGuidedPhase();
  }

  void _finishRun() {
    HapticFeedback.heavyImpact();
    _audioCoach.announceWorkoutCompleted();
    _timer?.cancel();
    _hrTimer?.cancel();
    _posSub?.cancel();
    setState(() => _state = RunState.finished);
    // I1: Update Distance challenge progress after run
    if (_distKm > 0) {
      ChallengeService().updateDistanceChallengesAfterRun(_distKm);
    }

    if (widget.plan != null) {
      final app = context.read<AppProvider>();
      app.completePlan(widget.plan!.id);

      final durMin = int.tryParse(widget.plan!.duration) ?? 30;
      final kcalBurned = int.tryParse(widget.plan!.kcal) ?? 200;
      app.addWorkout({
        'type': widget.plan!.type,
        'title': widget.plan!.title,
        'duration': durMin,
        'calories': kcalBurned,
        'date': DateTime.now().toIso8601String(),
      });

      context.read<StepTrackerProvider>().addManualSteps(durMin * 100);
    }

    _showSummary();
  }

  void _resetRun() {
    widget.onFullscreenChanged?.call(_isFullScreenMap);
    _audioCoach.resetSession();
    _timer?.cancel();
    _hrTimer?.cancel();
    _posSub?.cancel();
    
    setState(() {
      _state = RunState.planning;
      _gpsRoute.clear();
      _distKm = 0;
      _paceMin = 0;
      _calories = 0;
      _durSecs = 0;
      _totalDistanceMeters = 0;
      _lastValidPosition = null;
      _heartRate = null;
      _lastSpeed = 0;
      _pausedDur = Duration.zero;
      _startTime = null;
    });
    
    // Re-init location without tracking
    _initLocation();
    
    if (_curPos != null) _mapCtrl.move(_curPos!, 16); // Reset zoom
  }

  String _fmtDur(int s) {
    final m = s ~/ 60;
    final sec = s % 60;
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  String _fmtPace(double paceSecondsPerKm) {
    if (paceSecondsPerKm.isNaN || paceSecondsPerKm.isInfinite || paceSecondsPerKm <= 0 || paceSecondsPerKm > 3600) {
      return '--:--';
    }
    final minutes = paceSecondsPerKm ~/ 60;
    final seconds = (paceSecondsPerKm % 60).round();
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _startLocCtrl.dispose();
    _destLocCtrl.dispose();
    _posSub?.cancel();
    _timer?.cancel();
    _hrTimer?.cancel();
    _gpsWatchdogTimer?.cancel();
    _audioCoach.stop();
    _pulseCtrl.dispose();
    widget.onFullscreenChanged?.call(false);
    super.dispose();
  }

  Widget _buildMapWidget(String mapUrl, bool isDark, bool showPreRunRoute) {
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
          if (gesture && _follow) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _follow = false);
            });
          }
          _zoom = pos.zoom ?? _zoom;
          final rot = _mapCtrl.camera.rotation;
          if ((rot - _mapRotation).abs() > 0.1) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _mapRotation = rot);
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

        // Unselected alternative routes — visible muted purple/lavender
        if (showPreRunRoute && _alternativeRoutes.length > 1)
          PolylineLayer(polylines: [
            for (int i = 0; i < _alternativeRoutes.length; i++)
              if (i != _selectedRouteIndex) ...[
                // Glow layer
                Polyline(
                  points: _alternativeRoutes[i],
                  strokeWidth: 7,
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                ),
                // Core line
                Polyline(
                  points: _alternativeRoutes[i],
                  strokeWidth: 3.5,
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.55),
                  borderStrokeWidth: 1,
                  borderColor: Colors.white.withValues(alpha: 0.3),
                ),
              ],
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

  /// Horizontally scrollable cards showing each route alternative.
  /// Appears below the map when routes have been loaded.
  Widget _buildRouteAlternativeCards(bool isDark) {
    if (_routeAlternatives.isEmpty) return const SizedBox.shrink();

    final textColor = isDark ? Colors.white : Colors.black;

    // Single-route message
    if (_routeAlternatives.length == 1) {
      final alt = _routeAlternatives.first;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.voltCyan.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.voltCyan.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: AppColors.voltCyan, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(alt.label,
                      style: const TextStyle(
                          color: AppColors.voltCyan,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                  Text('${alt.summaryText} · Only 1 route available',
                      style: TextStyle(
                          color: textColor.withValues(alpha: 0.6),
                          fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Multiple routes — horizontal scroll cards
    return SizedBox(
      height: 84,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _routeAlternatives.length,
        itemBuilder: (context, i) {
          final alt = _routeAlternatives[i];
          final isSelected = i == _selectedRouteIndex;

          return GestureDetector(
            onTap: () => _selectAlternativeRoute(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: 158,
              margin: EdgeInsets.only(left: i == 0 ? 0 : 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.voltCyan.withValues(alpha: 0.12)
                    : textColor.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? AppColors.voltCyan
                      : textColor.withValues(alpha: 0.12),
                  width: isSelected ? 1.5 : 1.0,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.voltCyan.withValues(alpha: 0.18),
                          blurRadius: 8,
                          spreadRadius: 1,
                        )
                      ]
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.check_circle
                            : _routeIcon(alt.label),
                        size: 14,
                        color: isSelected
                            ? AppColors.voltCyan
                            : textColor.withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          alt.label,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? AppColors.voltCyan
                                : textColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    alt.durationText,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isSelected
                          ? AppColors.voltCyan
                          : textColor,
                    ),
                  ),
                  Text(
                    alt.distanceText,
                    style: TextStyle(
                      fontSize: 11,
                      color: textColor.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _routeIcon(String label) {
    final l = label.toLowerCase();
    if (l.contains('fastest')) return LucideIcons.zap;
    if (l.contains('shortest')) return LucideIcons.ruler;
    return LucideIcons.route;
  }

  Widget _buildWeatherAirQualityCard(WeatherModel? weather, bool isDark) {
    final tempText = weather != null ? '${weather.currentTemp.round()}°C' : '28°C';
    final condText = weather != null ? weather.condition : 'Partly Cloudy';
    final aqiVal = weather?.aqi ?? 42;
    final aqiCategory = aqiVal <= 50 ? 'Good' : (aqiVal <= 100 ? 'Moderate' : 'Unhealthy');
    final humidity = weather?.hydration ?? '64%';
    final wind = weather?.windSpeed != null ? '${weather!.windSpeed.round()} km/h' : '12 km/h';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.zenDarkCard : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.cardBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.accentOrange.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.cloudSun, color: AppColors.accentOrange, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$tempText $condText',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Perfect weather for an outdoor session',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.neutralGray,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMiniWeatherMetric(LucideIcons.leaf, 'Air Quality', '$aqiVal $aqiCategory', AppColors.primaryGreen, isDark),
              _buildMiniWeatherMetric(LucideIcons.droplets, 'Humidity', humidity, AppColors.primaryTeal, isDark),
              _buildMiniWeatherMetric(LucideIcons.wind, 'Wind', wind, AppColors.secondaryBlue, isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniWeatherMetric(IconData icon, String label, String value, Color iconColor, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: iconColor),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: AppColors.neutralGray,
              ),
            ),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildScenicStartCard(bool isDark) {
    return Container(
      width: double.infinity,
      height: 240,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [const Color(0xFFE0E7FF), const Color(0xFFCCFBF1), const Color(0xFFE0F2FE)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryTeal.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background decorative rings
          Positioned(
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.45),
                  width: 1.5,
                ),
              ),
            ),
          ),
          Positioned(
            child: Container(
              width: 155,
              height: 155,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.7),
                  width: 2,
                ),
              ),
            ),
          ),
          // Large circular Start Run button
          GestureDetector(
            onTap: _startCountdown,
            child: Container(
              width: 126,
              height: 126,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.secondaryBlue, AppColors.primaryTeal],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryTeal.withValues(alpha: 0.45),
                    blurRadius: 24,
                    spreadRadius: 2,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.play, color: Colors.white, size: 28),
                  const SizedBox(height: 6),
                  Text(
                    'START RUN',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    'Tap to begin',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Quick Target badge in top corner
          Positioned(
            top: 14,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.target, size: 12, color: AppColors.secondaryBlue),
                  const SizedBox(width: 4),
                  Text(
                    '5.0 km Target',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivitiesSection(bool isDark) {
    final runs = [
      {
        'title': 'Morning Run',
        'date': 'May 28, 2025',
        'distance': '5.02 km',
        'duration': '32:14',
        'pace': '6:25 /km',
        'calories': '412 kcal',
        'iconColor': AppColors.primaryTeal,
      },
      {
        'title': 'Tempo Run',
        'date': 'May 26, 2025',
        'distance': '6.21 km',
        'duration': '38:22',
        'pace': '6:10 /km',
        'calories': '520 kcal',
        'iconColor': AppColors.secondaryBlue,
      },
      {
        'title': 'Easy Run',
        'date': 'May 24, 2025',
        'distance': '3.12 km',
        'duration': '20:15',
        'pace': '6:30 /km',
        'calories': '250 kcal',
        'iconColor': AppColors.primaryGreen,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Activities',
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            GestureDetector(
              onTap: () {},
              child: Text(
                'View All',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryTeal,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...runs.map((r) => _buildRecentRunCard(r, isDark)),
      ],
    );
  }

  Widget _buildRecentRunCard(Map<String, dynamic> r, bool isDark) {
    final Color iconColor = r['iconColor'] as Color;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.zenDarkCard : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.cardBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(LucideIcons.footprints, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      r['title'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      r['distance'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryTeal,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      r['date'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.neutralGray,
                      ),
                    ),
                    Text(
                      '${r['duration']} · ${r['pace']} · ${r['calories']}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.neutralGray,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          const Icon(LucideIcons.chevronRight, size: 16, color: AppColors.neutralGray),
        ],
      ),
    );
  }

  Widget _buildCompactRoutePlannerCard(bool isDark) {
    // canSearch: either both coordinate-backed, or both have text (fallback geocode)
    bool canSearch = (_startRoutePos != null && _endRoutePos != null) ||
        (_startLocCtrl.text.isNotEmpty && _destLocCtrl.text.isNotEmpty);
    String statusText = 'No route';
    if (_isLoadingRoute) statusText = "Finding...";
    else if (_alternativeRoutes.isNotEmpty) statusText = "Route ready";
    else if (_routeError != null) statusText = "Unavailable";

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
              const Icon(LucideIcons.navigation, color: AppColors.voltCyan, size: 16),
              const SizedBox(width: 8),
              Text('Plan Route', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 14)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(statusText, style: TextStyle(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.7), fontSize: 10, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // ── Inputs with autocomplete ──
          Stack(
            alignment: Alignment.centerRight,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LocationInputField(
                    key: _startFieldKey,
                    controller: _startLocCtrl,
                    hint: 'Start location',
                    prefixIcon: LucideIcons.mapPin,
                    prefixIconColor: AppColors.voltCyan,
                    isDark: isDark,
                    isTop: true,
                    trailingAction: GestureDetector(
                      onTap: _fillCurrentLocation,
                      child: Icon(
                        Icons.my_location,
                        size: 18,
                        color: AppColors.voltCyan.withValues(alpha: 0.7),
                      ),
                    ),
                    onSuggestionSelected: (LocationSuggestion s) {
                      setState(() {
                        _startRoutePos = s.coordinates;
                        // Clear stale route
                        _alternativeRoutes.clear();
                        _routeAlternatives.clear();
                        _lastRouteResult = null;
                        _mockPreRunRoute.clear();
                        _routeReadinessScore = 0;
                      });
                      debugPrint('[RunningScreen] Start selected: "${s.shortName}" ${s.latitude},${s.longitude}');
                    },
                    onCoordinatesCleared: () => setState(() {
                      _startRoutePos = null;
                      _alternativeRoutes.clear();
                      _routeAlternatives.clear();
                      _lastRouteResult = null;
                      _mockPreRunRoute.clear();
                      _routeReadinessScore = 0;
                    }),
                  ),
                  const SizedBox(height: 2),
                  LocationInputField(
                    key: _destFieldKey,
                    controller: _destLocCtrl,
                    hint: 'Destination',
                    prefixIcon: LucideIcons.flag,
                    prefixIconColor: AppColors.pulseRed,
                    isDark: isDark,
                    isTop: false,
                    onSuggestionSelected: (LocationSuggestion s) {
                      setState(() {
                        _endRoutePos = s.coordinates;
                        // Clear stale route
                        _alternativeRoutes.clear();
                        _routeAlternatives.clear();
                        _lastRouteResult = null;
                        _mockPreRunRoute.clear();
                        _routeReadinessScore = 0;
                      });
                      debugPrint('[RunningScreen] Dest selected: "${s.shortName}" ${s.latitude},${s.longitude}');
                    },
                    onCoordinatesCleared: () => setState(() {
                      _endRoutePos = null;
                      _alternativeRoutes.clear();
                      _routeAlternatives.clear();
                      _lastRouteResult = null;
                      _mockPreRunRoute.clear();
                      _routeReadinessScore = 0;
                    }),
                  ),
                ],
              ),
              // Swap button overlaid on the right
              Positioned(
                right: 12,
                top: 0,
                bottom: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: _swapLocations,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 4),
                        ],
                        border: Border.all(
                            color: (isDark ? Colors.white : Colors.black)
                                .withValues(alpha: 0.05)),
                      ),
                      child: Icon(Icons.swap_vert,
                          size: 18,
                          color: isDark ? Colors.white : Colors.black),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: kRouteOptions.map((option) {
                final isActive = _routePreference == option.preference;
                final isSupported = option.isSupported;
                final textColor = isDark ? Colors.white : Colors.black;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () => _onRoutePreferenceSelected(option),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.voltCyan.withValues(alpha: 0.15)
                            : textColor.withValues(alpha: isSupported ? 0.05 : 0.02),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isActive
                              ? AppColors.voltCyan
                              : textColor.withValues(alpha: isSupported ? 0.1 : 0.04),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(option.icon, size: 12, color: isActive ? AppColors.voltCyan : textColor.withValues(alpha: isSupported ? 0.7 : 0.3)),
                          const SizedBox(width: 4),
                          Text(
                            option.label,
                            style: TextStyle(fontSize: 11, fontWeight: isActive ? FontWeight.bold : FontWeight.w500, color: isActive ? AppColors.voltCyan : textColor.withValues(alpha: isSupported ? 0.9 : 0.4)),
                          ),
                          if (!isSupported) ...[
                            const SizedBox(width: 4),
                            Text('Soon', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.solarAmber.withValues(alpha: 0.7))),
                          ]
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          if (_alternativeRoutes.length > 1 && _lastRouteResult != null) ...[
            const SizedBox(height: 8),
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
                  const SizedBox(width: 6),
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
          if (_routeError != null) ...[
            const SizedBox(height: 10),
            Text(_routeError!, style: const TextStyle(color: AppColors.pulseRed, fontSize: 11)),
          ],
          const SizedBox(height: 12),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoadingRoute
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5))
                  : Text(_alternativeRoutes.isNotEmpty ? 'Route Ready' : (_routeError != null && _isRetryableError ? 'Try Again' : 'Find Routes'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
          // ── 1. PLANNING VIEW (Scrollable Reference Design) ──
          if (!isRunningPhase && !_isFullScreenMap)
            Positioned.fill(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(
                  left: AppSpacing.screenMargin,
                  right: AppSpacing.screenMargin,
                  top: 12,
                  bottom: 150,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header: Run & Let's hit the road ──
                    Text(
                      'Run',
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Let's hit the road",
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.neutralGray,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Weather & Air Quality Card (Reference Design) ──
                    _buildWeatherAirQualityCard(weather, isDark),
                    const SizedBox(height: 18),

                    // ── Activity Selection Chips: Outdoor Run, Treadmill, Trail Run ──
                    Row(
                      children: ['Outdoor Run', 'Treadmill', 'Trail Run'].map((type) {
                        final isActive = _selectedRunType == type;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              setState(() => _selectedRunType = type);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? AppColors.primaryTeal
                                    : (isDark ? AppColors.zenDarkCard : Colors.white),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isActive
                                      ? AppColors.primaryTeal
                                      : (isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.cardBorder),
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: isActive
                                        ? AppColors.primaryTeal.withValues(alpha: 0.3)
                                        : Colors.black.withValues(alpha: 0.03),
                                    blurRadius: isActive ? 10 : 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                type,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isActive
                                      ? Colors.white
                                      : (isDark ? Colors.white70 : AppColors.textPrimary),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),

                    // ── Scenic Pathway Card with Large Gradient Circular Button ──
                    _buildScenicStartCard(isDark),
                    const SizedBox(height: 24),

                    // ── Recent Activities List (Reference Design) ──
                    _buildRecentActivitiesSection(isDark),
                    const SizedBox(height: 24),

                    // ── Optional Route Planner (Expandable Card) ──
                    _buildCompactRoutePlannerCard(isDark),
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

            // GPS Status Pill
            if (_state == RunState.running)
              Positioned(
                top: MediaQuery.of(context).padding.top > 20 ? MediaQuery.of(context).padding.top + 16 : 40,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.satellite, size: 14, color: AppColors.voltCyan),
                      const SizedBox(width: 8),
                      Text(
                        _gpsStatusText,
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
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
                bpm: _heartRate,
                duration: _fmtDur(_durSecs),
              ),
            ),

            if (isRunningPhase && _guidedPhases != null)
              Positioned(
                top: (MediaQuery.of(context).padding.top > 20 ? MediaQuery.of(context).padding.top + 16 : 40) + 48,
                left: 16,
                right: 16,
                child: _buildGuidedPhaseOverlay(isDark, theme),
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

          // Audio Coach row
          ListenableBuilder(
            listenable: _audioCoach,
            builder: (context, _) {
              return Container(
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
                        onTap: _showAudioCoachSettings,
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: _audioCoach.enabled ? AppColors.pulseRed : Colors.grey.withValues(alpha: 0.5),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(LucideIcons.mic, size: 16, color: Colors.white),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('LifePulse Audio Coach', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                                  Text(_audioCoach.enabled ? 'Voice guidance enabled' : 'Tap to configure voice prompts', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                  if (_audioCoach.enabled)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        [
                                          if (_audioCoach.distanceEnabled) 'Dist',
                                          if (_audioCoach.paceEnabled) 'Pace',
                                          if (_audioCoach.hydrationEnabled) 'Hydration',
                                          if (_audioCoach.heartRateEnabled) 'HR'
                                        ].join(' · '),
                                        style: TextStyle(color: AppColors.pulseRed.withValues(alpha: 0.8), fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Switch(
                      value: _audioCoach.enabled,
                      onChanged: (v) => _audioCoach.toggleEnabled(v),
                      activeTrackColor: AppColors.pulseRed,
                    ),
                  ],
                ),
              );
            },
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
          
          const SizedBox(height: 160), // Padding for bottom nav
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

  void _showAudioCoachSettings() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => ListenableBuilder(
        listenable: _audioCoach,
        builder: (context, _) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Audio Coach Settings', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Customize your live voice guidance', style: TextStyle(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.5), fontSize: 13)),
                const SizedBox(height: 20),
                
                SwitchListTile(
                  title: Text('Enable Audio Coach', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
                  subtitle: Text('Master toggle for all voice prompts', style: TextStyle(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.5), fontSize: 12)),
                  value: _audioCoach.enabled,
                  onChanged: (v) => _audioCoach.toggleEnabled(v),
                  activeColor: AppColors.pulseRed,
                  contentPadding: EdgeInsets.zero,
                ),
                const Divider(),
                
                SwitchListTile(
                  title: Text('Distance Milestones', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                  subtitle: Text('Announce every 0.5km and 1km', style: TextStyle(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.5), fontSize: 12)),
                  value: _audioCoach.distanceEnabled,
                  onChanged: _audioCoach.enabled ? (v) => _audioCoach.toggleDistance(v) : null,
                  activeColor: AppColors.pulseRed,
                  contentPadding: EdgeInsets.zero,
                ),
                
                SwitchListTile(
                  title: Text('Pace Updates', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                  subtitle: Text('Average pace update every 5 mins', style: TextStyle(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.5), fontSize: 12)),
                  value: _audioCoach.paceEnabled,
                  onChanged: _audioCoach.enabled ? (v) => _audioCoach.togglePace(v) : null,
                  activeColor: AppColors.pulseRed,
                  contentPadding: EdgeInsets.zero,
                ),
                
                SwitchListTile(
                  title: Text('Hydration Reminders', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                  subtitle: Text('Smart reminders based on weather temp', style: TextStyle(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.5), fontSize: 12)),
                  value: _audioCoach.hydrationEnabled,
                  onChanged: _audioCoach.enabled ? (v) => _audioCoach.toggleHydration(v) : null,
                  activeColor: AppColors.pulseRed,
                  contentPadding: EdgeInsets.zero,
                ),
                
                SwitchListTile(
                  title: Text('Heart Rate Alerts', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                  subtitle: Text('Warn if HR goes above 170 bpm', style: TextStyle(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.5), fontSize: 12)),
                  value: _audioCoach.heartRateEnabled,
                  onChanged: _audioCoach.enabled ? (v) => _audioCoach.toggleHeartRate(v) : null,
                  activeColor: AppColors.pulseRed,
                  contentPadding: EdgeInsets.zero,
                ),
                
                const SizedBox(height: 16),
              ],
            ),
          );
        }
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
                      _mockPreRunRoute.isNotEmpty ? 'Details' : 'Start Run',
                      style: const TextStyle(color: AppColors.voltCyan, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Expanded state
              if (_mockPreRunRoute.isEmpty) ...[
                const SizedBox(height: 8),
                const Text('Ready to run?', style: TextStyle(color: Colors.grey, fontSize: 14)),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _startCountdown,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.voltCyan,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('START FREE RUN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),

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
            Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _statCard('Distance', '${_distKm.toStringAsFixed(2)} km', AppColors.voltCyan, isDark)),
                    const SizedBox(width: 16),
                    Expanded(child: _statCard('Duration', _fmtDur(_durSecs), isDark ? Colors.white : Colors.black, isDark)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _statCard('Avg Pace', '${_fmtPace(_paceMin)} /km', AppColors.solarAmber, isDark)),
                    const SizedBox(width: 16),
                    Expanded(child: _statCard('Calories', '$_calories', AppColors.pulseRed, isDark)),
                  ],
                ),
              ],
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

  Widget _buildGuidedPhaseOverlay(bool isDark, ThemeData theme) {
    final currentPhase = _guidedPhases![_currentPhaseIndex];
    final nextPhase = _currentPhaseIndex < _guidedPhases!.length - 1
        ? _guidedPhases![_currentPhaseIndex + 1]
        : null;

    final currentPhaseSecs = currentPhase.durationMinutes * 60;
    final remainingSecs = (currentPhaseSecs - _phaseTimeElapsedSecs).clamp(0, currentPhaseSecs);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.voltCyan.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(currentPhase.icon, color: AppColors.voltCyan, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      currentPhase.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      nextPhase != null
                          ? 'Next: ${nextPhase.title} (${nextPhase.durationMinutes}m)'
                          : 'Final phase',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _fmtDur(remainingSecs),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.voltCyan,
                    ),
                  ),
                  const SizedBox(height: 2),
                  GestureDetector(
                    onTap: _skipGuidedPhase,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Skip', style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
                        SizedBox(width: 2),
                        Icon(LucideIcons.skipForward, size: 10, color: AppColors.textSecondary),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
