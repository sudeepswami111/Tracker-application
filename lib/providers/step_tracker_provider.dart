import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_provider.dart';
import '../services/challenge_service.dart';
import '../services/health_step_service.dart';

class StepTrackerProvider extends ChangeNotifier with WidgetsBindingObserver {
  static const int _streakStepThreshold = 1000;
  bool _streakRecordedToday = false;
  AppProvider? _appProvider;

  void setAppProvider(AppProvider appProvider) {
    _appProvider = appProvider;
    if (_steps >= 0 && _appProvider?.steps != _steps) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _appProvider?.updateSteps(_steps);
      });
    }
  }

  late Stream<StepCount> _stepCountStream;
  late Stream<PedestrianStatus> _pedestrianStatusStream;
  StreamSubscription<StepCount>? _stepCountSub;
  StreamSubscription<PedestrianStatus>? _pedestrianStatusSub;

  int _steps = 0;
  String _status = 'stopped';
  bool _isAvailable = false;
  bool _permissionGranted = false;
  bool _isLoading = true;
  String _error = '';

  // Pref keys
  static const String _prefKeyInitialSteps = 'step_tracker_initialSteps';
  static const String _prefKeyLastKnownDeviceSteps = 'step_tracker_lastKnownDeviceSteps';
  static const String _prefKeyLastSavedDate = 'step_tracker_lastSavedDate';
  static const String _prefKeyCachedSteps = 'step_tracker_cachedSteps';

  int _initialStepsForDay = -1;
  int _lastKnownDeviceSteps = -1;
  String _lastSavedDate = '';
  int _lastChallengeUpdateSteps = 0;
  DateTime _lastNotifyTime = DateTime(2000);

  // Health Connect integration state
  final HealthStepService _healthService = HealthStepService();
  int? _lastHealthConnectSteps;
  int _pedometerBaseHardwareSteps = -1;

  int get steps => _steps;
  int get dailyGoal => _appProvider?.stepsGoal ?? 10000;
  String get status => _status;
  bool get isAvailable => _isAvailable;
  bool get permissionGranted => _permissionGranted;
  bool get isLoading => _isLoading;
  String get error => _error;

  double get progress => dailyGoal > 0 ? (_steps / dailyGoal).clamp(0.0, 1.0) : 0.0;
  int get calories => (_steps * 0.04).round(); // ~0.04 kcal per step
  double get distance => (_steps * 0.00078); // ~0.78 meters per step = 0.00078 km
  int get activeMinutes => (_steps / 100).round(); // ~100 steps per active minute

  Timer? _midnightTimer;
  Timer? _exactMidnightTimer;

  StepTrackerProvider() {
    _initPlatformState();
    WidgetsBinding.instance.addObserver(this);
    _startMidnightTimer();
    _scheduleExactMidnightReset();
  }

  void _startMidnightTimer() {
    _midnightTimer = Timer.periodic(const Duration(seconds: 30), (_) => _checkDayReset());
  }

  void _scheduleExactMidnightReset() {
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    final untilMidnight = nextMidnight.difference(now);

    _exactMidnightTimer?.cancel();
    _exactMidnightTimer = Timer(untilMidnight, () {
      if (kDebugMode) {
        print('[StepTracker] Exact midnight timer fired!');
      }
      _checkDayReset();
      _scheduleExactMidnightReset();
    });

    if (kDebugMode) {
      print('[StepTracker] Next midnight reset in ${untilMidnight.inSeconds}s');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkDayReset();
      refreshSteps(); // Sync background steps when returning to app
    }
  }

  String _todayStr() {
    return DateTime.now().toIso8601String().substring(0, 10);
  }

  void _checkDayReset() async {
    final todayStr = _todayStr();
    if (_lastSavedDate.isNotEmpty && _lastSavedDate != todayStr) {
      if (kDebugMode) {
        print('[StepTracker] Day changed: $_lastSavedDate -> $todayStr');
      }

      final prefs = await SharedPreferences.getInstance();
      _initialStepsForDay = -1;
      _pedometerBaseHardwareSteps = -1;
      _lastHealthConnectSteps = null;
      _lastSavedDate = todayStr;
      _streakRecordedToday = false;
      _steps = 0;

      await prefs.setString(_prefKeyLastSavedDate, _lastSavedDate);
      await prefs.setInt(_prefKeyInitialSteps, _initialStepsForDay);
      await prefs.setInt(_prefKeyCachedSteps, 0);

      if (_appProvider != null) {
        _appProvider!.updateSteps(0);
      }

      _safeNotifyListeners();
      refreshSteps();
    }
  }

  void _safeNotifyListeners() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  Future<void> _initPlatformState() async {
    _isLoading = true;
    _safeNotifyListeners();

    try {
      // 1. Request Activity Recognition permission
      PermissionStatus perm = await Permission.activityRecognition.request();
      _permissionGranted = perm.isGranted;

      // 2. Load cached values
      final prefs = await SharedPreferences.getInstance();
      _initialStepsForDay = prefs.getInt(_prefKeyInitialSteps) ?? -1;
      _lastKnownDeviceSteps = prefs.getInt(_prefKeyLastKnownDeviceSteps) ?? -1;
      _lastSavedDate = prefs.getString(_prefKeyLastSavedDate) ?? '';
      _steps = prefs.getInt(_prefKeyCachedSteps) ?? 0;

      final todayStr = _todayStr();
      if (_lastSavedDate.isNotEmpty && _lastSavedDate != todayStr) {
        _initialStepsForDay = -1;
        _pedometerBaseHardwareSteps = -1;
        _lastSavedDate = todayStr;
        _steps = 0;
        _streakRecordedToday = false;
        await prefs.setString(_prefKeyLastSavedDate, _lastSavedDate);
        await prefs.setInt(_prefKeyInitialSteps, _initialStepsForDay);
        await prefs.setInt(_prefKeyCachedSteps, 0);
      } else if (_lastSavedDate.isEmpty) {
        _lastSavedDate = todayStr;
        await prefs.setString(_prefKeyLastSavedDate, _lastSavedDate);
      }

      // 3. Query Health Connect for today's authoritative steps
      await _syncWithHealthConnect();

      // 4. Subscribe to Hardware Sensors as live fallback/ticker
      if (_permissionGranted) {
        try {
          _pedestrianStatusStream = Pedometer.pedestrianStatusStream;
          _pedestrianStatusSub = _pedestrianStatusStream.listen(
            onPedestrianStatusChanged,
            onError: onPedestrianStatusError,
          );

          _stepCountStream = Pedometer.stepCountStream;
          _stepCountSub = _stepCountStream.listen(
            onStepCount,
            onError: onStepCountError,
          );
          _isAvailable = true;
        } catch (e) {
          if (kDebugMode) print('[StepTracker] Hardware pedometer subscription error: $e');
        }
      }
    } catch (e) {
      _isAvailable = false;
      _error = "Step tracking error: $e";
      if (kDebugMode) print("[StepTracker] Error: $e");
    }

    _isLoading = false;
    _safeNotifyListeners();
  }

  /// Syncs with Health Connect to get the authoritative aggregated step count.
  Future<void> _syncWithHealthConnect() async {
    try {
      final hcSteps = await _healthService.fetchTodayAggregatedSteps();
      if (hcSteps != null && hcSteps >= 0) {
        _lastHealthConnectSteps = hcSteps;
        if (hcSteps >= _steps) {
          _steps = hcSteps;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt(_prefKeyCachedSteps, _steps);
          if (_appProvider != null) {
            _appProvider!.updateSteps(_steps);
          }
        }
      }

      // Run full audit log for debug comparison
      await _healthService.auditTodaySteps(
        hardwarePedometerSteps: (_lastKnownDeviceSteps >= 0 && _initialStepsForDay >= 0)
            ? (_lastKnownDeviceSteps - _initialStepsForDay).clamp(0, 999999)
            : 0,
        displayedSteps: _steps,
      );
    } catch (e) {
      if (kDebugMode) print('[StepTracker] Health Connect sync error: $e');
    }
  }

  /// Public refresh method called on pull-to-refresh or screen resume
  Future<void> refreshSteps() async {
    await _syncWithHealthConnect();
    _safeNotifyListeners();
  }

  void onStepCount(StepCount event) async {
    final todayStr = _todayStr();
    final prefs = await SharedPreferences.getInstance();

    // Day boundary check
    if (_lastSavedDate != todayStr) {
      _initialStepsForDay = event.steps;
      _pedometerBaseHardwareSteps = event.steps;
      _lastHealthConnectSteps = null;
      _lastSavedDate = todayStr;
      _streakRecordedToday = false;
      await prefs.setInt(_prefKeyInitialSteps, _initialStepsForDay);
      await prefs.setString(_prefKeyLastSavedDate, _lastSavedDate);
      _steps = 0;
    } else if (_initialStepsForDay == -1) {
      _initialStepsForDay = event.steps;
      _pedometerBaseHardwareSteps = event.steps;
      _lastSavedDate = todayStr;
      await prefs.setInt(_prefKeyInitialSteps, _initialStepsForDay);
      await prefs.setString(_prefKeyLastSavedDate, _lastSavedDate);
    }

    _lastKnownDeviceSteps = event.steps;
    await prefs.setInt(_prefKeyLastKnownDeviceSteps, _lastKnownDeviceSteps);

    // Compute hardware steps delta since app baseline
    if (_pedometerBaseHardwareSteps == -1) {
      _pedometerBaseHardwareSteps = event.steps;
    }
    int hardwareDelta = event.steps - _pedometerBaseHardwareSteps;
    if (hardwareDelta < 0) {
      // Device rebooted
      _pedometerBaseHardwareSteps = event.steps;
      hardwareDelta = 0;
    }

    // Determine final steps:
    // If Health Connect provided an authoritative base, add live hardware delta
    int calculatedSteps;
    if (_lastHealthConnectSteps != null && _lastHealthConnectSteps! > 0) {
      calculatedSteps = _lastHealthConnectSteps! + hardwareDelta;
    } else {
      calculatedSteps = event.steps - _initialStepsForDay;
      if (calculatedSteps < 0) {
        _initialStepsForDay = 0;
        calculatedSteps = event.steps;
      }
    }

    if (calculatedSteps > _steps) {
      _steps = calculatedSteps;
      await prefs.setInt(_prefKeyCachedSteps, _steps);
    }

    // Throttle UI notifications to max 1 per second
    final now = DateTime.now();
    if (now.difference(_lastNotifyTime).inMilliseconds >= 1000) {
      _lastNotifyTime = now;
      if (_appProvider != null) {
        _appProvider!.updateSteps(_steps);
      }

      // Challenge update (every 500 steps)
      if (_steps - _lastChallengeUpdateSteps >= 500) {
        _lastChallengeUpdateSteps = _steps;
        ChallengeService().updateStepsChallenges(_steps);
      }

      // Auto-record streak
      if (!_streakRecordedToday && _steps >= _streakStepThreshold && _appProvider != null) {
        _streakRecordedToday = true;
        _appProvider!.recordActivity();
      }

      _safeNotifyListeners();

      if (kDebugMode) {
        print('[StepTracker] Steps: $_steps (HC=${_lastHealthConnectSteps ?? 0}, HWDelta=$hardwareDelta, Event=${event.steps})');
      }
    }
  }

  void addManualSteps(int extraSteps) async {
    _steps += extraSteps;
    if (_initialStepsForDay != -1) {
      _initialStepsForDay -= extraSteps;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefKeyInitialSteps, _initialStepsForDay);
    await prefs.setInt(_prefKeyCachedSteps, _steps);
    if (_appProvider != null) {
      _appProvider!.updateSteps(_steps);
    }
    _safeNotifyListeners();
  }

  void onPedestrianStatusChanged(PedestrianStatus event) {
    _status = event.status;
    _safeNotifyListeners();
  }

  void onPedestrianStatusError(Object error) {
    if (kDebugMode) print('Pedestrian Status Error: $error');
    _status = 'unknown';
    _safeNotifyListeners();
  }

  void onStepCountError(Object error) {
    if (kDebugMode) print('Step Count Error: $error');
    _isAvailable = false;
    _error = "Step tracking not supported on this device";
    _safeNotifyListeners();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _midnightTimer?.cancel();
    _exactMidnightTimer?.cancel();
    _stepCountSub?.cancel();
    _pedestrianStatusSub?.cancel();
    super.dispose();
  }
}
