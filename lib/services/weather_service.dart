import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import 'package:geolocator/geolocator.dart';
import '../models/weather_model.dart';

class WeatherService {
  static const String _boxName = 'weatherBox';
  static const String _cacheKey = 'weatherCache';
  static const int _ttlMinutes = 30;

  static Future<WeatherModel?> getWeather() async {
    try {
      final box = await Hive.openBox(_boxName);
      
      // 1. Check Cache with TTL
      final cachedData = box.get(_cacheKey);
      if (cachedData != null) {
        try {
          final map = Map<String, dynamic>.from(cachedData);
          final weather = WeatherModel.fromJson(map);
          if (DateTime.now().difference(weather.lastFetched).inMinutes < _ttlMinutes) {
            return weather;
          }
        } catch (e) {
          // Cache invalid
        }
      }

      // 2. Get Location
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever || perm == LocationPermission.denied) {
        return null;
      }
      
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.low,
            timeLimit: Duration(seconds: 5),
          ),
        );
      } catch (_) {
        position = await Geolocator.getLastKnownPosition();
      }

      // Default to New York if absolutely no location can be found
      final lat = position?.latitude ?? 40.7128;
      final lon = position?.longitude ?? -74.0060;

      // 3. Fetch from Open-Meteo
      final url = Uri.parse(
          'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon'
          '&current=temperature_2m,weather_code,wind_speed_10m'
          '&hourly=temperature_2m,weather_code,uv_index'
          '&daily=weather_code,temperature_2m_max,temperature_2m_min'
          '&timezone=auto'
      );
      final response = await http.get(url);
      if (response.statusCode != 200) throw Exception('Failed to fetch weather');
      final data = jsonDecode(response.body);

      // 4. Fetch AQI
      final aqiUrl = Uri.parse(
          'https://air-quality-api.open-meteo.com/v1/air-quality?latitude=$lat&longitude=$lon'
          '&current=european_aqi'
      );
      int aqi = 50; // Default if fails
      try {
        final aqiRes = await http.get(aqiUrl);
        if (aqiRes.statusCode == 200) {
          final aqiData = jsonDecode(aqiRes.body);
          aqi = (aqiData['current']['european_aqi'] as num).toInt();
        }
      } catch (_) {}

      // 5. Parse Data
      final current = data['current'];
      final hourly = data['hourly'];
      final daily = data['daily'];

      List<HourlyForecast> hourlyList = [];
      for (int i = 0; i < 24; i++) { // Get next 24 hours
        hourlyList.add(HourlyForecast(
          time: DateTime.parse(hourly['time'][i]),
          temp: (hourly['temperature_2m'][i] as num).toDouble(),
          weatherCode: hourly['weather_code'][i] as int,
          uvIndex: (hourly['uv_index'][i] as num?)?.toDouble() ?? 0.0,
        ));
      }

      List<DailyForecast> dailyList = [];
      for (int i = 0; i < 7; i++) { // Get next 7 days
        dailyList.add(DailyForecast(
          date: DateTime.parse(daily['time'][i]),
          maxTemp: (daily['temperature_2m_max'][i] as num).toDouble(),
          minTemp: (daily['temperature_2m_min'][i] as num).toDouble(),
          weatherCode: daily['weather_code'][i] as int,
        ));
      }

      final weatherModel = WeatherModel(
        currentTemp: (current['temperature_2m'] as num).toDouble(),
        weatherCode: current['weather_code'] as int,
        windSpeed: (current['wind_speed_10m'] as num).toDouble(),
        aqi: aqi,
        uvIndex: hourlyList.isNotEmpty ? hourlyList.first.uvIndex : 0.0,
        hourly: hourlyList,
        daily: dailyList,
        lastFetched: DateTime.now(),
      );

      // 6. Cache Data
      await box.put(_cacheKey, weatherModel.toJson());
      
      return weatherModel;
    } catch (e) {
      debugPrint('Weather fetch error: $e');
      return null; // Return null if fetching fails
    }
  }
}
