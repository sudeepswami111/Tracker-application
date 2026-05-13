class WeatherModel {
  final double currentTemp;
  final int weatherCode;
  final int aqi;
  final double windSpeed;
  final double uvIndex;
  final List<HourlyForecast> hourly;
  final List<DailyForecast> daily;
  final DateTime lastFetched;

  WeatherModel({
    required this.currentTemp,
    required this.weatherCode,
    required this.aqi,
    required this.windSpeed,
    required this.uvIndex,
    required this.hourly,
    required this.daily,
    required this.lastFetched,
  });

  String get condition => _getConditionFromCode(weatherCode);
  bool get isUnsafe => aqi > 150 || windSpeed > 40 || currentTemp > 40 || currentTemp < -10;
  
  String get suggestion {
    if (isUnsafe) return 'Unsafe conditions! Stay indoors.';
    if (currentTemp > 30) return 'Too hot — try swimming or indoor gym.';
    if (weatherCode >= 60 && weatherCode <= 69) return 'Rainy — great day for yoga or indoor cycling.';
    if (weatherCode >= 71) return 'Snowy — dress warm if you go out!';
    return 'Great day for a run!';
  }

  static String _getConditionFromCode(int code) {
    if (code == 0) return 'Clear';
    if (code == 1 || code == 2 || code == 3) return 'Cloudy';
    if (code >= 45 && code <= 48) return 'Foggy';
    if (code >= 51 && code <= 69) return 'Rainy';
    if (code >= 71 && code <= 77) return 'Snow';
    if (code >= 80 && code <= 82) return 'Showers';
    if (code >= 95 && code <= 99) return 'Thunderstorm';
    return 'Unknown';
  }

  Map<String, dynamic> toJson() => {
        'currentTemp': currentTemp,
        'weatherCode': weatherCode,
        'aqi': aqi,
        'windSpeed': windSpeed,
        'uvIndex': uvIndex,
        'hourly': hourly.map((e) => e.toJson()).toList(),
        'daily': daily.map((e) => e.toJson()).toList(),
        'lastFetched': lastFetched.toIso8601String(),
      };

  factory WeatherModel.fromJson(Map<String, dynamic> json) => WeatherModel(
        currentTemp: (json['currentTemp'] as num).toDouble(),
        weatherCode: json['weatherCode'] as int,
        aqi: json['aqi'] as int,
        windSpeed: (json['windSpeed'] as num).toDouble(),
        uvIndex: (json['uvIndex'] as num).toDouble(),
        hourly: (json['hourly'] as List).map((e) => HourlyForecast.fromJson(Map<String, dynamic>.from(e))).toList(),
        daily: (json['daily'] as List).map((e) => DailyForecast.fromJson(Map<String, dynamic>.from(e))).toList(),
        lastFetched: DateTime.parse(json['lastFetched'] as String),
      );
}

class HourlyForecast {
  final DateTime time;
  final double temp;
  final int weatherCode;
  final double uvIndex;

  HourlyForecast({
    required this.time,
    required this.temp,
    required this.weatherCode,
    required this.uvIndex,
  });

  String get condition => WeatherModel._getConditionFromCode(weatherCode);

  Map<String, dynamic> toJson() => {
        'time': time.toIso8601String(),
        'temp': temp,
        'weatherCode': weatherCode,
        'uvIndex': uvIndex,
      };

  factory HourlyForecast.fromJson(Map<String, dynamic> json) => HourlyForecast(
        time: DateTime.parse(json['time'] as String),
        temp: (json['temp'] as num).toDouble(),
        weatherCode: json['weatherCode'] as int,
        uvIndex: (json['uvIndex'] as num).toDouble(),
      );
}

class DailyForecast {
  final DateTime date;
  final double maxTemp;
  final double minTemp;
  final int weatherCode;

  DailyForecast({
    required this.date,
    required this.maxTemp,
    required this.minTemp,
    required this.weatherCode,
  });

  String get condition => WeatherModel._getConditionFromCode(weatherCode);

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'maxTemp': maxTemp,
        'minTemp': minTemp,
        'weatherCode': weatherCode,
      };

  factory DailyForecast.fromJson(Map<String, dynamic> json) => DailyForecast(
        date: DateTime.parse(json['date'] as String),
        maxTemp: (json['maxTemp'] as num).toDouble(),
        minTemp: (json['minTemp'] as num).toDouble(),
        weatherCode: json['weatherCode'] as int,
      );
}
