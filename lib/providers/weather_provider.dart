import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/weather_model.dart';
import '../services/weather_service.dart';

class WeatherProvider extends ChangeNotifier {
  WeatherModel? _weather;
  bool _isLoading = false;
  StreamSubscription<Position>? _positionStream;

  WeatherModel? get weather => _weather;
  bool get isLoading => _isLoading;

  WeatherProvider() {
    fetchWeather();
    _startLocationStream();
  }

  Future<void> fetchWeather() async {
    _isLoading = true;
    notifyListeners();

    _weather = await WeatherService.getWeather();
    
    _isLoading = false;
    notifyListeners();
  }

  void _startLocationStream() async {
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.whileInUse || perm == LocationPermission.always) {
      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 1000,
        ),
      ).listen((Position position) async {
        final prefs = await SharedPreferences.getInstance();
        final lastLat = prefs.getDouble('last_lat');
        final lastLon = prefs.getDouble('last_lon');

        if (lastLat != null && lastLon != null) {
          final distance = Geolocator.distanceBetween(lastLat, lastLon, position.latitude, position.longitude);
          if (distance > 5000) { // 5km
            fetchWeather();
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }
}
