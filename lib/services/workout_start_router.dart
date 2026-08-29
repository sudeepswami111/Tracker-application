import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/workout_phase.dart';
import '../providers/app_provider.dart'; // for DailyPlan
import '../providers/workout_session_provider.dart';
import '../screens/running/running_screen.dart';
import '../screens/workout/guided_workout_session_screen.dart';

class WorkoutStartRouter {
  static bool isGpsActivity(String type) {
    final t = type.toLowerCase();
    return t.contains('run') ||
           t.contains('walk') ||
           t.contains('cycling') ||
           t.contains('bike ride') ||
           t.contains('outdoor');
  }

  static bool isGuidedActivity(String type) {
    final t = type.toLowerCase();
    return t.contains('yoga') ||
           t.contains('strength') ||
           t.contains('gym') ||
           t.contains('swimming') ||
           t.contains('meditation') ||
           t.contains('study') ||
           t.contains('stretch') ||
           t.contains('hiit') ||
           t.contains('rest') ||
           t.contains('recovery') ||
           t.contains('indoor');
  }

  static void startWorkoutFromPlan({
    required BuildContext context,
    required DailyPlan plan,
    required List<WorkoutPhase> phases,
  }) {
    // Start session state in provider
    try {
      context.read<WorkoutSessionProvider>().startSession(plan.id, phases.length);
    } catch (e) {
      debugPrint('[WorkoutStartRouter] Provider error: $e');
    }

    if (isGpsActivity(plan.type)) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RunningScreen(
            phases: phases,
            plan: plan,
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GuidedWorkoutSessionScreen(
            plan: plan,
            phases: phases,
          ),
        ),
      );
    }
  }
}
