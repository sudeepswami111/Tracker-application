import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

class DashboardInteractionStorageService {
  static const String boxName = 'dashboard_interactions';

  static String _formatDateKey(String prefix, DateTime date) {
    return '${prefix}_${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // --- Calendar Notes ---
  static Future<void> saveCalendarNote(DateTime date, String note) async {
    final box = await Hive.openBox(boxName);
    final key = _formatDateKey('calendar_note', date);
    await box.put(key, note);
    debugPrint('DashboardInteractionStorageService: Saved calendar note: $key -> $note');
  }

  static Future<String?> getCalendarNote(DateTime date) async {
    final box = await Hive.openBox(boxName);
    final key = _formatDateKey('calendar_note', date);
    final note = box.get(key);
    debugPrint('DashboardInteractionStorageService: Loaded calendar note: $key -> $note');
    return note as String?;
  }

  static Future<void> deleteCalendarNote(DateTime date) async {
    final box = await Hive.openBox(boxName);
    final key = _formatDateKey('calendar_note', date);
    await box.delete(key);
    debugPrint('DashboardInteractionStorageService: Deleted calendar note: $key');
  }

  // --- Calendar Reminders ---
  static Future<void> saveCalendarReminder(DateTime date, String reminderTimeOrData) async {
    final box = await Hive.openBox(boxName);
    final key = _formatDateKey('calendar_reminder', date);
    List<String> reminders = List<String>.from(box.get(key, defaultValue: []) ?? []);
    reminders.add(reminderTimeOrData);
    await box.put(key, reminders);
    debugPrint('DashboardInteractionStorageService: Saved calendar reminder: $key -> $reminderTimeOrData');
  }

  static Future<List<String>> getCalendarReminder(DateTime date) async {
    final box = await Hive.openBox(boxName);
    final key = _formatDateKey('calendar_reminder', date);
    final reminders = List<String>.from(box.get(key, defaultValue: []) ?? []);
    debugPrint('DashboardInteractionStorageService: Loaded calendar reminders: $key -> $reminders');
    return reminders;
  }

  static Future<void> deleteCalendarReminder(DateTime date) async {
    final box = await Hive.openBox(boxName);
    final key = _formatDateKey('calendar_reminder', date);
    await box.delete(key);
    debugPrint('DashboardInteractionStorageService: Deleted calendar reminder: $key');
  }

  // --- Daily Thought ---
  static Future<void> saveDailyMood(DateTime date, String mood) async {
    final box = await Hive.openBox(boxName);
    final key = _formatDateKey('daily_mood', date);
    await box.put(key, mood);
    debugPrint('DashboardInteractionStorageService: Saved daily mood: $key -> $mood');
  }

  static Future<String?> getDailyMood(DateTime date) async {
    final box = await Hive.openBox(boxName);
    final key = _formatDateKey('daily_mood', date);
    final mood = box.get(key);
    debugPrint('DashboardInteractionStorageService: Loaded daily mood: $key -> $mood');
    return mood as String?;
  }

  static Future<void> saveDailyReflection(DateTime date, String reflection) async {
    final box = await Hive.openBox(boxName);
    final key = _formatDateKey('daily_reflection', date);
    await box.put(key, reflection);
    debugPrint('DashboardInteractionStorageService: Saved daily reflection: $key -> $reflection');
  }

  static Future<String?> getDailyReflection(DateTime date) async {
    final box = await Hive.openBox(boxName);
    final key = _formatDateKey('daily_reflection', date);
    final reflection = box.get(key);
    debugPrint('DashboardInteractionStorageService: Loaded daily reflection: $key -> $reflection');
    return reflection as String?;
  }

  static Future<void> saveFavoriteThought(String thought) async {
    final box = await Hive.openBox(boxName);
    final key = 'favorite_thought_${thought.hashCode}';
    await box.put(key, thought);
    debugPrint('DashboardInteractionStorageService: Saved favorite thought: $key');
  }

  static Future<bool> isFavoriteThought(String thought) async {
    final box = await Hive.openBox(boxName);
    final key = 'favorite_thought_${thought.hashCode}';
    final result = box.containsKey(key);
    debugPrint('DashboardInteractionStorageService: Checked favorite thought: $key -> $result');
    return result;
  }
}
