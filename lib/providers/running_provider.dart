import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class RunData {
  final int id;
  final String date;
  final double distance;
  final String duration;
  final String pace;
  final int calories;
  final String route;
  final List<RoutePoint> coordinates;

  RunData({
    required this.id,
    required this.date,
    required this.distance,
    required this.duration,
    required this.pace,
    required this.calories,
    required this.route,
    this.coordinates = const [],
  });
}

class RoutePoint {
  final double latitude;
  final double longitude;
  RoutePoint(this.latitude, this.longitude);
}

class RunningProvider extends ChangeNotifier {
  // ──── State ────
  bool isTracking = false;
  bool isPaused = false;
  double currentDistance = 0;
  int currentDuration = 0; // seconds
  String currentPace = '0:00';
  int currentCalories = 0;
  double currentSpeed = 0;

  // ──── GPS ────
  List<RoutePoint> routeCoordinates = [];
  RoutePoint? currentPosition;
  RoutePoint? startPosition;
  StreamSubscription<Position>? _positionSubscription;
  Timer? _durationTimer;
  bool hasLocationPermission = false;

  // ──── History ────
  List<RunData> history = [
    RunData(id: 1, date: '2026-05-03', distance: 5.2, duration: '28:45', pace: '5:32', calories: 320, route: 'Central Park Loop'),
    RunData(id: 2, date: '2026-05-01', distance: 8.1, duration: '45:20', pace: '5:36', calories: 510, route: 'Riverside Path'),
    RunData(id: 3, date: '2026-04-29', distance: 3.5, duration: '19:15', pace: '5:30', calories: 215, route: 'Neighborhood Run'),
    RunData(id: 4, date: '2026-04-27', distance: 10.0, duration: '56:40', pace: '5:40', calories: 640, route: 'Lake Circuit'),
    RunData(id: 5, date: '2026-04-25', distance: 6.3, duration: '34:50', pace: '5:32', calories: 395, route: 'Hill Training'),
  ];

  // ──── Personal Records ────
  final Map<String, String> personalRecords = {
    'Fastest 5K': '24:30',
    'Fastest 10K': '52:15',
    'Longest Run': '21.5 km',
    'Most Calories': '1,240 kcal',
  };

  final List<double> monthlyDistance = [32, 45, 38, 52, 41, 48, 55, 60, 42, 58, 50, 65];

  // ──── Location Service ────
  Future<bool> initLocationService() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) return false;

    hasLocationPermission = true;

    // Get initial position
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      currentPosition = RoutePoint(pos.latitude, pos.longitude);
      notifyListeners();
    } catch (_) {}

    return true;
  }

  // ──── Start Run ────
  Future<void> startRun() async {
    if (!hasLocationPermission) {
      final ok = await initLocationService();
      if (!ok) return;
    }

    isTracking = true;
    isPaused = false;
    currentDistance = 0;
    currentDuration = 0;
    currentPace = '0:00';
    currentCalories = 0;
    currentSpeed = 0;
    routeCoordinates = [];

    if (currentPosition != null) {
      startPosition = currentPosition;
      routeCoordinates.add(currentPosition!);
    }

    // Start GPS tracking
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 5, // Update every 5 meters
      ),
    ).listen(_onPositionUpdate);

    // Duration timer
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!isPaused) {
        currentDuration++;
        _calculateStats();
        notifyListeners();
      }
    });

    notifyListeners();
  }

  void _onPositionUpdate(Position position) {
    if (isPaused) return;

    final newPos = RoutePoint(position.latitude, position.longitude);

    // Calculate distance from last point
    if (routeCoordinates.isNotEmpty) {
      final last = routeCoordinates.last;
      final dist = Geolocator.distanceBetween(
        last.latitude, last.longitude,
        newPos.latitude, newPos.longitude,
      );
      currentDistance += dist / 1000; // Convert meters to km
    }

    currentPosition = newPos;
    routeCoordinates.add(newPos);
    currentSpeed = position.speed * 3.6; // m/s to km/h

    _calculateStats();
    notifyListeners();
  }

  void _calculateStats() {
    // Pace (min/km)
    if (currentDistance > 0.01) {
      final paceSeconds = currentDuration / currentDistance;
      final paceMin = (paceSeconds / 60).floor();
      final paceSec = (paceSeconds % 60).floor();
      currentPace = '$paceMin:${paceSec.toString().padLeft(2, '0')}';
    }

    // Calories (approx 62 kcal per km)
    currentCalories = (currentDistance * 62).floor();

    // Speed
    if (currentDuration > 0) {
      currentSpeed = currentDistance / (currentDuration / 3600);
    }
  }

  // ──── Pause/Resume ────
  void pauseRun() {
    isPaused = true;
    notifyListeners();
  }

  void resumeRun() {
    isPaused = false;
    notifyListeners();
  }

  // ──── Stop Run ────
  void stopRun() {
    _positionSubscription?.cancel();
    _durationTimer?.cancel();

    if (currentDistance > 0.01) {
      final mins = currentDuration ~/ 60;
      final secs = currentDuration % 60;
      history.insert(
        0,
        RunData(
          id: DateTime.now().millisecondsSinceEpoch,
          date: DateTime.now().toIso8601String().split('T')[0],
          distance: double.parse(currentDistance.toStringAsFixed(2)),
          duration: '$mins:${secs.toString().padLeft(2, '0')}',
          pace: currentPace,
          calories: currentCalories,
          route: 'GPS Run',
          coordinates: List.from(routeCoordinates),
        ),
      );
    }

    isTracking = false;
    isPaused = false;
    notifyListeners();
  }

  // ──── Reset ────
  void resetRun() {
    currentDistance = 0;
    currentDuration = 0;
    currentPace = '0:00';
    currentCalories = 0;
    currentSpeed = 0;
    routeCoordinates = [];
    startPosition = null;
    notifyListeners();
  }

  String formatDuration(int totalSecs) {
    final mins = totalSecs ~/ 60;
    final secs = totalSecs % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _durationTimer?.cancel();
    super.dispose();
  }
}
