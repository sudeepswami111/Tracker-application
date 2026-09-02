import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/workout_phase.dart';

class SmartSuggestion {
  final String title;
  final String body;

  const SmartSuggestion({required this.title, required this.body});
}

class WorkoutTimeRecommendation {
  final String optimalWindow;
  final String secondaryWindow;
  final String scienceReason;
  final String quickTip;
  final IconData icon;

  const WorkoutTimeRecommendation({
    required this.optimalWindow,
    required this.secondaryWindow,
    required this.scienceReason,
    required this.quickTip,
    required this.icon,
  });
}

class WorkoutPlanSuggestionService {
  static WorkoutTimeRecommendation getOptimalTimeRecommendation(String activityType, {double? currentTemp, bool isRainy = false}) {
    final normalized = _normalizeActivityType(activityType).toLowerCase();

    if (currentTemp != null && currentTemp > 30) {
      return const WorkoutTimeRecommendation(
        optimalWindow: '06:00 AM – 07:30 AM',
        secondaryWindow: '07:00 PM – 08:30 PM',
        scienceReason: 'Avoid peak solar radiation & heat exhaustion (>30°C)',
        quickTip: 'Early morning or post-sunset provides the safest thermoregulation',
        icon: LucideIcons.sunMedium,
      );
    }

    if (normalized.contains('run') || normalized.contains('treadmill')) {
      return const WorkoutTimeRecommendation(
        optimalWindow: '05:30 PM – 07:30 PM',
        secondaryWindow: '06:00 AM – 08:00 AM',
        scienceReason: 'Core body temperature & lung capacity peak in late afternoon for max speed',
        quickTip: '05:30 PM – 07:30 PM: Lowest perceived exertion & highest VO2 efficiency',
        icon: LucideIcons.flame,
      );
    } else if (normalized.contains('gym') || normalized.contains('strength') || normalized.contains('hiit') || normalized.contains('workout')) {
      return const WorkoutTimeRecommendation(
        optimalWindow: '04:00 PM – 07:00 PM',
        secondaryWindow: '08:30 AM – 10:30 AM',
        scienceReason: 'Optimal testosterone/cortisol ratio and highest peak muscle torque',
        quickTip: 'Late afternoon sessions generate 5–10% higher maximal lifting strength',
        icon: LucideIcons.dumbbell,
      );
    } else if (normalized.contains('yoga') || normalized.contains('stretch') || normalized.contains('meditat')) {
      return const WorkoutTimeRecommendation(
        optimalWindow: '06:00 AM – 07:30 AM',
        secondaryWindow: '08:30 PM – 10:00 PM',
        scienceReason: 'Enhances parasympathetic tone, morning mobility, and nighttime deep sleep',
        quickTip: 'Sunrise releases overnight joint stiffness; evening lowers cortisol before bed',
        icon: LucideIcons.sparkles,
      );
    } else if (normalized.contains('walk')) {
      return const WorkoutTimeRecommendation(
        optimalWindow: '06:30 AM – 08:30 AM',
        secondaryWindow: '06:00 PM – 08:00 PM',
        scienceReason: 'Aids metabolic circadian sync and accelerates post-meal glucose clearing',
        quickTip: 'Post-dinner walk prevents blood sugar spikes and aids digestion',
        icon: LucideIcons.footprints,
      );
    } else if (normalized.contains('cycle') || normalized.contains('bike')) {
      return const WorkoutTimeRecommendation(
        optimalWindow: '06:00 AM – 08:30 AM',
        secondaryWindow: '05:00 PM – 07:00 PM',
        scienceReason: 'Optimal cardiovascular output with cooler ambient air and lower traffic',
        quickTip: 'Early morning offers cleaner air quality and safer road conditions',
        icon: LucideIcons.bike,
      );
    } else if (normalized.contains('swim')) {
      return const WorkoutTimeRecommendation(
        optimalWindow: '07:00 AM – 09:30 AM',
        secondaryWindow: '05:30 PM – 07:30 PM',
        scienceReason: 'Low-impact cardiovascular activation and optimal pulmonary expansion',
        quickTip: 'Mid-morning or early evening provides ideal water temperature and muscle warm-up',
        icon: LucideIcons.waves,
      );
    }

    return const WorkoutTimeRecommendation(
      optimalWindow: '07:00 AM – 09:00 AM',
      secondaryWindow: '05:30 PM – 07:30 PM',
      scienceReason: 'Aligns with human circadian alertness and core muscle flexibility',
      quickTip: 'Consistent timing every day produces the fastest physiological adaptations',
      icon: LucideIcons.clock,
    );
  }

  static List<WorkoutPhase> generatePhases({
    required String activityType,
    required int totalDurationMinutes,
    String? intensity,
    String? weatherStatus,
  }) {
    final normalized = _normalizeActivityType(activityType);

    // Default timings
    int defWarmUp = 5;
    int defMain = 30;
    int defCool = 5;

    String warmUpTitle = 'Warm-up';
    String mainTitle = 'Main Activity';
    String coolTitle = 'Cooldown';

    IconData warmUpIcon = LucideIcons.accessibility;
    IconData mainIcon = LucideIcons.activity;
    IconData coolIcon = LucideIcons.droplets;

    String warmUpDesc = 'Prepare your body for the activity.';
    String mainDesc = 'Perform the main workout activity.';
    String coolDesc = 'Bring your heart rate down and stretch.';

    // Customize based on normalized activity type
    switch (normalized) {
      case 'Running':
        defWarmUp = 5;
        defMain = 30;
        defCool = 5;
        warmUpTitle = 'Warm-up';
        mainTitle = (weatherStatus == 'hot' || weatherStatus == 'rainy') ? 'Indoor Treadmill' : 'Outdoor Run';
        coolTitle = 'Cooldown';
        warmUpIcon = LucideIcons.accessibility;
        mainIcon = Icons.directions_run;
        coolIcon = LucideIcons.droplets;
        warmUpDesc = 'Start with light jogging and dynamic stretching.';
        mainDesc = 'Run at a steady, controlled pace. Keep breathing controlled.';
        coolDesc = 'Slow walk and stretch your legs.';
        break;

      case 'Walking':
        defWarmUp = 3;
        defMain = 25;
        defCool = 5;
        warmUpTitle = 'Easy Start';
        mainTitle = (weatherStatus == 'hot' || weatherStatus == 'rainy') ? 'Indoor Walk' : 'Brisk Walk';
        coolTitle = 'Cooldown';
        warmUpIcon = LucideIcons.footprints;
        mainIcon = LucideIcons.footprints;
        coolIcon = LucideIcons.accessibility;
        warmUpDesc = 'Start at a relaxed, comfortable pace.';
        mainDesc = 'Walk briskly to raise your heart rate.';
        coolDesc = 'Gentle recovery walk and calf stretches.';
        break;

      case 'Cycling':
        defWarmUp = 5;
        defMain = 40;
        defCool = 5;
        warmUpTitle = 'Warm-up Ride';
        mainTitle = (weatherStatus == 'hot' || weatherStatus == 'rainy') ? 'Indoor Spin' : 'Cycling';
        coolTitle = 'Easy Pedal';
        warmUpIcon = Icons.directions_bike;
        mainIcon = Icons.directions_bike;
        coolIcon = LucideIcons.droplets;
        warmUpDesc = 'Light spin to raise temperature and joint lubrication.';
        mainDesc = 'Maintain steady cadence and moderate resistance.';
        coolDesc = 'Very low resistance pedal and light stretches.';
        break;

      case 'Bike Ride':
        defWarmUp = 2;
        defMain = 45;
        defCool = 5;
        warmUpTitle = 'Safety Check';
        mainTitle = (weatherStatus == 'hot' || weatherStatus == 'rainy') ? 'Indoor Bike' : 'Ride';
        coolTitle = 'Cooldown';
        warmUpIcon = LucideIcons.shieldAlert; // Safety check
        mainIcon = Icons.directions_bike;
        coolIcon = LucideIcons.accessibility;
        warmUpDesc = 'Check tires, brakes, helmet, and gear safety.';
        mainDesc = 'Main outdoor bike ride, pay attention to traffic.';
        coolDesc = 'Slow down to an easy pace and stretch key muscles.';
        break;

      case 'Yoga':
        defWarmUp = 3;
        defMain = 25;
        defCool = 5;
        warmUpTitle = 'Breathing';
        mainTitle = 'Yoga Flow';
        coolTitle = 'Relaxation';
        warmUpIcon = LucideIcons.wind;
        mainIcon = LucideIcons.accessibility;
        coolIcon = LucideIcons.smile;
        warmUpDesc = 'Mindful deep breathing and centering exercise.';
        mainDesc = 'Perform Vinyasa or custom yoga pose sequence.';
        coolDesc = 'Deep relaxation, lying down in Savasana pose.';
        break;

      case 'Strength':
        defWarmUp = 5;
        defMain = 30;
        defCool = 5;
        warmUpTitle = 'Mobility';
        mainTitle = 'Strength Sets';
        coolTitle = 'Stretch';
        warmUpIcon = LucideIcons.accessibility;
        mainIcon = Icons.fitness_center;
        coolIcon = LucideIcons.accessibility;
        warmUpDesc = 'Joint mobility drills and active warm-up exercises.';
        mainDesc = 'Lift weights, perform core exercises or bodyweight sets.';
        coolDesc = 'Stretch worked muscle groups, focus on lower back.';
        break;

      case 'Gym':
        defWarmUp = 5;
        defMain = 40;
        defCool = 5;
        warmUpTitle = 'Warm-up';
        mainTitle = 'Main Workout';
        coolTitle = 'Stretch';
        warmUpIcon = LucideIcons.accessibility;
        mainIcon = Icons.fitness_center;
        coolIcon = LucideIcons.accessibility;
        warmUpDesc = 'Start with light cardio to elevate body temperature.';
        mainDesc = 'Proceed with machine, cable, or compound exercises.';
        coolDesc = 'Light static stretches and breathing.';
        break;

      case 'Swimming':
        defWarmUp = 5;
        defMain = 30;
        defCool = 5;
        warmUpTitle = 'Warm-up Swim';
        mainTitle = 'Swim Laps';
        coolTitle = 'Easy Swim';
        warmUpIcon = LucideIcons.swatchBook; // pool substitute or similar
        mainIcon = LucideIcons.swatchBook;
        coolIcon = LucideIcons.swatchBook;
        warmUpDesc = 'Swim at a relaxed pace to adjust to water.';
        mainDesc = 'Swim sets at a sustained, higher pace.';
        coolDesc = 'Slow down to recover breath and relax muscles.';
        break;

      case 'Meditation':
        defWarmUp = 2;
        defMain = 15;
        defCool = 3;
        warmUpTitle = 'Settle';
        mainTitle = 'Meditation';
        coolTitle = 'Reflection';
        warmUpIcon = LucideIcons.smile;
        mainIcon = LucideIcons.smile;
        coolIcon = LucideIcons.smile;
        warmUpDesc = 'Find a comfortable posture and settle mind.';
        mainDesc = 'Focus on breathing, mindfulness, or visualization.';
        coolDesc = 'Acknowledge state of mind and gently return to space.';
        break;

      case 'Study':
        defWarmUp = 5;
        defMain = 45;
        defCool = 10;
        warmUpTitle = 'Focus Prep';
        mainTitle = 'Deep Work';
        coolTitle = 'Break';
        warmUpIcon = LucideIcons.clipboardList;
        mainIcon = LucideIcons.bookOpen;
        coolIcon = LucideIcons.coffee;
        warmUpDesc = 'Organize materials, silences, and clarify goals.';
        mainDesc = 'Focus on single task without distraction.';
        coolDesc = 'Step away from screen, hydrate or do light stretches.';
        break;

      case 'Stretching':
        defWarmUp = 5;
        defMain = 20;
        defCool = 3;
        warmUpTitle = 'Mobility';
        mainTitle = 'Stretch Flow';
        coolTitle = 'Breathing';
        warmUpIcon = LucideIcons.accessibility;
        mainIcon = LucideIcons.accessibility;
        coolIcon = LucideIcons.wind;
        warmUpDesc = 'Light active movements to warm muscles.';
        mainDesc = 'Static stretches held for 20-30 seconds.';
        coolDesc = 'Deep breaths, letting remaining tension melt.';
        break;

      case 'HIIT':
        defWarmUp = 5;
        defMain = 20;
        defCool = 5;
        warmUpTitle = 'Warm-up';
        mainTitle = 'HIIT Rounds';
        coolTitle = 'Cooldown';
        warmUpIcon = LucideIcons.accessibility;
        mainIcon = LucideIcons.timer;
        coolIcon = LucideIcons.droplets;
        warmUpDesc = 'Dynamic stretching and low-intensity movements.';
        mainDesc = 'Alternate high intensity effort with short rest periods.';
        coolDesc = 'Slow walk and active stretching.';
        break;

      case 'Rest / Recovery':
        defWarmUp = 3;
        defMain = 10;
        defCool = 10;
        warmUpTitle = 'Breathing';
        mainTitle = 'Light Mobility';
        coolTitle = 'Recovery';
        warmUpIcon = LucideIcons.wind;
        mainIcon = LucideIcons.accessibility;
        coolIcon = LucideIcons.smile;
        warmUpDesc = 'Deep diaphragmatic breathing to trigger relaxation.';
        mainDesc = 'Gentle dynamic joint mobility (no strain).';
        coolDesc = 'Complete rest, hydration, and muscle relaxation.';
        break;

      default:
        // Unknown: Default timings
        defWarmUp = 5;
        defMain = totalDurationMinutes > 10 ? totalDurationMinutes - 10 : 5;
        defCool = 5;
        warmUpTitle = 'Prepare';
        mainTitle = 'Main Activity';
        coolTitle = 'Finish';
        break;
    }

    final int defTotal = defWarmUp + defMain + defCool;

    // Calculate scaled timings
    int warmUp = ((defWarmUp / defTotal) * totalDurationMinutes).round();
    int coolDown = ((defCool / defTotal) * totalDurationMinutes).round();

    if (defWarmUp > 0 && warmUp < 1) warmUp = 1;
    if (defCool > 0 && coolDown < 1) coolDown = 1;

    int main = totalDurationMinutes - warmUp - coolDown;
    if (main < 1) {
      main = 1;
      int remaining = totalDurationMinutes - main;
      if (defWarmUp + defCool > 0) {
        warmUp = ((defWarmUp / (defWarmUp + defCool)) * remaining).round();
        coolDown = remaining - warmUp;
      } else {
        warmUp = 0;
        coolDown = 0;
      }
    }

    return [
      WorkoutPhase(
        title: warmUpTitle,
        shortTitle: _getShortTitle(warmUpTitle),
        durationMinutes: warmUp,
        icon: warmUpIcon,
        description: warmUpDesc,
      ),
      WorkoutPhase(
        title: mainTitle,
        shortTitle: _getShortTitle(mainTitle),
        durationMinutes: main,
        icon: mainIcon,
        description: mainDesc,
      ),
      WorkoutPhase(
        title: coolTitle,
        shortTitle: _getShortTitle(coolTitle),
        durationMinutes: coolDown,
        icon: coolIcon,
        description: coolDesc,
      ),
    ];
  }

  static SmartSuggestion getSuggestion(String activityType, {double? temp}) {
    final normalized = _normalizeActivityType(activityType);

    switch (normalized) {
      case 'Running':
        return const SmartSuggestion(
          title: 'Best after 6:00 AM or evening',
          body: 'Avoid outdoor exercise if temperatures are very hot. Keep water close and consider indoor alternatives.',
        );
      case 'Walking':
        return const SmartSuggestion(
          title: 'Good for recovery & daily steps',
          body: 'An easy-paced walk is perfect for light active recovery or hitting your daily movement goals.',
        );
      case 'Cycling':
        return const SmartSuggestion(
          title: 'Check route & safety first',
          body: 'Verify your cycling path beforehand. Always wear your helmet and remain aware of local traffic.',
        );
      case 'Bike Ride':
        return const SmartSuggestion(
          title: 'Safety check before riding',
          body: 'Wear your helmet, check tyre pressure, and test your brakes before going out onto roads.',
        );
      case 'Yoga':
        return const SmartSuggestion(
          title: 'Quiet space suggested',
          body: 'Set up your yoga mat in a quiet, clutter-free room and focus on deep, controlled breathing.',
        );
      case 'Strength':
        return const SmartSuggestion(
          title: 'Start with joint mobility',
          body: 'Warm up your joints before lifting heavy. Avoid overtraining and rest at least 60-90s between sets.',
        );
      case 'Gym':
        return const SmartSuggestion(
          title: 'Warm up and safety first',
          body: 'Begin with 5-10m light cardio. Maintain proper form and avoid overtraining. Rest between sets.',
        );
      case 'Swimming':
        return const SmartSuggestion(
          title: 'Hydrate well before swimming',
          body: 'You still sweat in the pool! Ensure your shoulders are fully warmed up to prevent injury.',
        );
      case 'Meditation':
        return const SmartSuggestion(
          title: 'Find a calm environment',
          body: 'Silence your phone, sit upright, and focus on your breath without judgement.',
        );
      case 'Study':
        return const SmartSuggestion(
          title: 'Enable Focus Mode',
          body: 'Utilize Pomodoro: 45m deep focused work followed by a 10m break to rest your mind.',
        );
      case 'Stretching':
        return const SmartSuggestion(
          title: 'Hold stretches without bouncing',
          body: 'Move slowly and hold static stretches for 20-30s. Perfect for post-workout recovery.',
        );
      case 'HIIT':
        return const SmartSuggestion(
          title: 'High intensity warning',
          body: 'Perform a thorough warm-up. Keep intervals intense but maintain safety and form.',
        );
      case 'Rest / Recovery':
        return const SmartSuggestion(
          title: 'Recovery is progress',
          body: 'Rest days are crucial for muscle rebuilding and mental longevity. Drink plenty of water.',
        );
      default:
        return const SmartSuggestion(
          title: 'Crush your goals',
          body: 'Prepare your mind and body, stay hydrated, and perform your activity at a safe, steady pace.',
        );
    }
  }

  static String _normalizeActivityType(String type) {
    final lower = type.toLowerCase().trim();

    if (lower.contains('running') || lower == 'run' || lower == 'outdoor run' || lower == 'trail run' || lower == 'treadmill') {
      return 'Running';
    }
    if (lower.contains('walking') || lower == 'walk' || lower == 'outdoor walk') {
      return 'Walking';
    }
    if (lower == 'cycling' || lower == 'cycle' || lower == 'outdoor cycle') {
      return 'Cycling';
    }
    if (lower == 'bike ride' || lower == 'bike') {
      return 'Bike Ride';
    }
    if (lower == 'yoga') {
      return 'Yoga';
    }
    if (lower.contains('strength') || lower.contains('weight')) {
      return 'Strength';
    }
    if (lower == 'gym' || lower.contains('workout')) {
      return 'Gym';
    }
    if (lower.contains('swim')) {
      return 'Swimming';
    }
    if (lower.contains('meditat')) {
      return 'Meditation';
    }
    if (lower.contains('study') || lower.contains('focus') || lower.contains('deep work')) {
      return 'Study';
    }
    if (lower.contains('stretch')) {
      return 'Stretching';
    }
    if (lower == 'hiit' || lower.contains('cardio') || lower.contains('crossfit')) {
      return 'HIIT';
    }
    if (lower.contains('rest') || lower.contains('recovery')) {
      return 'Rest / Recovery';
    }

    return 'Unknown';
  }

  static String _getShortTitle(String title) {
    final lower = title.toLowerCase().trim();
    if (lower.contains('warm-up') || lower.contains('warmup')) {
      return 'Warm-up';
    }
    if (lower.contains('cooldown') || lower.contains('cool down')) {
      return 'Cooldown';
    }
    if (lower.contains('easy start')) return 'Start';
    if (lower.contains('safety check')) return 'Safety';
    if (lower.contains('focus prep')) return 'Prep';
    if (lower.contains('settle')) return 'Settle';
    if (lower.contains('breathing')) return 'Breathe';
    if (lower.contains('mobility')) return 'Mobility';
    
    if (lower.contains('run') || lower.contains('treadmill')) {
      return 'Run';
    }
    if (lower.contains('walk')) {
      return 'Walk';
    }
    if (lower.contains('cycle') || lower.contains('ride') || lower.contains('spin') || lower.contains('bike')) {
      return 'Ride';
    }
    if (lower.contains('yoga') || lower.contains('flow')) {
      return 'Flow';
    }
    if (lower.contains('strength')) {
      return 'Strength';
    }
    if (lower.contains('gym') || lower.contains('workout')) {
      return 'Workout';
    }
    if (lower.contains('swim') || lower.contains('laps')) {
      if (lower.contains('easy swim')) return 'Easy Swim';
      if (lower.contains('swim laps')) return 'Swim Laps';
      return 'Swim';
    }
    if (lower.contains('meditat')) {
      return 'Meditate';
    }
    if (lower.contains('study') || lower.contains('deep work') || lower.contains('focus')) {
      return 'Work';
    }
    if (lower.contains('stretch')) {
      return 'Stretch';
    }
    if (lower.contains('hiit')) {
      return 'HIIT';
    }
    if (lower.contains('rest') || lower.contains('recovery')) {
      return 'Rest';
    }
    if (lower.contains('break')) {
      return 'Break';
    }
    return title;
  }
}
