import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StepTrackerProvider extends ChangeNotifier {
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

  int _initialStepsForDay = -1;
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

  StepTrackerProvider() {
    _initPlatformState();
  }

  Future<void> _initPlatformState() async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Request Permission
      PermissionStatus perm = await Permission.activityRecognition.request();
      if (perm.isGranted) {
        _permissionGranted = true;

        // 2. Load cached initial steps
        final prefs = await SharedPreferences.getInstance();
        _initialStepsForDay = prefs.getInt('initialSteps') ?? -1;
        _lastSavedDate = prefs.getString('lastSavedDate') ?? '';
        
        final todayStr = DateTime.now().toIso8601String().substring(0, 10);
        if (_lastSavedDate != todayStr) {
          _initialStepsForDay = -1; // Reset for new day
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
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    final prefs = await SharedPreferences.getInstance();

    if (_initialStepsForDay == -1 || _lastSavedDate != todayStr) {
      _initialStepsForDay = event.steps;
      _lastSavedDate = todayStr;
      await prefs.setInt('initialSteps', _initialStepsForDay);
      await prefs.setString('lastSavedDate', _lastSavedDate);
    }

    int currentSteps = event.steps - _initialStepsForDay;
    if (currentSteps < 0) {
      // Device rebooted, steps reset to 0
      _initialStepsForDay = 0;
      currentSteps = event.steps;
      await prefs.setInt('initialSteps', 0);
    }

    _steps = currentSteps;
    notifyListeners();
    
    if (kDebugMode) print('Live steps updated: $_steps');
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
    _stepCountSub?.cancel();
    _pedestrianStatusSub?.cancel();
    super.dispose();
  }
}
