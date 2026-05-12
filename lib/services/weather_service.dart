import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import '../models/weather_model.dart';

class WeatherService {
  static const _hiveBox = 'weather_cache';
  static const _cacheKey = 'weather_data';

  /// Fetch weather — returns cached data if fresh, else re-fetches from Open-Meteo.
  static Future<WeatherData?> getWeather() async {
    try {
      // 1. Check Hive cache first
      final cached = _readCache();
      if (cached != null && !cached.isStale) return cached;

      // 2. Get GPS coords
      final position = await _getPosition();
      if (position == null) return cached; // Fallback to stale cache

      // 3. Fetch from Open-Meteo (free, no API key)
      final data = await _fetchFromApi(position.latitude, position.longitude);
      if (data != null) _writeCache(data);
      return data ?? cached;
    } catch (e) {
      debugPrint('[WeatherService] Error: $e');
      return _readCache(); // always fall back to cache on error
    }
  }

  static Future<Position?> _getPosition() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever ||
          perm == LocationPermission.denied) return null;

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
      );
    } catch (_) {
      return null;
    }
  }

  static Future<WeatherData?> _fetchFromApi(double lat, double lon) async {
    final uri = Uri.parse(
      'https://api.open-meteo.com/v1/forecast'
      '?latitude=$lat&longitude=$lon'
      '&current=temperature_2m,weather_code,wind_speed_10m,relative_humidity_2m,uv_index,precipitation'
      '&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_sum'
      '&timezone=auto'
      '&forecast_days=7',
    );

    final response = await http.get(uri).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) return null;

    final json = jsonDecode(response.body) as Map<String, dynamic>;

    final cur = json['current'] as Map<String, dynamic>;
    final curUnits = json['current_units'] as Map<String, dynamic>? ?? {};

    final daily = json['daily'] as Map<String, dynamic>;
    final dates = daily['time'] as List<dynamic>;
    final codeList = daily['weather_code'] as List<dynamic>;
    final maxList = daily['temperature_2m_max'] as List<dynamic>;
    final minList = daily['temperature_2m_min'] as List<dynamic>;
    final precipList = daily['precipitation_sum'] as List<dynamic>;

    final forecast = List.generate(
      dates.length,
      (i) => DayForecast(
        date: dates[i] as String,
        tempMax: (maxList[i] as num?)?.toDouble() ?? 0,
        tempMin: (minList[i] as num?)?.toDouble() ?? 0,
        weatherCode: (codeList[i] as num?)?.toInt() ?? 0,
        precipitation: (precipList[i] as num?)?.toDouble() ?? 0,
      ),
    );

    final current = WeatherCondition(
      tempC: (cur['temperature_2m'] as num?)?.toDouble() ?? 0,
      tempMax: forecast.isNotEmpty ? forecast[0].tempMax : 0,
      tempMin: forecast.isNotEmpty ? forecast[0].tempMin : 0,
      weatherCode: (cur['weather_code'] as num?)?.toInt() ?? 0,
      windSpeedKmh: (cur['wind_speed_10m'] as num?)?.toDouble() ?? 0,
      uvIndex: (cur['uv_index'] as num?)?.toInt() ?? 0,
      humidity: (cur['relative_humidity_2m'] as num?)?.toInt() ?? 0,
      precipitation: (cur['precipitation'] as num?)?.toDouble() ?? 0,
    );

    return WeatherData(
      current: current,
      forecast: forecast,
      fetchedAt: DateTime.now(),
      lat: lat,
      lon: lon,
    );
  }

  static WeatherData? _readCache() {
    try {
      final box = Hive.box(_hiveBox);
      final raw = box.get(_cacheKey) as String?;
      if (raw == null) return null;
      return WeatherData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static void _writeCache(WeatherData data) {
    try {
      final box = Hive.box(_hiveBox);
      box.put(_cacheKey, jsonEncode(data.toJson()));
    } catch (_) {}
  }

  /// Opens the Hive box — call once at startup before using the service.
  static Future<void> init() async {
    await Hive.openBox(_hiveBox);
  }
}
