import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_provider.dart';

class StepTrackerProvider extends ChangeNotifier with WidgetsBindingObserver {
  static const int _streakStepThreshold = 1000; // Change this value if needed
  bool _streakRecordedToday = false;
  AppProvider? _appProvider;

  void setAppProvider(AppProvider appProvider) {
    _appProvider = appProvider;
  }

  late Stream<StepCount> _stepCountStream;
  late Stream<PedestrianStatus> _pedestrianStatusStream;
  StreamSubscription<StepCount>? _stepCountSub;
  StreamSubscription<PedestrianStatus>? _pedestrianStatusSub;

  int _steps = 0;
  final int _dailyGoal = 10000;
  String _status = 'stopped';
  bool _isAvailable = false;
  bool _permissionGranted = false;
  bool _isLoading = true;
  String _error = '';

  // Use UNIQUE pref keys to avoid collision with AppProvider's 'lastSavedDate'
  static const String _prefKeyInitialSteps = 'step_tracker_initialSteps';
  static const String _prefKeyLastKnownDeviceSteps = 'step_tracker_lastKnownDeviceSteps';
  static const String _prefKeyLastSavedDate = 'step_tracker_lastSavedDate';

  int _initialStepsForDay = -1;
  int _lastKnownDeviceSteps = -1;
  String _lastSavedDate = '';

  int get steps => _steps;
  int get dailyGoal => _dailyGoal;
  String get status => _status;
  bool get isAvailable => _isAvailable;
  bool get permissionGranted => _permissionGranted;
  bool get isLoading => _isLoading;
  String get error => _error;

  double get progress => _dailyGoal > 0 ? (_steps / _dailyGoal).clamp(0.0, 1.0) : 0.0;
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
    // Safety net: check every 30 seconds
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
      // Re-arm for next midnight
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
    }
  }

  /// Returns today's date as "yyyy-MM-dd"
  String _todayStr() {
    return DateTime.now().toIso8601String().substring(0, 10);
  }

  /// Called periodically and on app resume to detect day boundary crossings.
  void _checkDayReset() async {
    final todayStr = _todayStr();
    if (_lastSavedDate.isNotEmpty && _lastSavedDate != todayStr) {
      if (kDebugMode) {
        print('[StepTracker] Day changed: $_lastSavedDate -> $todayStr');
        print('[StepTracker] Setting baseline to lastKnownDeviceSteps=$_lastKnownDeviceSteps');
      }

      final prefs = await SharedPreferences.getInstance();

      // Set the new baseline to wherever the hardware counter was at end of yesterday
      if (_lastKnownDeviceSteps > 0) {
        _initialStepsForDay = _lastKnownDeviceSteps;
      }
      // If _lastKnownDeviceSteps is still -1 (no events ever), we'll set
      // the baseline from the first onStepCount event of the new day.

      _lastSavedDate = todayStr;
      _streakRecordedToday = false;
      _steps = 0;

      await prefs.setString(_prefKeyLastSavedDate, _lastSavedDate);
      await prefs.setInt(_prefKeyInitialSteps, _initialStepsForDay);

      if (kDebugMode) {
        print('[StepTracker] Reset complete. steps=$_steps, baseline=$_initialStepsForDay');
      }

      notifyListeners();
    }
  }

  Future<void> _initPlatformState() async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Request Permission
      PermissionStatus perm = await Permission.activityRecognition.request();
      if (perm.isGranted) {
        _permissionGranted = true;

        // 2. Load cached values using UNIQUE pref keys
        final prefs = await SharedPreferences.getInstance();

        // ── One-time FORCE RESET (v2) ──
        // Wipe all stale step data so baseline is recalculated fresh.
        // This runs once, then sets a flag so it never runs again.
        const resetFlag = 'step_tracker_reset_v2';
        if (!prefs.containsKey(resetFlag)) {
          // Clear ALL step tracker keys (old and new)
          await prefs.remove('initialSteps');
          await prefs.remove('lastKnownDeviceSteps');
          await prefs.remove(_prefKeyInitialSteps);
          await prefs.remove(_prefKeyLastKnownDeviceSteps);
          await prefs.remove(_prefKeyLastSavedDate);
          await prefs.setBool(resetFlag, true);
          if (kDebugMode) {
            print('[StepTracker] Force reset v2: cleared all stale step data');
          }
        }

        _initialStepsForDay = prefs.getInt(_prefKeyInitialSteps) ?? -1;
        _lastKnownDeviceSteps = prefs.getInt(_prefKeyLastKnownDeviceSteps) ?? -1;
        _lastSavedDate = prefs.getString(_prefKeyLastSavedDate) ?? '';

        if (kDebugMode) {
          print('[StepTracker] Init: lastSavedDate=$_lastSavedDate, '
              'initialSteps=$_initialStepsForDay, '
              'lastKnownDeviceSteps=$_lastKnownDeviceSteps');
        }

        final todayStr = _todayStr();

        if (_lastSavedDate.isNotEmpty && _lastSavedDate != todayStr) {
          // Day changed while app was closed.
          // Baseline = yesterday's last known device steps.
          if (_lastKnownDeviceSteps > 0) {
            _initialStepsForDay = _lastKnownDeviceSteps;
          }
          _lastSavedDate = todayStr;
          _steps = 0;
          _streakRecordedToday = false;
          await prefs.setString(_prefKeyLastSavedDate, _lastSavedDate);
          await prefs.setInt(_prefKeyInitialSteps, _initialStepsForDay);

          if (kDebugMode) {
            print('[StepTracker] Day changed during offline. Reset steps to 0, '
                'new baseline=$_initialStepsForDay');
          }
        } else if (_lastSavedDate == todayStr) {
          // Same day — reconstruct today's step count from saved state
          if (_initialStepsForDay >= 0 && _lastKnownDeviceSteps >= 0) {
            _steps = (_lastKnownDeviceSteps - _initialStepsForDay).clamp(0, 999999);
          }
          if (kDebugMode) {
            print('[StepTracker] Same day resume. '
                'steps=$_steps (=$_lastKnownDeviceSteps - $_initialStepsForDay)');
          }
        } else {
          // First launch ever — _lastSavedDate is empty
          _lastSavedDate = todayStr;
          await prefs.setString(_prefKeyLastSavedDate, _lastSavedDate);
          if (kDebugMode) {
            print('[StepTracker] First launch. Will set baseline on first step event.');
          }
        }

        // 3. Subscribe to Sensors
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
      } else {
        _permissionGranted = false;
        _error = "Permission denied";
      }
    } catch (e) {
      _isAvailable = false;
      _error = "Step tracking not supported on this device";
      if (kDebugMode) print("Pedometer error: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

  void onStepCount(StepCount event) async {
    final todayStr = _todayStr();
    final prefs = await SharedPreferences.getInstance();

    // ─── Day boundary check (redundant safety net) ───
    if (_lastSavedDate != todayStr) {
      if (kDebugMode) {
        print('[StepTracker] onStepCount detected day change: $_lastSavedDate -> $todayStr');
      }
      // Set baseline to PREVIOUS last known steps (end of yesterday)
      if (_lastSavedDate.isNotEmpty && _lastKnownDeviceSteps > 0) {
        _initialStepsForDay = _lastKnownDeviceSteps;
      } else {
        // No previous data at all — use current event as baseline
        _initialStepsForDay = event.steps;
      }
      _lastSavedDate = todayStr;
      _streakRecordedToday = false;
      await prefs.setInt(_prefKeyInitialSteps, _initialStepsForDay);
      await prefs.setString(_prefKeyLastSavedDate, _lastSavedDate);
    } else if (_initialStepsForDay == -1) {
      // First step event ever for this day — set baseline
      _initialStepsForDay = event.steps;
      _lastSavedDate = todayStr;
      await prefs.setInt(_prefKeyInitialSteps, _initialStepsForDay);
      await prefs.setString(_prefKeyLastSavedDate, _lastSavedDate);
      if (kDebugMode) {
        print('[StepTracker] First event baseline set: $_initialStepsForDay');
      }
    }

    // ─── Always update last known device steps ───
    _lastKnownDeviceSteps = event.steps;
    await prefs.setInt(_prefKeyLastKnownDeviceSteps, _lastKnownDeviceSteps);

    // ─── Calculate today's steps ───
    int currentSteps = event.steps - _initialStepsForDay;
    if (currentSteps < 0) {
      // Device rebooted — hardware counter reset to near-zero
      _initialStepsForDay = 0;
      currentSteps = event.steps;
      await prefs.setInt(_prefKeyInitialSteps, 0);
      if (kDebugMode) {
        print('[StepTracker] Device reboot detected. Reset baseline to 0.');
      }
    }

    _steps = currentSteps;

    // Auto-validate streak when step threshold is crossed
    if (!_streakRecordedToday && _steps >= _streakStepThreshold && _appProvider != null) {
      _streakRecordedToday = true;
      _appProvider!.recordActivity();
      if (kDebugMode) print('[StepTracker] Streak recorded via steps: $_steps');
    }

    notifyListeners();

    if (kDebugMode) {
      print('[StepTracker] Steps: $_steps (event=${event.steps}, baseline=$_initialStepsForDay)');
    }
  }

  void onPedestrianStatusChanged(PedestrianStatus event) {
    _status = event.status;
    notifyListeners();
  }

  void onPedestrianStatusError(Object error) {
    if (kDebugMode) print('Pedestrian Status Error: $error');
    _status = 'unknown';
    notifyListeners();
  }

  void onStepCountError(Object error) {
    if (kDebugMode) print('Step Count Error: $error');
    _isAvailable = false;
    _error = "Step tracking not supported on this device";
    notifyListeners();
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
