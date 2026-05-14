import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/weather_model.dart';

class WeatherService {
  static const String _boxName = 'weatherBox';
  static const String _cacheKey = 'weatherCache';
  static const int _ttlMinutes = 30;

  static Future<WeatherModel?> getWeather() async {
    try {
      final box = await Hive.openBox(_boxName);
      
      final prefs = await SharedPreferences.getInstance();

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
          // Retry once with slightly longer timeout
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
        if (lat == 0.0 && lon == 0.0) {
          throw Exception('LocationTimeout');
        }
      }

      // Reverse geocoding
      String cityName = "Unknown Location";
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(lat, lon);
        if (placemarks.isNotEmpty) {
          if (placemarks.first.locality != null && placemarks.first.administrativeArea != null) {
             cityName = "${placemarks.first.locality}, ${placemarks.first.administrativeArea}";
          } else {
             cityName = placemarks.first.locality ?? placemarks.first.subAdministrativeArea ?? placemarks.first.administrativeArea ?? "Unknown Location";
          }
        }
      } catch (_) {}

      // 3. Fetch from Open-Meteo
      final url = Uri.parse(
          'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon'
          '&current=temperature_2m,weather_code,wind_speed_10m,relative_humidity_2m,is_day'
          '&hourly=temperature_2m,weather_code,uv_index,precipitation_probability'
          '&daily=weather_code,temperature_2m_max,temperature_2m_min'
          '&timezone=auto'
      );
      final response = await http.get(url);
      if (response.statusCode != 200) throw Exception('Failed to fetch weather');
      final data = jsonDecode(response.body);

      // 4. Fetch AQI
      final aqiUrl = Uri.parse(
          'https://air-quality-api.open-meteo.com/v1/air-quality?latitude=$lat&longitude=$lon'
          '&current=pm10,pm2_5'
      );
      int aqi = 50; // Default if fails
      try {
        final aqiRes = await http.get(aqiUrl);
        if (aqiRes.statusCode == 200) {
          final aqiData = jsonDecode(aqiRes.body);
          if (aqiData['current'] != null) {
            double pm10 = (aqiData['current']['pm10'] as num?)?.toDouble() ?? 0.0;
            double pm25 = (aqiData['current']['pm2_5'] as num?)?.toDouble() ?? 0.0;
            aqi = _calculateIndianAqi(pm25, pm10);
          }
        }
      } catch (_) {}

      // 5. Parse Data
      final current = data['current'];
      final hourly = data['hourly'];
      final daily = data['daily'];

      final currentTemp = (current['temperature_2m'] as num).toDouble();
      final currentHumidity = (current['relative_humidity_2m'] as num?)?.toDouble() ?? 50.0;
      final isDay = (current['is_day'] as int?) == 1;

      List<HourlyForecast> hourlyList = [];
      for (int i = 0; i < 24; i++) { // Get next 24 hours
        hourlyList.add(HourlyForecast(
          time: DateTime.parse(hourly['time'][i]),
          temp: (hourly['temperature_2m'][i] as num).toDouble(),
          weatherCode: hourly['weather_code'][i] as int,
          uvIndex: (hourly['uv_index'][i] as num?)?.toDouble() ?? 0.0,
          precipitationProbability: (hourly['precipitation_probability'][i] as num?)?.toDouble() ?? 0.0,
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

      // 6. Dynamic Insights Calculation
      String bestTimeStr = "Anytime";
      String intensityStr = "Moderate";
      String hydrationStr = "Normal | Drink 250ml/hr";

      HourlyForecast? bestHour;
      for (var h in hourlyList) {
        if (h.time.hour >= 5 && h.time.hour <= 21 && h.precipitationProbability < 20) {
          if (bestHour == null || h.temp < bestHour.temp) {
            bestHour = h;
          }
        }
      }

      if (bestHour != null) {
        int hr = bestHour.time.hour;
        String period = hr >= 12 ? 'PM' : 'AM';
        int displayHr = hr > 12 ? hr - 12 : (hr == 0 ? 12 : hr);
        bestTimeStr = "$displayHr:00 $period";
        
        if (bestHour.temp < 25) {
          intensityStr = "High";
        } else if (bestHour.temp <= 32) {
          intensityStr = "Moderate";
        } else {
          intensityStr = "Low (avoid intense exercise)";
        }
      }

      if (currentTemp > 35 || currentHumidity > 70) {
        hydrationStr = "High Risk | Drink 500ml/hr";
      } else if (currentTemp >= 28 && currentTemp <= 35) {
        hydrationStr = "Moderate | Drink 350ml/hr";
      } else {
        hydrationStr = "Normal | Drink 250ml/hr";
      }

      final weatherModel = WeatherModel(
        currentTemp: currentTemp,
        weatherCode: current['weather_code'] as int,
        windSpeed: (current['wind_speed_10m'] as num).toDouble(),
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

      // 6. Cache Data
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

    int ipm25 = getSubIndex(pm25, [0, 30, 60, 90, 120, 250], [0, 50, 100, 200, 300, 400, 500]);
    int ipm10 = getSubIndex(pm10, [0, 50, 100, 250, 350, 430], [0, 50, 100, 200, 300, 400, 500]);
    
    return ipm25 > ipm10 ? ipm25 : ipm10;
  }
}
