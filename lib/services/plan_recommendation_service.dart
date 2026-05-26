import '../models/weather_model.dart';
import 'plan_readiness_service.dart';

class PlanRecommendationResult {
  final String bestTimeMessage;
  final String reason;
  final List<String> alternativeWorkouts;
  final String adaptiveActionText;

  PlanRecommendationResult({
    required this.bestTimeMessage,
    required this.reason,
    required this.alternativeWorkouts,
    required this.adaptiveActionText,
  });
}

class PlanRecommendationService {
  static PlanRecommendationResult getRecommendation({
    required WeatherModel? weather,
    required PlanReadinessResult readiness,
  }) {
    String bestTime = 'Anytime today';
    String reason = 'Conditions are optimal';
    List<String> alternatives = [];
    String actionText = 'Start Workout';

    if (weather != null) {
      if (weather.bestTime != 'Anytime' && weather.bestTime.isNotEmpty) {
        bestTime = 'Best after ${weather.bestTime}';
        reason = 'Cooler temperatures and better conditions';
      }

      if (readiness.status == ReadinessStatus.caution || readiness.status == ReadinessStatus.notIdeal) {
        if (weather.currentTemp > 32) {
          reason = 'High temperature risk';
          actionText = 'Switch to Indoor';
          alternatives = ['Indoor Cycling', 'Yoga', 'Strength'];
        } else if (weather.conditionText.toLowerCase().contains('rain')) {
          reason = 'Rainy conditions';
          actionText = 'Switch to Indoor';
          alternatives = ['Treadmill', 'Stretch', 'HIIT'];
        } else if (weather.aqi > 150) {
          reason = 'Poor Air Quality';
          actionText = 'Switch to Indoor';
          alternatives = ['Yoga', 'Strength', 'Pilates'];
        }
      }
    }

    return PlanRecommendationResult(
      bestTimeMessage: bestTime,
      reason: reason,
      alternativeWorkouts: alternatives,
      adaptiveActionText: actionText,
    );
  }
}
