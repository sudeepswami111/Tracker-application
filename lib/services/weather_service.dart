import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/weather_model.dart';

/// WeatherService — powered by Open-Meteo (free, no API key required).
/// AQI is calculated using the Indian National Air Quality Index (NAQI)
/// from PM2.5 and PM10 readings fetched from the Open-Meteo Air Quality API.
class WeatherService {
  static const String _boxName = 'weatherBox';
  static const String _cacheKey = 'weatherCacheV2';
  static const int _ttlMinutes = 30;

  static Future<WeatherModel?> getWeather({bool forceRefresh = false}) async {
    try {
      final box = await Hive.openBox(_boxName);
      final prefs = await SharedPreferences.getInstance();

      // 1. Check Cache with TTL
      final cachedData = box.get(_cacheKey);
      if (cachedData != null && !forceRefresh) {
        try {
          final map = Map<String, dynamic>.from(cachedData);
          final weather = WeatherModel.fromJson(map);
          if (DateTime.now().difference(weather.lastFetched).inMinutes < _ttlMinutes) {
            return weather;
          }
        } catch (_) {
          // Cache invalid — re-fetch
        }
      }

      // 2. Get Location
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever || perm == LocationPermission.denied) {
        throw Exception('LocationPermissionDenied');
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
        try {
          position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.low,
              timeLimit: Duration(seconds: 10),
            ),
          );
        } catch (_) {
          position = await Geolocator.getLastKnownPosition();
        }
      }

      double lat;
      double lon;

      if (position != null) {
        lat = position.latitude;
        lon = position.longitude;
        await prefs.setDouble('last_lat', lat);
        await prefs.setDouble('last_lon', lon);
      } else {
        lat = prefs.getDouble('last_lat') ?? 0.0;
        lon = prefs.getDouble('last_lon') ?? 0.0;
        if (lat == 0.0 && lon == 0.0) throw Exception('LocationTimeout');
      }

      // 3. Phase 2D — Reverse Geocoding with subLocality priority
      String cityName = 'Unknown Location';
      try {
        final placemarks = await placemarkFromCoordinates(lat, lon);
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          // Prefer the most granular recognizable name
          final sub = p.subLocality?.trim();
          final loc = p.locality?.trim();
          final subAdmin = p.subAdministrativeArea?.trim();
          final admin = p.administrativeArea?.trim();

          final name = (sub != null && sub.isNotEmpty)
              ? sub
              : (loc != null && loc.isNotEmpty)
                  ? loc
                  : (subAdmin != null && subAdmin.isNotEmpty)
                      ? subAdmin
                      : (admin ?? 'Unknown Location');

          if (admin != null && admin.isNotEmpty && name != admin) {
            cityName = '$name, $admin';
          } else {
            cityName = name;
          }
        }
      } catch (_) {}

      // 4. Fetch Weather from Open-Meteo
      final weatherUrl = Uri.parse(
        'https://api.open-meteo.com/v1/forecast'
        '?latitude=$lat&longitude=$lon'
        '&current=temperature_2m,weather_code,wind_speed_10m,relative_humidity_2m,is_day'
        '&hourly=temperature_2m,apparent_temperature,weather_code,precipitation_probability,wind_speed_10m,relative_humidity_2m,uv_index'
        '&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max,uv_index_max,sunrise,sunset'
        '&timezone=auto',
      );
      final weatherResponse = await http.get(weatherUrl);
      if (weatherResponse.statusCode != 200) {
        throw Exception('Open-Meteo weather fetch failed: ${weatherResponse.statusCode}');
      }
      final data = jsonDecode(weatherResponse.body) as Map<String, dynamic>;

      // 5. Fetch AQI from Open-Meteo Air Quality API
      int aqi = 50;
      try {
        final aqiUrl = Uri.parse(
          'https://air-quality-api.open-meteo.com/v1/air-quality'
          '?latitude=$lat&longitude=$lon&current=pm10,pm2_5',
        );
        final aqiRes = await http.get(aqiUrl);
        if (aqiRes.statusCode == 200) {
          final aqiData = jsonDecode(aqiRes.body) as Map<String, dynamic>;
          if (aqiData['current'] != null) {
            final pm25 = (aqiData['current']['pm2_5'] as num?)?.toDouble() ?? 0.0;
            final pm10 = (aqiData['current']['pm10'] as num?)?.toDouble() ?? 0.0;
            aqi = _calculateIndianAqi(pm25, pm10);
          }
        }
      } catch (_) {}

      // 6. Parse Current
      final current = data['current'] as Map<String, dynamic>;
      final hourlyRaw = data['hourly'] as Map<String, dynamic>;
      final dailyRaw = data['daily'] as Map<String, dynamic>;

      final currentTemp = (current['temperature_2m'] as num).toDouble();
      final currentHumidity = (current['relative_humidity_2m'] as num?)?.toDouble() ?? 50.0;
      final windSpeed = (current['wind_speed_10m'] as num).toDouble();
      final isDay = (current['is_day'] as int?) == 1;
      final currentWeatherCode = current['weather_code'] as int;

      // Phase 2B — Hazy condition label when sky is clear but AQI is bad
      String conditionText = _getConditionFromCode(currentWeatherCode);
      if ((currentWeatherCode == 0 || currentWeatherCode == 1) && aqi > 100) {
        conditionText = aqi > 150 ? 'Hazy' : 'Clear but Hazy';
      }

      // 7. Phase 2C — Hourly forecast starting from current hour (not midnight index 0)
      final List<String> hourlyTimes = List<String>.from(hourlyRaw['time'] as List);
      final now = DateTime.now();
      final currentHourStr =
          '${now.year.toString().padLeft(4, '0')}-'
          '${now.month.toString().padLeft(2, '0')}-'
          '${now.day.toString().padLeft(2, '0')}T'
          '${now.hour.toString().padLeft(2, '0')}:00';
      int startIdx = hourlyTimes.indexWhere((t) => t == currentHourStr);
      if (startIdx == -1) {
        // Fallback: find first time >= now
        startIdx = hourlyTimes.indexWhere(
          (t) => !DateTime.parse(t).isBefore(DateTime(now.year, now.month, now.day, now.hour)),
        );
      }
      if (startIdx == -1) startIdx = 0;

      final List<HourlyForecast> hourlyList = [];
      for (int i = startIdx; i < startIdx + 24 && i < hourlyTimes.length; i++) {
        hourlyList.add(HourlyForecast(
          time: DateTime.parse(hourlyTimes[i]),
          temp: (hourlyRaw['temperature_2m'][i] as num).toDouble(),
          weatherCode: hourlyRaw['weather_code'][i] as int,
          conditionText: _getConditionFromCode(hourlyRaw['weather_code'][i] as int),
          uvIndex: (hourlyRaw['uv_index'][i] as num?)?.toDouble() ?? 0.0,
          precipitationProbability:
              (hourlyRaw['precipitation_probability'][i] as num?)?.toDouble() ?? 0.0,
        ));
      }

      // 8. Daily Forecast
      final List<DailyForecast> dailyList = [];
      final List dailyTimes = dailyRaw['time'] as List;
      for (int i = 0; i < dailyTimes.length && i < 7; i++) {
        int code = dailyRaw['weather_code'][i] as int;
        final popMax = (dailyRaw['precipitation_probability_max'][i] as num?)?.toDouble() ?? 0.0;
        
        // Safeguard against Open-Meteo dry Thunderstorm glitch
        if ((code == 95 || code == 96 || code == 99) && popMax < 10) {
          code = 1; // Mainly Clear
        }

        dailyList.add(DailyForecast(
          date: DateTime.parse(dailyTimes[i] as String),
          maxTemp: (dailyRaw['temperature_2m_max'][i] as num).toDouble(),
          minTemp: (dailyRaw['temperature_2m_min'][i] as num).toDouble(),
          precipitationProbabilityMax: popMax,
          uvIndexMax: (dailyRaw['uv_index_max'][i] as num?)?.toDouble() ?? 0.0,
          sunrise: dailyRaw['sunrise'][i] as String? ?? '',
          sunset: dailyRaw['sunset'][i] as String? ?? '',
          weatherCode: code,
          conditionText: _getConditionFromCode(code),
        ));
      }

      // 9. Dynamic Fitness Insights
      String bestTimeStr = 'Anytime';
      String intensityStr = 'Moderate';
      String hydrationStr = 'Normal | Drink 250ml/hr';

      HourlyForecast? bestHour;
      for (final h in hourlyList) {
        if (h.time.hour >= 5 && h.time.hour <= 21 && h.precipitationProbability < 20) {
          if (bestHour == null || h.temp < bestHour.temp) bestHour = h;
        }
      }

      if (bestHour != null) {
        final hr = bestHour.time.hour;
        final period = hr >= 12 ? 'PM' : 'AM';
        final displayHr = hr > 12 ? hr - 12 : (hr == 0 ? 12 : hr);
        bestTimeStr = '$displayHr:00 $period';
        if (bestHour.temp < 25) {
          intensityStr = 'High';
        } else if (bestHour.temp <= 32) {
          intensityStr = 'Moderate';
        } else {
          intensityStr = 'Low (avoid intense exercise)';
        }
      }

      if (currentTemp > 35 || currentHumidity > 70) {
        hydrationStr = 'High Risk | Drink 500ml/hr';
      } else if (currentTemp >= 28 && currentTemp <= 35) {
        hydrationStr = 'Moderate | Drink 350ml/hr';
      }

      final weatherModel = WeatherModel(
        currentTemp: currentTemp,
        weatherCode: currentWeatherCode,
        conditionText: conditionText,
        windSpeed: windSpeed,
        aqi: aqi,
        uvIndex: hourlyList.isNotEmpty ? hourlyList.first.uvIndex : 0.0,
        hourly: hourlyList,
        daily: dailyList,
        lastFetched: DateTime.now(),
        cityName: cityName,
        bestTime: bestTimeStr,
        intensity: intensityStr,
        hydration: hydrationStr,
        isDay: isDay,
      );

      await box.put(_cacheKey, weatherModel.toJson());
      return weatherModel;
    } catch (e) {
      debugPrint('Weather fetch error: $e');
      if (e.toString().contains('LocationPermissionDenied')) {
        throw Exception('LocationPermissionDenied');
      }
      if (e.toString().contains('LocationTimeout')) {
        throw Exception('LocationTimeout');
      }
      return null;
    }
  }

  /// Open-Meteo WMO weather code → human-readable label.
  static String _getConditionFromCode(int code) {
    if (code == 0) return 'Clear Sky';
    if (code == 1) return 'Mainly Clear';
    if (code == 2) return 'Partly Cloudy';
    if (code == 3) return 'Overcast';
    if (code == 45 || code == 48) return 'Foggy';
    if (code == 51 || code == 53 || code == 55) return 'Drizzle';
    if (code == 61 || code == 63 || code == 65) return 'Rain';
    if (code == 71 || code == 73 || code == 75) return 'Snow';
    if (code == 80 || code == 81 || code == 82) return 'Rain Showers';
    if (code == 95 || code == 96 || code == 99) return 'Thunderstorm';
    return 'Unknown';
  }

  /// Indian National Air Quality Index from PM2.5 and PM10 breakpoints.
  static int _calculateIndianAqi(double pm25, double pm10) {
    int getSubIndex(double c, List<double> bp, List<int> i) {
      for (int k = 0; k < bp.length - 1; k++) {
        if (c >= bp[k] && c <= bp[k + 1]) {
          return (((i[k + 1] - i[k]) / (bp[k + 1] - bp[k])) * (c - bp[k]) + i[k]).round();
        }
      }
      if (c > bp.last) return 500;
      return 0;
    }

    final ipm25 =
        getSubIndex(pm25, [0, 30, 60, 90, 120, 250], [0, 50, 100, 200, 300, 400, 500]);
    final ipm10 =
        getSubIndex(pm10, [0, 50, 100, 250, 350, 430], [0, 50, 100, 200, 300, 400, 500]);
    return ipm25 > ipm10 ? ipm25 : ipm10;
  }
}
