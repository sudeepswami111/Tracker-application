import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class AppProvider extends ChangeNotifier {
  // ──── User ────
  final String userName = 'Alex';
  final int userLevel = 12;
  final int userXP = 2840;
  final int userXPToNext = 3500;

  // ──── Dashboard Stats ────
  int steps = 12450;
  final int stepsGoal = 15000;
  int calories = 2340;
  final int caloriesGoal = 3000;
  double distance = 8.2;
  final double distanceGoal = 10;
  double sleepHours = 7.5;
  final double sleepGoal = 8;
  double waterIntake = 2.1;
  final double waterGoal = 3;
  double studyHrs = 4.5;
  final double studyGoal = 6;

  // ──── Fitness ────
  int todayCalories = 2340;
  int todayDuration = 75;
  int todayExercises = 4;
  int weeklyGoal = 5;
  int weeklyCompleted = 3;
  List<double> bodyWeight = [82, 81.5, 81.8, 81.2, 80.9, 80.5, 80.2, 79.8, 80.1, 79.5, 79.2, 79, 78.8, 78.5];
  double bmi = 24.1;
  List<Map<String, dynamic>> workouts = [
    {'id': 1, 'type': 'Running', 'duration': 35, 'calories': 420, 'intensity': 'High', 'time': '7:00 AM', 'icon': Icons.directions_run},
    {'id': 2, 'type': 'Weight Training', 'duration': 45, 'calories': 380, 'intensity': 'Medium', 'time': '8:00 AM', 'icon': Icons.fitness_center},
    {'id': 3, 'type': 'Yoga', 'duration': 30, 'calories': 150, 'intensity': 'Low', 'time': '6:00 PM', 'icon': Icons.self_improvement},
    {'id': 4, 'type': 'Cycling', 'duration': 40, 'calories': 350, 'intensity': 'High', 'time': '5:00 PM', 'icon': Icons.pedal_bike},
  ];

  // ──── Health ────
  int heartRate = 72;
  final int restingHR = 62;
  final int maxHR = 185;
  double sleepQuality = 82;
  double sleepDeep = 2.1;
  double sleepLight = 3.8;
  double sleepREM = 1.6;
  double sleepAwake = 0.3;
  List<double> sleepWeekly = [7.2, 6.8, 7.5, 8.1, 7.0, 7.8, 7.5];
  int waterGlasses = 6;
  final int waterGlassGoal = 8;
  List<int> waterHistory = [8, 6, 7, 8, 5, 7, 6];
  double currentWeight = 78.5;
  final double targetWeight = 75;
  List<double> weightHistory = [82, 81.5, 81, 80.5, 80, 79.5, 79.2, 79, 78.8, 78.5];
  int wellnessScore = 85;
  String mood = 'great';
  int energy = 78;
  int stress = 32;
  int systolic = 120;
  int diastolic = 80;
  double temperature = 98.4;
  int oxygenLevel = 98;

  // ──── Study ────
  int studyStreak = 15;
  final int longestStreak = 28;
  int totalStudyMinutes = 270;
  bool focusTimerRunning = false;
  int focusTimerDuration = 25 * 60;
  int focusSessionsCompleted = 3;
  List<Map<String, dynamic>> studySessions = [
    {'id': 1, 'subject': 'Mathematics', 'duration': 120, 'color': const Color(0xFF6C5CE7), 'time': '9:00 AM'},
    {'id': 2, 'subject': 'Computer Science', 'duration': 90, 'color': const Color(0xFF00D2D3), 'time': '11:30 AM'},
    {'id': 3, 'subject': 'English Literature', 'duration': 60, 'color': const Color(0xFFFF6B6B), 'time': '2:00 PM'},
  ];
  List<Map<String, dynamic>> subjects = [
    {'name': 'Mathematics', 'hours': 45, 'progress': 72, 'color': const Color(0xFF6C5CE7)},
    {'name': 'Computer Science', 'hours': 38, 'progress': 65, 'color': const Color(0xFF00D2D3)},
    {'name': 'English Literature', 'hours': 22, 'progress': 48, 'color': const Color(0xFFFF6B6B)},
    {'name': 'Physics', 'hours': 30, 'progress': 55, 'color': const Color(0xFFFECA57)},
    {'name': 'History', 'hours': 15, 'progress': 35, 'color': const Color(0xFFF093FB)},
  ];
  List<List<int>> weeklyHeatmap = [
    [3, 2, 4, 1, 3, 0, 2],
    [2, 4, 3, 2, 1, 3, 1],
    [4, 3, 2, 4, 2, 1, 3],
    [1, 2, 3, 3, 4, 2, 0],
  ];
  List<Map<String, dynamic>> milestones = [
    {'id': 1, 'title': '7-Day Streak', 'achieved': true, 'icon': '🔥'},
    {'id': 2, 'title': '100 Hours Studied', 'achieved': true, 'icon': '📚'},
    {'id': 3, 'title': 'Early Bird', 'achieved': true, 'icon': '🌅'},
    {'id': 4, 'title': '30-Day Streak', 'achieved': false, 'icon': '💎', 'progress': 50},
    {'id': 5, 'title': '500 Hours Studied', 'achieved': false, 'icon': '🏆', 'progress': 30},
  ];

  // ──── Streaks ────
  final Map<String, int> streaks = {'Fitness': 12, 'Running': 5, 'Health': 8, 'Study': 15};

  // ──── Weekly Chart Data ────
  List<Map<String, dynamic>> get weeklyData {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final rng = Random(42); // Fixed seed for consistent data
    return days.map((day) => {
      'day': day,
      'fitness': (rng.nextInt(60) + 30).toDouble(),
      'running': (rng.nextInt(40) + 10).toDouble(),
      'study': (rng.nextInt(50) + 20).toDouble(),
    }).toList();
  }

  // ──── Goals ────
  List<Map<String, dynamic>> dailyGoals = [
    {'title': 'Walk 15,000 steps', 'progress': 83, 'category': 'fitness'},
    {'title': 'Drink 8 glasses of water', 'progress': 75, 'category': 'health'},
    {'title': 'Study for 6 hours', 'progress': 75, 'category': 'study'},
    {'title': 'Run 5 km', 'progress': 100, 'category': 'running'},
    {'title': 'Sleep 8 hours', 'progress': 94, 'category': 'health'},
  ];

  // ──── Insights ────
  final List<Map<String, String>> insights = [
    {'type': 'positive', 'message': 'Your running pace improved by 3% this week! Keep it up! 🏃‍♂️'},
    {'type': 'suggestion', 'message': 'Try adding a morning stretch routine to improve your flexibility score.'},
    {'type': 'warning', 'message': 'Your sleep duration has been below target for 3 days. Consider an earlier bedtime.'},
    {'type': 'positive', 'message': 'Study streak milestone: 15 days! You\'re building incredible consistency! 🔥'},
  ];

  // ──── Achievements ────
  List<Map<String, dynamic>> achievements = [
    {'title': 'Early Bird', 'icon': '🌅', 'unlocked': true},
    {'title': 'Marathoner', 'icon': '🏃', 'unlocked': true},
    {'title': 'Deep Work', 'icon': '🧠', 'unlocked': true},
    {'title': 'Hydration Hero', 'icon': '💧', 'unlocked': true},
    {'title': 'Iron Will', 'icon': '💪', 'unlocked': false, 'progress': 40},
    {'title': 'Speed Demon', 'icon': '⚡', 'unlocked': false, 'progress': 85},
  ];

  // ──── Live Data Simulation ────
  Timer? _liveTimer;

  void startLiveSimulation() {
    _liveTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      final rng = Random();
      heartRate = (heartRate + rng.nextInt(7) - 3).clamp(55, 100);
      steps += rng.nextInt(15) + 5;
      calories += rng.nextInt(3);
      notifyListeners();
    });
  }

  void stopLiveSimulation() {
    _liveTimer?.cancel();
  }

  // ──── Actions ────
  void addWater() {
    if (waterGlasses < 12) {
      waterGlasses++;
      waterIntake = double.parse((waterIntake + 0.25).toStringAsFixed(2));
      notifyListeners();
    }
  }

  void addWorkout(Map<String, dynamic> workout) {
    workouts.insert(0, workout);
    todayCalories += workout['calories'] as int;
    todayDuration += workout['duration'] as int;
    todayExercises++;
    notifyListeners();
  }

  void addStudySession(Map<String, dynamic> session) {
    studySessions.add(session);
    totalStudyMinutes += session['duration'] as int;
    notifyListeners();
  }

  void toggleFocusTimer() {
    focusTimerRunning = !focusTimerRunning;
    notifyListeners();
  }

  void completeFocusSession() {
    focusSessionsCompleted++;
    focusTimerRunning = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _liveTimer?.cancel();
    super.dispose();
  }
}
