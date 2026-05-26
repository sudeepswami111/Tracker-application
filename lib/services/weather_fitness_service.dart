import '../models/weather_model.dart';
import 'package:intl/intl.dart';

enum RiskLevel { low, moderate, high, extreme }

class RiskIndicator {
  final RiskLevel level;
  final String label;

  RiskIndicator(this.level, this.label);
}

class WeatherFitnessScore {
  final int score;
  final String status;
  final RiskIndicator heatRisk;
  final RiskIndicator uvRisk;
  final RiskIndicator aqiRisk;
  final RiskIndicator rainRisk;
  final RiskIndicator windRisk;
  final String runRecommendation;
  final String runReason;
  final String alternativeActivity;

  WeatherFitnessScore({
    required this.score,
    required this.status,
    required this.heatRisk,
    required this.uvRisk,
    required this.aqiRisk,
    required this.rainRisk,
    required this.windRisk,
    required this.runRecommendation,
    required this.runReason,
    required this.alternativeActivity,
  });
}

class WeatherFitnessService {
  static WeatherFitnessScore calculateReadiness(WeatherModel weather) {
    int score = 100;

    // 1. Heat Risk
    RiskLevel heatRisk = RiskLevel.low;
    if (weather.currentApparentTemp >= 40) {
      heatRisk = RiskLevel.extreme;
      score -= 60;
    } else if (weather.currentApparentTemp >= 35) {
      heatRisk = RiskLevel.high;
      score -= 30;
    } else if (weather.currentApparentTemp >= 30) {
      heatRisk = RiskLevel.moderate;
      score -= 10;
    } else if (weather.currentApparentTemp < 0) {
      heatRisk = RiskLevel.high;
      score -= 20;
    }

    // 2. UV Risk
    RiskLevel uvRisk = RiskLevel.low;
    if (weather.uvIndex >= 8) {
      uvRisk = RiskLevel.extreme;
      score -= 25;
    } else if (weather.uvIndex >= 6) {
      uvRisk = RiskLevel.high;
      score -= 15;
    } else if (weather.uvIndex >= 3) {
      uvRisk = RiskLevel.moderate;
      score -= 5;
    }

    // 3. AQI Risk
    RiskLevel aqiRisk = RiskLevel.low;
    if (weather.aqi > 200) {
      aqiRisk = RiskLevel.extreme;
      score -= 80;
    } else if (weather.aqi > 150) {
      aqiRisk = RiskLevel.high;
      score -= 40;
    } else if (weather.aqi > 100) {
      aqiRisk = RiskLevel.moderate;
      score -= 15;
    }

    // 4. Rain Risk
    RiskLevel rainRisk = RiskLevel.low;
    if (weather.currentPrecipitationProbability >= 70) {
      rainRisk = RiskLevel.high;
      score -= 20;
    } else if (weather.currentPrecipitationProbability >= 30) {
      rainRisk = RiskLevel.moderate;
      score -= 10;
    }

    // Thunderstorm Penalty (Instant Avoid)
    if (weather.weatherCode == 95 || weather.weatherCode == 96 || weather.weatherCode == 99) {
      score = 0;
      rainRisk = RiskLevel.extreme;
    }

    // 5. Wind Risk
    RiskLevel windRisk = RiskLevel.low;
    if (weather.windSpeed > 40) {
      windRisk = RiskLevel.extreme;
      score -= 30;
    } else if (weather.windSpeed > 25) {
      windRisk = RiskLevel.high;
      score -= 10;
    } else if (weather.windSpeed > 15) {
      windRisk = RiskLevel.moderate;
      score -= 5;
    }

    score = score.clamp(0, 100);

    String status = 'Avoid';
    if (score >= 85) {
      status = 'Excellent for outdoor workout';
    } else if (score >= 70) {
      status = 'Good for light workout';
    } else if (score >= 50) {
      status = 'Caution advised';
    } else {
      status = 'Avoid outdoor workout';
    }

    // "Should I Run Now?" Logic
    String runRecommendation = 'Yes, go for it!';
    String runReason = 'Conditions are favorable.';
    String alternativeActivity = 'Run, Cycle, or Outdoor Walk';

    if (score < 50) {
      runRecommendation = 'Not ideal now.';
      if (aqiRisk == RiskLevel.extreme || aqiRisk == RiskLevel.high) {
        runReason = 'Air quality is very poor.';
      } else if (heatRisk == RiskLevel.extreme || heatRisk == RiskLevel.high) {
        runReason = 'Heat index is dangerously high.';
      } else if (weather.weatherCode == 95 || weather.weatherCode == 96 || weather.weatherCode == 99) {
        runReason = 'Thunderstorm risk.';
      } else {
        runReason = 'Multiple high weather risks.';
      }
      alternativeActivity = 'Indoor Strength, Yoga, or Treadmill';
    } else if (score < 75) {
      runRecommendation = 'Proceed with caution.';
      if (heatRisk == RiskLevel.moderate) {
        runReason = 'It is getting warm, stay hydrated.';
        alternativeActivity = 'Swim or Light Jog';
      } else if (uvRisk == RiskLevel.high || uvRisk == RiskLevel.moderate) {
        runReason = 'UV is moderate/high, wear sunscreen.';
        alternativeActivity = 'Shaded Run or Evening Walk';
      } else if (rainRisk == RiskLevel.high || rainRisk == RiskLevel.moderate) {
        runReason = 'Rain is likely, be careful.';
        alternativeActivity = 'Indoor Cycling or Gym';
      } else {
        runReason = 'Weather is okay, but not perfect.';
        alternativeActivity = 'Brisk Walk or Short Run';
      }
    }

    return WeatherFitnessScore(
      score: score,
      status: status,
      heatRisk: RiskIndicator(heatRisk, 'Heat'),
      uvRisk: RiskIndicator(uvRisk, 'UV'),
      aqiRisk: RiskIndicator(aqiRisk, 'AQI'),
      rainRisk: RiskIndicator(rainRisk, 'Rain'),
      windRisk: RiskIndicator(windRisk, 'Wind'),
      runRecommendation: runRecommendation,
      runReason: runReason,
      alternativeActivity: alternativeActivity,
    );
  }

  static String getBestWorkoutWindow(List<HourlyForecast> hourly) {
    if (hourly.isEmpty) return 'No data';

    HourlyForecast? bestStart;
    int bestScore = -999;

    for (int i = 0; i < hourly.length - 1; i++) {
      final h = hourly[i];
      // Skip night time for "best window" usually, unless it's extremely hot
      if (h.time.hour < 5 || h.time.hour > 22) continue;

      int hourScore = 100;
      if (h.temp > 30) hourScore -= 30;
      if (h.temp > 35) hourScore -= 60;
      if (h.uvIndex > 5) hourScore -= 20;
      if (h.precipitationProbability > 30) hourScore -= 40;
      if (h.weatherCode == 95 || h.weatherCode == 96 || h.weatherCode == 99) hourScore -= 100;

      if (hourScore > bestScore) {
        bestScore = hourScore;
        bestStart = h;
      }
    }

    if (bestStart == null || bestScore < 0) return 'Try tomorrow';

    final end = bestStart.time.add(const Duration(hours: 1));
    final format = DateFormat('h a');
    return '${format.format(bestStart.time)} - ${format.format(end)}';
  }

  static List<String> getActivityChips(WeatherModel weather, WeatherFitnessScore fitness) {
    if (fitness.score < 50) {
      return ['Indoor Workout', 'Yoga', 'Rest'];
    } else if (weather.currentApparentTemp > 30) {
      return ['Swim', 'Evening Walk', 'Gym'];
    } else if (weather.currentPrecipitationProbability > 40) {
      return ['Stretching', 'Home Workout', 'Mobility'];
    } else {
      return ['Run', 'Cycle', 'Outdoor Walk'];
    }
  }

  static String getDailyFitnessPlan(DailyForecast day) {
    if (day.weatherCode == 95 || day.weatherCode == 96 || day.weatherCode == 99) {
      return 'Avoid Outdoor';
    }
    if (day.maxTemp >= 38) {
      return 'Indoor Strength';
    }
    if (day.maxTemp >= 32) {
      return 'Swim Day';
    }
    if (day.precipitationProbabilityMax >= 60) {
      return 'Recovery Day';
    }
    if (day.maxTemp >= 15 && day.maxTemp <= 25 && day.precipitationProbabilityMax < 20) {
      return 'Best for Run';
    }
    return 'Outdoor Walk';
  }
}
