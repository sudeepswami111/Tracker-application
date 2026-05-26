import '../models/weather_model.dart';

enum ReadinessStatus { ready, good, caution, notIdeal }

class PlanReadinessResult {
  final int score;
  final ReadinessStatus status;
  final String label;

  PlanReadinessResult(this.score, this.status, this.label);
}

class PlanReadinessService {
  static PlanReadinessResult calculateReadiness({
    WeatherModel? weather,
    int currentStreak = 0,
    int currentSteps = 0,
  }) {
    int score = 85; // Baseline

    // Weather impact
    if (weather != null) {
      if (weather.currentTemp > 35) score -= 20; // Too hot
      if (weather.currentTemp < 5) score -= 10;  // Too cold
      if (weather.aqi > 150) score -= 15;        // Bad air
      if (weather.conditionText.toLowerCase().contains('rain')) score -= 10;
    }

    // Streak impact (consistency bonus)
    if (currentStreak > 3) score += 5;
    if (currentStreak > 7) score += 5;

    // Steps impact (fatigue)
    if (currentSteps > 15000) score -= 10;

    score = score.clamp(0, 100);

    if (score >= 80) return PlanReadinessResult(score, ReadinessStatus.ready, 'Ready');
    if (score >= 60) return PlanReadinessResult(score, ReadinessStatus.good, 'Good');
    if (score >= 40) return PlanReadinessResult(score, ReadinessStatus.caution, 'Caution');
    return PlanReadinessResult(score, ReadinessStatus.notIdeal, 'Not Ideal');
  }
}
