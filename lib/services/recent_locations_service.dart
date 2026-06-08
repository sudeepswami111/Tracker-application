import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/location_suggestion.dart';

/// Persists and retrieves the user's recently selected locations.
/// Stores up to [maxCount] entries in SharedPreferences as a JSON array.
class RecentLocationsService {
  static const String _prefsKey = 'recent_locations_v1';
  static const int maxCount = 5;

  // ── Singleton ──────────────────────────────────────────────────────────────
  static final RecentLocationsService _instance =
      RecentLocationsService._internal();
  factory RecentLocationsService() => _instance;
  RecentLocationsService._internal();

  // In-memory cache of recents so we don't hit disk on every call.
  List<LocationSuggestion>? _cached;

  /// Returns the list of recently used locations (newest first).
  Future<List<LocationSuggestion>> getRecentLocations() async {
    if (_cached != null) return List.unmodifiable(_cached!);
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null || raw.isEmpty) {
        _cached = [];
        return [];
      }
      final list = (jsonDecode(raw) as List)
          .map((e) => LocationSuggestion.fromJson(e as Map<String, dynamic>))
          .toList();
      _cached = list;
      return List.unmodifiable(list);
    } catch (e) {
      _cached = [];
      return [];
    }
  }

  /// Saves a newly selected suggestion to the top of the list.
  /// Deduplicates by [shortName] and keeps only the most recent [maxCount].
  Future<void> saveLocation(LocationSuggestion suggestion) async {
    try {
      final current = List<LocationSuggestion>.from(
          _cached ?? await getRecentLocations());

      // Remove existing entry with same shortName (dedup)
      current.removeWhere(
          (s) => s.shortName.toLowerCase() == suggestion.shortName.toLowerCase());

      // Add to front
      current.insert(0, suggestion);

      // Trim to max
      final trimmed = current.take(maxCount).toList();
      _cached = trimmed;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _prefsKey,
        jsonEncode(trimmed.map((s) => s.toJson()).toList()),
      );
    } catch (e) {
      // Don't crash for a non-critical persistence failure
      debugPrint('[RecentLocations] Save failed: $e');
    }
  }

  /// Clears all saved recent locations.
  Future<void> clearAll() async {
    _cached = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }

  void debugPrint(String msg) {
    // ignore: avoid_print
    print(msg);
  }
}
