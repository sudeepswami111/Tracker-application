import 'package:flutter/material.dart';
import '../models/weather_model.dart';
import '../services/weather_service.dart';

enum WeatherStatus { idle, loading, loaded, error }

class WeatherProvider extends ChangeNotifier {
  WeatherData? _data;
  WeatherStatus _status = WeatherStatus.idle;
  String _errorMsg = '';

  WeatherData? get data => _data;
  WeatherStatus get status => _status;
  String get errorMsg => _errorMsg;
  bool get isLoading => _status == WeatherStatus.loading;
  bool get hasData => _data != null;

  WeatherProvider() {
    fetch();
  }

  Future<void> fetch() async {
    if (_status == WeatherStatus.loading) return;
    _status = WeatherStatus.loading;
    notifyListeners();

    try {
      final result = await WeatherService.getWeather();
      if (result != null) {
        _data = result;
        _status = WeatherStatus.loaded;
      } else {
        _errorMsg = 'Unable to fetch weather';
        _status = WeatherStatus.error;
      }
    } catch (e) {
      _errorMsg = e.toString();
      _status = WeatherStatus.error;
    }

    notifyListeners();
  }
}
