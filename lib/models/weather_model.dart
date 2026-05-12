class WeatherCondition {
  final double tempC;
  final double tempMax;
  final double tempMin;
  final int weatherCode;
  final double windSpeedKmh;
  final int uvIndex;
  final int humidity;
  final double precipitation;

  const WeatherCondition({
    required this.tempC,
    required this.tempMax,
    required this.tempMin,
    required this.weatherCode,
    required this.windSpeedKmh,
    required this.uvIndex,
    required this.humidity,
    required this.precipitation,
  });

  String get conditionLabel {
    if (weatherCode == 0) return 'Clear Sky';
    if (weatherCode <= 2) return 'Partly Cloudy';
    if (weatherCode == 3) return 'Overcast';
    if (weatherCode <= 49) return 'Foggy';
    if (weatherCode <= 59) return 'Drizzle';
    if (weatherCode <= 69) return 'Rain';
    if (weatherCode <= 79) return 'Snowfall';
    if (weatherCode <= 84) return 'Rain Showers';
    if (weatherCode <= 99) return 'Thunderstorm';
    return 'Unknown';
  }

  /// Returns a Unicode emoji for the weather
  String get emoji {
    if (weatherCode == 0) return '☀️';
    if (weatherCode <= 2) return '⛅';
    if (weatherCode == 3) return '☁️';
    if (weatherCode <= 49) return '🌫️';
    if (weatherCode <= 59) return '🌦️';
    if (weatherCode <= 69) return '🌧️';
    if (weatherCode <= 79) return '❄️';
    if (weatherCode <= 84) return '🌦️';
    if (weatherCode <= 99) return '⛈️';
    return '🌡️';
  }

  bool get isUnsafeForOutdoor =>
      weatherCode >= 80 || uvIndex >= 9 || windSpeedKmh > 50 || tempC > 38 || tempC < 0;

  bool get isGoodForRun =>
      !isUnsafeForOutdoor && tempC >= 10 && tempC <= 28 && weatherCode <= 3;

  String get activitySuggestion {
    if (weatherCode >= 80) return '⛈️ Storm alert — stay indoors today';
    if (tempC > 38) return '🥵 Too hot — try swimming or indoor yoga';
    if (tempC < 5) return '🥶 Too cold — consider an indoor workout';
    if (uvIndex >= 9) return '☀️ Extreme UV — run early morning or evening';
    if (windSpeedKmh > 40) return '💨 High winds — skip cycling today';
    if (weatherCode >= 60 && weatherCode < 80) return '🌧️ Rainy day — great for indoor training';
    if (isGoodForRun) return '🏃 Great day for a run outside!';
    return '👍 Decent weather — any activity works';
  }

  Map<String, dynamic> toJson() => {
        'tempC': tempC,
        'tempMax': tempMax,
        'tempMin': tempMin,
        'weatherCode': weatherCode,
        'windSpeedKmh': windSpeedKmh,
        'uvIndex': uvIndex,
        'humidity': humidity,
        'precipitation': precipitation,
      };

  factory WeatherCondition.fromJson(Map<String, dynamic> json) => WeatherCondition(
        tempC: (json['tempC'] as num).toDouble(),
        tempMax: (json['tempMax'] as num).toDouble(),
        tempMin: (json['tempMin'] as num).toDouble(),
        weatherCode: (json['weatherCode'] as num).toInt(),
        windSpeedKmh: (json['windSpeedKmh'] as num).toDouble(),
        uvIndex: (json['uvIndex'] as num).toInt(),
        humidity: (json['humidity'] as num).toInt(),
        precipitation: (json['precipitation'] as num).toDouble(),
      );
}

class DayForecast {
  final String date; // yyyy-MM-dd
  final double tempMax;
  final double tempMin;
  final int weatherCode;
  final double precipitation;

  const DayForecast({
    required this.date,
    required this.tempMax,
    required this.tempMin,
    required this.weatherCode,
    required this.precipitation,
  });

  String get emoji {
    if (weatherCode == 0) return '☀️';
    if (weatherCode <= 2) return '⛅';
    if (weatherCode == 3) return '☁️';
    if (weatherCode <= 49) return '🌫️';
    if (weatherCode <= 59) return '🌦️';
    if (weatherCode <= 69) return '🌧️';
    if (weatherCode <= 79) return '❄️';
    if (weatherCode <= 84) return '🌦️';
    if (weatherCode <= 99) return '⛈️';
    return '🌡️';
  }

  String get dayName {
    final d = DateTime.parse(date);
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[d.weekday - 1];
  }

  Map<String, dynamic> toJson() => {
        'date': date,
        'tempMax': tempMax,
        'tempMin': tempMin,
        'weatherCode': weatherCode,
        'precipitation': precipitation,
      };

  factory DayForecast.fromJson(Map<String, dynamic> json) => DayForecast(
        date: json['date'] as String,
        tempMax: (json['tempMax'] as num).toDouble(),
        tempMin: (json['tempMin'] as num).toDouble(),
        weatherCode: (json['weatherCode'] as num).toInt(),
        precipitation: (json['precipitation'] as num).toDouble(),
      );
}

class WeatherData {
  final WeatherCondition current;
  final List<DayForecast> forecast;
  final DateTime fetchedAt;
  final double lat;
  final double lon;

  const WeatherData({
    required this.current,
    required this.forecast,
    required this.fetchedAt,
    required this.lat,
    required this.lon,
  });

  bool get isStale => DateTime.now().difference(fetchedAt).inMinutes >= 30;

  Map<String, dynamic> toJson() => {
        'current': current.toJson(),
        'forecast': forecast.map((f) => f.toJson()).toList(),
        'fetchedAt': fetchedAt.toIso8601String(),
        'lat': lat,
        'lon': lon,
      };

  factory WeatherData.fromJson(Map<String, dynamic> json) => WeatherData(
        current: WeatherCondition.fromJson(json['current'] as Map<String, dynamic>),
        forecast: (json['forecast'] as List<dynamic>)
            .map((e) => DayForecast.fromJson(e as Map<String, dynamic>))
            .toList(),
        fetchedAt: DateTime.parse(json['fetchedAt'] as String),
        lat: (json['lat'] as num).toDouble(),
        lon: (json['lon'] as num).toDouble(),
      );
}
