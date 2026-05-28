import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import '../services/notification_service.dart';

// ──── 2.1 Daily Snapshot Model ────
class DailySnapshot {
  final String date; // yyyy-MM-dd
  final int steps;
  final int calories;
  final double distanceKm;
  final double sleepHours;
  final double waterIntake;
  final double studyHrs;
  final int waterGlasses;
  final int pulseScore;

  const DailySnapshot({
    required this.date,
    required this.steps,
    required this.calories,
    required this.distanceKm,
    required this.sleepHours,
    required this.waterIntake,
    required this.studyHrs,
    required this.waterGlasses,
    required this.pulseScore,
  });

  Map<String, dynamic> toJson() => {
        'date': date,
        'steps': steps,
        'calories': calories,
        'distanceKm': distanceKm,
        'sleepHours': sleepHours,
        'waterIntake': waterIntake,
        'studyHrs': studyHrs,
        'waterGlasses': waterGlasses,
        'pulseScore': pulseScore,
      };

  factory DailySnapshot.fromJson(Map<String, dynamic> json) => DailySnapshot(
        date: json['date'] as String? ?? '',
        steps: (json['steps'] as num?)?.toInt() ?? 0,
        calories: (json['calories'] as num?)?.toInt() ?? 0,
        distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0.0,
        sleepHours: (json['sleepHours'] as num?)?.toDouble() ?? 0.0,
        waterIntake: (json['waterIntake'] as num?)?.toDouble() ?? 0.0,
        studyHrs: (json['studyHrs'] as num?)?.toDouble() ?? 0.0,
        waterGlasses: (json['waterGlasses'] as num?)?.toInt() ?? 0,
        pulseScore: (json['pulseScore'] as num?)?.toInt() ?? 0,
      );
}

class DailyPlan {
  final String id;
  final String title;
  final String duration;
  final String kcal;
  final String imageUrl;
  final String type;
  bool isCompleted;

  DailyPlan({
    required this.id,
    required this.title,
    required this.duration,
    required this.kcal,
    required this.imageUrl,
    this.type = 'Run',
    this.isCompleted = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'duration': duration,
        'kcal': kcal,
        'imageUrl': imageUrl,
        'type': type,
        'isCompleted': isCompleted,
      };

  factory DailyPlan.fromJson(Map<String, dynamic> json) => DailyPlan(
        id: json['id'] as String,
        title: json['title'] as String,
        duration: json['duration'] as String,
        kcal: json['kcal'] as String,
        imageUrl: json['imageUrl'] as String,
        type: json['type'] as String? ?? 'Run',
        isCompleted: json['isCompleted'] as bool? ?? false,
      );
}

// ──── Feature 4 — Challenge Model ────
class ChallengeModel {
  final String title;
  final double targetValue;
  double currentValue;
  final String metric;
  final int daysLeft;
  bool isCompleted;
  bool claimed;

  ChallengeModel({
    required this.title,
    required this.targetValue,
    required this.currentValue,
    required this.metric,
    required this.daysLeft,
    this.isCompleted = false,
    this.claimed = false,
  });

  void refresh(double liveValue) {
    currentValue = liveValue;
    isCompleted = currentValue >= targetValue;
  }
}

class PrefsKeys {
  static const userName = 'userName';
  static const avatarUrl = 'avatarUrl';
  static const isMetric = 'isMetric';
  static const steps = 'steps';
  static const distance = 'distance';
  static const waterGlasses = 'waterGlasses';
  static const waterIntake = 'waterIntake';
  static const calories = 'calories';
  static const sleepHours = 'sleepHours';
  static const studyHrs = 'studyHrs';
  static const dailyHistory = 'dailyHistory';
  static const currentStreak = 'currentStreak';
  static const streakFreezes = 'streakFreezes';
  static const isStreakPending = 'isStreakPending';
  static const lastActivityDate = 'lastActivityDate';
  static const dailyPlans = 'dailyPlans';
  static const lastSavedDate = 'lastSavedDate';
  static const completedTasksCount = 'completedTasksCount';
}

class AppProvider extends ChangeNotifier with WidgetsBindingObserver {
  final SharedPreferences prefs;
  DateTime Function() clock;

  AppProvider(this.prefs, {this.clock = DateTime.now}) {
    WidgetsBinding.instance.addObserver(this);
    _loadData();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkDailyReset();
    }
  }
  // ──── User ────
  String userName = 'User';
  int completedTasksCount = 0;
  String email = 'user@example.com';
  String avatarUrl = '';
  int userLevel = 1;
  int userXP = 0;
  int userXPToNext = 1000;
  bool isMetric = true;

  // ──── Settings Persistence ────
  bool healthConnectEnabled = true;
  bool masterNotifications = true;
  bool workoutReminders = true;
  bool studyReminders = false;
  double dailyStepsGoal = 10000.0;
  int pomodoroDuration = 25;

  // ──── Nutrition Streak ────
  int nutritionStreak = 0;
  int longestNutritionStreak = 0;

  // ──── Dashboard Stats ────
  int steps = 0;
  int get stepsGoal => dailyStepsGoal.toInt();
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
  int longestStreak = 0;
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
  int currentStreak = 1;
  int streakFreezes = 0;
  bool isStreakPending = false;
  String lastActivityDate = '';

  void updateStreak() {
    final today = DateUtils.dateOnly(clock());
    if (lastActivityDate.isEmpty) {
      currentStreak = 1;
      if (currentStreak > longestStreak) {
        longestStreak = currentStreak;
      }
      lastActivityDate = today.toIso8601String();
      isStreakPending = false;
      _saveData();
      notifyListeners();
      return;
    }

    final lastActive = DateUtils.dateOnly(DateTime.parse(lastActivityDate));
    final diffDays = today.difference(lastActive).inDays;

    if (diffDays == 0) return; // Idempotent: already updated today

    if (diffDays == 1) {
      currentStreak++;
    } else if (diffDays == 2 && streakFreezes > 0) {
      streakFreezes--;
      currentStreak++; // Saved by freeze
    } else if (diffDays >= 2) {
      if (currentStreak > 1) {
        _showStreakResetSnackbar();
      }
      currentStreak = 1;
    }

    if (currentStreak > longestStreak) {
      longestStreak = currentStreak;
    }

    // Streak milestone notification every 7 days
    if (currentStreak > 0 && currentStreak % 7 == 0) {
      addNotification(
        '🔥 ${currentStreak}-Day Streak!',
        "You've been active for $currentStreak days in a row!",
        type: 'streak',
      );
    }

    lastActivityDate = today.toIso8601String();
    isStreakPending = false;
    _saveData();
    notifyListeners();
  }

  void recordActivity() {
    updateStreak();
  }

  void checkStreakStatus() {
    final today = DateUtils.dateOnly(clock());
    if (lastActivityDate.isEmpty) {
      isStreakPending = false;
      return;
    }

    final lastActive = DateUtils.dateOnly(DateTime.parse(lastActivityDate));
    final diffDays = today.difference(lastActive).inDays;

    if (diffDays == 0) {
      isStreakPending = false;
    } else if (diffDays == 1) {
      isStreakPending = true; // Pending for today
    } else if (diffDays == 2 && streakFreezes > 0) {
      isStreakPending = true; // Still pending, can be saved by freeze
    } else if (diffDays >= 2) {
      if (currentStreak > 1) {
        _showStreakResetSnackbar();
      }
      currentStreak = 0;
      isStreakPending = false;
    }
  }

  void _showStreakResetSnackbar() {
    final context = navigatorKey.currentContext;
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Oops! You missed a day. Your streak has been reset.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // ──── Navigation ────
  int currentTabIndex = 0;
  void setTabIndex(int index) {
    currentTabIndex = index;
    notifyListeners();
  }

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

  // ──── Daily Plans ────
  List<DailyPlan> dailyPlans = [];
  DailyPlan? activeRunPlan;

  void setActiveRunPlan(DailyPlan? plan) {
    activeRunPlan = plan;
    notifyListeners();
  }

  void addDailyPlan(DailyPlan plan) {
    dailyPlans.add(plan);
    _saveData();
    notifyListeners();
  }

  void removeDailyPlan(String id) {
    dailyPlans.removeWhere((p) => p.id == id);
    _saveData();
    notifyListeners();
  }

  void togglePlanComplete(String id) {
    final idx = dailyPlans.indexWhere((p) => p.id == id);
    if (idx != -1) {
      final wasCompleted = dailyPlans[idx].isCompleted;
      dailyPlans[idx].isCompleted = !wasCompleted;
      if (dailyPlans[idx].isCompleted) {
        completedTasksCount++;
      } else {
        completedTasksCount = (completedTasksCount - 1).clamp(0, 9999999).toInt();
      }
      _saveData();
      notifyListeners();
    }
  }

  bool hasUnreadNotifications = false;
  int _supabaseUnreadCount = 0;
  int get unreadNotificationCount => _supabaseUnreadCount;
  List<Map<String, dynamic>> notifications = [];

  void setUnreadCount(int count) {
    _supabaseUnreadCount = count;
    hasUnreadNotifications = count > 0;
    notifyListeners();
  }

  // ──── 2.1 History ────
  List<DailySnapshot> history = [];

  // ──── Feature 4 Challenges ────
  List<ChallengeModel> activeChallenges = [];

  bool get hasCompletedTasks => dailyGoals.any((goal) => (goal['progress'] as num) >= 100);

  // ──── 2.4 Pulse Score (0-100) — 5-factor weighted ────
  int get pulseScore {
    final stepsP  = (steps / stepsGoal).clamp(0.0, 1.0);
    final calP    = (todayCalories / caloriesGoal).clamp(0.0, 1.0);
    final waterP  = (waterGlasses / waterGlassGoal).clamp(0.0, 1.0);
    final sleepP  = (sleepHours / sleepGoal).clamp(0.0, 1.0);
    final studyP  = (studyHrs / studyGoal).clamp(0.0, 1.0);
    return ((stepsP * 0.25 + calP * 0.20 + waterP * 0.20 + sleepP * 0.20 + studyP * 0.15) * 100).round();
  }

  // ──── Insights ────
  final List<Map<String, String>> insights = [];

  // ──── Achievements ────
  List<Map<String, dynamic>> achievements = [];

  // ──── Live Data Simulation ────
  Timer? _liveTimer;
  Timer? _resetTimer; // 2.2 Hourly midnight-check timer

  void startLiveSimulation() {
    _liveTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (heartRate == 0) heartRate = 60;
      final rng = Random();
      heartRate = (heartRate + rng.nextInt(7) - 3).clamp(55, 100);
      // steps += rng.nextInt(5); // Removed demo steps
      notifyListeners();
      _saveData();
      // Smart nudges — checks hour internally, fires at most once/day per nudge
      await NotificationService.scheduleSmartNudges(this);
    });
    // Check for midnight reset every 30 seconds for near-instant detection
    _resetTimer = Timer.periodic(const Duration(seconds: 30), (_) => _checkDailyReset());
  }

  void stopLiveSimulation() {
    _liveTimer?.cancel();
    _resetTimer?.cancel();
  }

  void _loadData() {
    userName = prefs.getString(PrefsKeys.userName) ?? 'User';
    avatarUrl = prefs.getString(PrefsKeys.avatarUrl) ?? '';
    isMetric = prefs.getBool(PrefsKeys.isMetric) ?? true;
    steps = prefs.getInt(PrefsKeys.steps) ?? 0;
    distance = prefs.getDouble(PrefsKeys.distance) ?? 0.0;
    waterGlasses = prefs.getInt(PrefsKeys.waterGlasses) ?? 0;
    waterIntake = prefs.getDouble(PrefsKeys.waterIntake) ?? 0.0;
    calories = prefs.getInt(PrefsKeys.calories) ?? 0;
    sleepHours = prefs.getDouble(PrefsKeys.sleepHours) ?? 0.0;
    studyHrs = prefs.getDouble(PrefsKeys.studyHrs) ?? 0.0;
    longestStreak = prefs.getInt('longestStreak') ?? 0;
    healthConnectEnabled = prefs.getBool('healthConnectEnabled') ?? true;
    masterNotifications = prefs.getBool('masterNotifications') ?? true;
    workoutReminders = prefs.getBool('workoutReminders') ?? true;
    studyReminders = prefs.getBool('studyReminders') ?? false;
    dailyStepsGoal = prefs.getDouble('dailyStepsGoal') ?? 10000.0;
    pomodoroDuration = prefs.getInt('pomodoroDuration') ?? 25;
    nutritionStreak = prefs.getInt('nutritionStreak') ?? 0;
    longestNutritionStreak = prefs.getInt('longestNutritionStreak') ?? 0;
    // 2.1 — Load history
    final histJson = prefs.getString(PrefsKeys.dailyHistory);
    if (histJson != null) {
      try {
        final decoded = jsonDecode(histJson) as List<dynamic>;
        history = decoded
            .map((e) => DailySnapshot.fromJson(e as Map<String, dynamic>))
            .toList()
            .reversed
            .toList(); // newest first
      } catch (_) {
        history = [];
      }
    }
    currentStreak = prefs.getInt(PrefsKeys.currentStreak) ?? 1;
    streakFreezes = prefs.getInt(PrefsKeys.streakFreezes) ?? 0;
    isStreakPending = prefs.getBool(PrefsKeys.isStreakPending) ?? false;
    lastActivityDate = prefs.getString(PrefsKeys.lastActivityDate) ?? '';
    completedTasksCount = prefs.getInt(PrefsKeys.completedTasksCount) ?? 0;
    
    // Load Daily Plans
    final plansJson = prefs.getString(PrefsKeys.dailyPlans);
    if (plansJson != null) {
      try {
        final decoded = jsonDecode(plansJson) as List<dynamic>;
        dailyPlans = decoded.map((e) => DailyPlan.fromJson(e as Map<String, dynamic>)).toList();
      } catch (_) {}
    }

    // 2.2 — Detect midnight and reset if new day
    _checkDailyReset();
    checkStreakStatus();
    // I5 — Generate weekly challenges every Monday
    final lastGenerated = prefs.getString('lastChallengesGenerated') ?? '';
    final today = _todayStr();
    if (lastGenerated != today && DateTime.now().weekday == DateTime.monday) {
      generateWeeklyChallenges();
      prefs.setString('lastChallengesGenerated', today);
    }
    notifyListeners();
  }

  // ──── 2.2 Midnight Detection ────
  String _todayStr() {
    final now = clock();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  void _checkDailyReset() {
    final today = _todayStr();
    final lastSaved = prefs.getString(PrefsKeys.lastSavedDate) ?? '';
    if (lastSaved == today) return; // same day, no reset needed

    debugPrint('[LifePulse] Day changed: $lastSaved → $today — resetting daily counters');

    // Snapshot yesterday's data before reset (only if we had a previous day)
    if (lastSaved.isNotEmpty) {
      final snapshot = DailySnapshot(
        date: lastSaved,
        steps: steps,
        calories: calories,
        distanceKm: distance,
        sleepHours: sleepHours,
        waterIntake: waterIntake,
        studyHrs: studyHrs,
        waterGlasses: waterGlasses,
        pulseScore: pulseScore,
      );
      history.insert(0, snapshot);
      // Persist history (keep last 90 days)
      if (history.length > 90) history = history.sublist(0, 90);
      final encoded = jsonEncode(history.map((s) => s.toJson()).toList());
      prefs.setString(PrefsKeys.dailyHistory, encoded);
    }

    // Reset ALL daily counters to zero
    steps = 0;
    calories = 0;
    distance = 0.0;
    sleepHours = 0.0;
    waterGlasses = 0;
    waterIntake = 0.0;
    studyHrs = 0.0;
    todayCalories = 0;
    todayDuration = 0;
    todayExercises = 0;
    workouts = [];

    // Stamp today so we don't reset again until tomorrow
    prefs.setString(PrefsKeys.lastSavedDate, today);
    _saveData();
    notifyListeners();
  }

  void _saveData() {
    prefs.setString(PrefsKeys.userName, userName);
    prefs.setString(PrefsKeys.avatarUrl, avatarUrl);
    prefs.setBool(PrefsKeys.isMetric, isMetric);
    prefs.setInt(PrefsKeys.steps, steps);
    prefs.setInt(PrefsKeys.calories, calories);
    prefs.setDouble(PrefsKeys.distance, distance);
    prefs.setDouble(PrefsKeys.sleepHours, sleepHours);
    prefs.setInt(PrefsKeys.waterGlasses, waterGlasses);
    prefs.setDouble(PrefsKeys.waterIntake, waterIntake);
    prefs.setDouble(PrefsKeys.studyHrs, studyHrs);
    prefs.setInt(PrefsKeys.currentStreak, currentStreak);
    prefs.setInt(PrefsKeys.streakFreezes, streakFreezes);
    prefs.setBool(PrefsKeys.isStreakPending, isStreakPending);
    prefs.setString(PrefsKeys.lastActivityDate, lastActivityDate);
    prefs.setInt(PrefsKeys.completedTasksCount, completedTasksCount);
    prefs.setInt('longestStreak', longestStreak);
    prefs.setBool('healthConnectEnabled', healthConnectEnabled);
    prefs.setBool('masterNotifications', masterNotifications);
    prefs.setBool('workoutReminders', workoutReminders);
    prefs.setBool('studyReminders', studyReminders);
    prefs.setDouble('dailyStepsGoal', dailyStepsGoal);
    prefs.setInt('pomodoroDuration', pomodoroDuration);
    prefs.setInt('nutritionStreak', nutritionStreak);
    prefs.setInt('longestNutritionStreak', longestNutritionStreak);
    
    // Save Daily Plans
    final plansEncoded = jsonEncode(dailyPlans.map((p) => p.toJson()).toList());
    prefs.setString(PrefsKeys.dailyPlans, plansEncoded);

    // Feature 3 — fire smart nudges after every save
    NotificationService.scheduleSmartNudges(this);
  }

  void updateUserName(String newName) async {
    userName = newName;
    _saveData();
    notifyListeners();

    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        // Try to update, if it fails maybe row doesn't exist, but we assume it does via sync
        await Supabase.instance.client
            .from('profiles')
            .update({'name': newName})
            .eq('id', user.id);
      } catch (e) {
        debugPrint("Error updating profile: \$e");
      }
    }
  }

  Future<void> syncProfileWithSupabase() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (data != null) {
        if (data['name'] != null) {
          userName = data['name'] as String;
        } else if (data['full_name'] != null) {
          userName = data['full_name'] as String;
        }
        if (data['avatar_url'] != null) {
          avatarUrl = data['avatar_url'] as String;
        }
      } else {
        // Insert initial data if row doesn't exist
        await Supabase.instance.client.from('profiles').insert({
          'id': user.id,
          'name': userName,
        });
      }
      email = user.email ?? email;
      _saveData();
      notifyListeners();
    } catch (e) {
      debugPrint("Error syncing profile: \$e");
    }
  }

  Future<void> uploadProfileImage(File file) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    
    try {
      final fileName = '${user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await Supabase.instance.client.storage
          .from('avatars')
          .upload(fileName, file, fileOptions: const FileOptions(cacheControl: '3600', upsert: true));
          
      final String publicUrl = Supabase.instance.client.storage
          .from('avatars')
          .getPublicUrl(fileName);
          
      // Update the profiles table so other users see the new avatar
      await Supabase.instance.client
          .from('profiles')
          .update({'avatar_url': publicUrl})
          .eq('id', user.id);
          
      avatarUrl = publicUrl;
      _saveData();
      notifyListeners();
      
      await Supabase.instance.client
          .from('profiles')
          .update({'avatar_url': publicUrl})
          .eq('id', user.id);
          
    } catch (e) {
      debugPrint("Error uploading profile image: $e");
      rethrow;
    }
  }

  void updateAvatarUrl(String newUrl) {
    avatarUrl = newUrl;
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

  void markAllNotificationsRead() {
    for (final n in notifications) {
      n['isRead'] = true;
    }
    hasUnreadNotifications = false;
    notifyListeners();
  }

  void markNotificationRead(String id) {
    final index = notifications.indexWhere((n) => n['id'] == id);
    if (index != -1) {
      notifications[index]['isRead'] = true;
    }
    hasUnreadNotifications = notifications.any((n) => !(n['isRead'] as bool));
    notifyListeners();
  }

  void removeNotification(String id) {
    notifications.removeWhere((n) => n['id'] == id);
    hasUnreadNotifications = notifications.any((n) => !(n['isRead'] as bool));
    notifyListeners();
  }

  Future<void> addNotification(String title, String body, {String type = 'achievement'}) async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;

    // Insert to Supabase so it appears in NotificationsScreen
    try {
      await Supabase.instance.client.from('notifications').insert({
        'user_id': uid,
        'type': type,
        'title': title,
        'body': body,
        'is_read': false,
      });
    } catch (e) {
      debugPrint('addNotification Supabase error: $e');
    }

    // Update badge count for immediate UI feedback
    _supabaseUnreadCount++;
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
    recordActivity();
    if (waterGlasses < 12) {
      waterGlasses++;
      waterIntake = double.parse((waterIntake + 0.25).toStringAsFixed(2));
      _saveData();
      notifyListeners();

      if (waterGlasses == waterGlassGoal) {
        addNotification('Hydration Hero! 💧', 'You reached your daily water goal of $waterGlassGoal glasses!', type: 'achievement');
        _showGoalPopup('Hydration Hero', 'You reached your daily water goal of $waterGlassGoal glasses!', LucideIcons.droplets);
      }
    }
  }

  void removeWater() {
    if (waterGlasses > 0) {
      waterGlasses--;
      waterIntake = (waterIntake - 0.25).clamp(0.0, double.infinity);
      waterIntake = double.parse(waterIntake.toStringAsFixed(2));
      _saveData();
      notifyListeners();
    }
  }

  // ──── 3.3/3.4 Update from HealthService sync ────
  void updateFromHealth(Map<String, dynamic> data) {
    if (data.isEmpty) return;
    if (data['heartRate'] != null && (data['heartRate'] as int) > 0) {
      heartRate = data['heartRate'] as int;
    }
    if (data['steps'] != null && (data['steps'] as int) > steps) {
      steps = data['steps'] as int;
    }
    if (data['sleepHours'] != null && (data['sleepHours'] as double) > 0) {
      sleepHours = data['sleepHours'] as double;
    }
    if (data['oxygenLevel'] != null && (data['oxygenLevel'] as int) > 0) {
      oxygenLevel = data['oxygenLevel'] as int;
    }
    _saveData();
    notifyListeners();
  }

  void updateSteps(int newSteps) {
    steps = newSteps;
    calories = (newSteps * 0.04).round();
    distance = newSteps * 0.00078;
    _saveData();
    notifyListeners();
  }

  void addWorkout(Map<String, dynamic> workout) {
    recordActivity();
    workouts.insert(0, workout);
    todayCalories += workout['calories'] as int;
    todayDuration += workout['duration'] as int;
    todayExercises++;
    _saveData();
    notifyListeners();
  }

  void addStudySession(Map<String, dynamic> session) {
    recordActivity();
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

  // ──── Feature 4 — Weekly Challenge Generator ────
  void generateWeeklyChallenges() {
    // Use last 7 snapshots; fall back to current values if not enough history
    final recent = history.take(7).toList();
    double avgSteps = steps.toDouble();
    double avgCal = todayCalories.toDouble();
    double avgStudy = studyHrs;

    if (recent.isNotEmpty) {
      avgSteps = recent.map((s) => s.steps.toDouble()).reduce((a, b) => a + b) / recent.length;
      avgCal   = recent.map((s) => s.calories.toDouble()).reduce((a, b) => a + b) / recent.length;
      avgStudy = recent.map((s) => s.studyHrs).reduce((a, b) => a + b) / recent.length;
    }

    const boost = 1.15; // +15%
    final now = DateTime.now();
    final daysLeft = 7 - now.weekday + 1;

    activeChallenges = [
      ChallengeModel(
        title: 'Walk ${(avgSteps * boost * 7).round()} steps this week',
        targetValue: avgSteps * boost * 7,
        currentValue: steps.toDouble(),
        metric: 'steps',
        daysLeft: daysLeft,
      ),
      ChallengeModel(
        title: 'Burn ${(avgCal * boost * 7).round()} kcal this week',
        targetValue: avgCal * boost * 7,
        currentValue: todayCalories.toDouble(),
        metric: 'calories',
        daysLeft: daysLeft,
      ),
      ChallengeModel(
        title: 'Study ${(avgStudy * boost * 7).toStringAsFixed(1)} hrs this week',
        targetValue: avgStudy * boost * 7,
        currentValue: studyHrs,
        metric: 'studyHrs',
        daysLeft: daysLeft,
      ),
    ];
    for (final c in activeChallenges) {
      c.isCompleted = c.currentValue >= c.targetValue;
    }
    notifyListeners();
  }

  // I7 — Updated claimChallenge: accepts title and rank directly
  void claimChallenge(String challengeTitle, int rank) {
    achievements.add({
      'title': challengeTitle,
      'icon': LucideIcons.trophy,
      'unlocked': true,
      'description': 'Finished #$rank',
    });
    notifyListeners();
    _saveData();
  }

  // Legacy overload kept for backward compat with ChallengeModel-based calls
  void claimChallengeModel(ChallengeModel c) {
    if (!c.isCompleted || c.claimed) return;
    c.claimed = true;
    claimChallenge(c.title, 1);
  }

  // ──── Settings Setters ────
  void setHealthConnectEnabled(bool v) {
    healthConnectEnabled = v;
    _saveData();
    notifyListeners();
  }

  void setMasterNotifications(bool v) {
    masterNotifications = v;
    _saveData();
    notifyListeners();
  }

  void setWorkoutReminders(bool v) {
    workoutReminders = v;
    _saveData();
    notifyListeners();
  }

  void setStudyReminders(bool v) {
    studyReminders = v;
    _saveData();
    notifyListeners();
  }

  void setDailyStepsGoal(double v) {
    dailyStepsGoal = v;
    _saveData();
    notifyListeners();
  }

  void setPomodoroDuration(int v) {
    pomodoroDuration = v;
    _saveData();
    notifyListeners();
  }

  void setNutritionStreak(int v) {
    nutritionStreak = v;
    if (nutritionStreak > longestNutritionStreak) {
      longestNutritionStreak = nutritionStreak;
    }
    _saveData();
    notifyListeners();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _liveTimer?.cancel();
    _resetTimer?.cancel();
    super.dispose();
  }
}
