import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../services/notification_service.dart';

class AppProvider extends ChangeNotifier {
  final SharedPreferences prefs;

  AppProvider(this.prefs) {
    _loadData();
  }
  // ──── User ────
  String userName = 'User';
  String email = 'user@example.com';
  String profileImagePath = '';
  int userLevel = 1;
  int userXP = 0;
  int userXPToNext = 1000;
  bool isMetric = true;

  // ──── Dashboard Stats ────
  int steps = 0;
  final int stepsGoal = 10000;
  int calories = 0;
  final int caloriesGoal = 2500;
  double distance = 0.0;
  final double distanceGoal = 5.0;
  double sleepHours = 0.0;
  final double sleepGoal = 8.0;
  double waterIntake = 0.0;
  final double waterGoal = 2.0;
  double studyHrs = 0.0;
  final double studyGoal = 4.0;

  // ──── Fitness ────
  int todayCalories = 0;
  int todayDuration = 0;
  int todayExercises = 0;
  int weeklyGoal = 3;
  int weeklyCompleted = 0;
  List<double> bodyWeight = [];
  double bmi = 0.0;
  List<Map<String, dynamic>> workouts = [];

  // ──── Health ────
  int heartRate = 0;
  final int restingHR = 60;
  final int maxHR = 190;
  double sleepQuality = 0;
  double sleepDeep = 0;
  double sleepLight = 0;
  double sleepREM = 0;
  double sleepAwake = 0;
  List<double> sleepWeekly = [];
  int waterGlasses = 0;
  final int waterGlassGoal = 8;
  List<int> waterHistory = [];
  double currentWeight = 0;
  final double targetWeight = 0;
  List<double> weightHistory = [];
  int wellnessScore = 0;
  String mood = 'neutral';
  int energy = 50;
  int stress = 50;
  int systolic = 120;
  int diastolic = 80;
  double temperature = 98.6;
  int oxygenLevel = 98;

  // ──── Study ────
  int studyStreak = 0;
  final int longestStreak = 0;
  int totalStudyMinutes = 0;
  bool focusTimerRunning = false;
  int focusTimerDuration = 25 * 60;
  int focusSessionsCompleted = 0;
  List<Map<String, dynamic>> studySessions = [];
  List<Map<String, dynamic>> subjects = [];
  List<List<int>> weeklyHeatmap = [
    [0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0],
  ];
  List<Map<String, dynamic>> milestones = [];

  // ──── Streaks ────
  final Map<String, int> streaks = {};

  // ──── Weekly Chart Data ────
  List<Map<String, dynamic>> get weeklyData {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days.map((day) => {
      'day': day,
      'fitness': 0.0,
      'running': 0.0,
      'study': 0.0,
    }).toList();
  }

  List<Map<String, dynamic>> dailyGoals = [];

  bool hasUnreadNotifications = false;
  List<Map<String, dynamic>> notifications = [];

  bool get hasCompletedTasks => dailyGoals.any((goal) => (goal['progress'] as num) >= 100);

  // ──── Insights ────
  final List<Map<String, String>> insights = [];

  // ──── Achievements ────
  List<Map<String, dynamic>> achievements = [];

  // ──── Live Data Simulation ────
  Timer? _liveTimer;

  void startLiveSimulation() {
    _liveTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (heartRate == 0) heartRate = 60;
      final rng = Random();
      heartRate = (heartRate + rng.nextInt(7) - 3).clamp(55, 100);
      steps += rng.nextInt(5);
      notifyListeners();
      _saveData();
    });
  }

  void stopLiveSimulation() {
    _liveTimer?.cancel();
  }

  void _loadData() {
    userName = prefs.getString('userName') ?? 'User';
    profileImagePath = prefs.getString('profileImagePath') ?? '';
    isMetric = prefs.getBool('isMetric') ?? true;
    steps = prefs.getInt('steps') ?? 0;
    distance = prefs.getDouble('distance') ?? 0.0;
    waterGlasses = prefs.getInt('waterGlasses') ?? 0;
    waterIntake = prefs.getDouble('waterIntake') ?? 0.0;
    notifyListeners();
  }

  void _saveData() {
    prefs.setString('userName', userName);
    prefs.setString('profileImagePath', profileImagePath);
    prefs.setBool('isMetric', isMetric);
    prefs.setInt('steps', steps);
    prefs.setDouble('distance', distance);
    prefs.setInt('waterGlasses', waterGlasses);
    prefs.setDouble('waterIntake', waterIntake);
  }

  void updateUserName(String newName) {
    userName = newName;
    _saveData();
    notifyListeners();
  }

  void updateProfileImagePath(String newPath) {
    profileImagePath = newPath;
    _saveData();
    notifyListeners();
  }

  void toggleUnitSystem() {
    isMetric = !isMetric;
    _saveData();
    notifyListeners();
  }

  void markNotificationsRead() {
    hasUnreadNotifications = false;
    notifyListeners();
  }

  void addNotification(String title, String subtitle, IconData icon, Color color) {
    notifications.insert(0, {'title': title, 'subtitle': subtitle, 'icon': icon, 'color': color});
    hasUnreadNotifications = true;
    notifyListeners();
  }

  void _showGoalPopup(String title, String subtitle, IconData icon) {
    final context = navigatorKey.currentContext;
    if (context != null) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(children: [
            Icon(icon, color: Colors.blue, size: 28),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold))),
          ]),
          content: Text(subtitle, style: const TextStyle(fontSize: 16)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Awesome!', style: TextStyle(fontWeight: FontWeight.bold)),
            )
          ],
        ),
      );
    }
  }

  // ──── Actions ────
  void addWater() {
    if (waterGlasses < 12) {
      waterGlasses++;
      waterIntake = double.parse((waterIntake + 0.25).toStringAsFixed(2));
      _saveData();
      notifyListeners();

      if (waterGlasses == waterGlassGoal) {
        addNotification('Goal Reached!', 'You hit your water intake goal.', LucideIcons.droplets, Colors.blue);
        _showGoalPopup('Hydration Hero', 'You reached your daily water goal of $waterGlassGoal glasses!', LucideIcons.droplets);
      }
    }
  }

  void addWorkout(Map<String, dynamic> workout) {
    workouts.insert(0, workout);
    todayCalories += workout['calories'] as int;
    todayDuration += workout['duration'] as int;
    todayExercises++;
    _saveData();
    notifyListeners();
  }

  void addStudySession(Map<String, dynamic> session) {
    studySessions.add(session);
    totalStudyMinutes += session['duration'] as int;
    _saveData();
    notifyListeners();
  }

  void toggleFocusTimer() {
    focusTimerRunning = !focusTimerRunning;
    if (focusTimerRunning) {
      NotificationService.showNotification('Activity Started!', 'Focus Timer is running.');
    }
    notifyListeners();
  }

  void completeFocusSession() {
    focusSessionsCompleted++;
    focusTimerRunning = false;
    _saveData();
    notifyListeners();
  }

  @override
  void dispose() {
    _liveTimer?.cancel();
    super.dispose();
  }
}
