import 'package:flutter/material.dart';
import '../models/weather_model.dart';
import '../services/weather_service.dart';

class WeatherProvider extends ChangeNotifier {
  WeatherModel? _weather;
  bool _isLoading = false;

  WeatherModel? get weather => _weather;
  bool get isLoading => _isLoading;

  WeatherProvider() {
    fetchWeather();
  }

  Future<void> fetchWeather() async {
    _isLoading = true;
    notifyListeners();

    _weather = await WeatherService.getWeather();
    
    _isLoading = false;
    notifyListeners();
  }
}
