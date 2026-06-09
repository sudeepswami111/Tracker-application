import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioCoachService extends ChangeNotifier {
  static final AudioCoachService _instance = AudioCoachService._internal();
  factory AudioCoachService() => _instance;
  AudioCoachService._internal();

  final FlutterTts _tts = FlutterTts();
  late SharedPreferences _prefs;

  bool _initialized = false;
  
  // Settings
  bool enabled = true;
  bool distanceEnabled = true;
  bool paceEnabled = true;
  bool hydrationEnabled = true;
  bool heartRateEnabled = true;
  bool phaseEnabled = true;

  // Session State
  Set<int> _announcedDistances = {}; // Stores integer parts of km to avoid repeats
  DateTime? _lastPaceAnnouncement;
  DateTime? _lastHydrationAnnouncement;
  DateTime? _lastHeartRateWarning;

  Future<void> initialize() async {
    if (_initialized) return;

    _prefs = await SharedPreferences.getInstance();
    
    // Load preferences
    enabled = _prefs.getBool('audio_coach_enabled') ?? true;
    distanceEnabled = _prefs.getBool('audio_coach_distance_enabled') ?? true;
    paceEnabled = _prefs.getBool('audio_coach_pace_enabled') ?? true;
    hydrationEnabled = _prefs.getBool('audio_coach_hydration_enabled') ?? true;
    heartRateEnabled = _prefs.getBool('audio_coach_hr_enabled') ?? true;
    phaseEnabled = _prefs.getBool('audio_coach_phase_enabled') ?? true;

    // Configure TTS
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    
    // Try en-IN if available, fallback to en-US. We keep it simple here.
    
    _initialized = true;
    notifyListeners();
  }

  // --- Setting Management ---

  Future<void> toggleEnabled(bool value) async {
    enabled = value;
    await _prefs.setBool('audio_coach_enabled', value);
    notifyListeners();
    if (!value) stop();
  }

  Future<void> toggleDistance(bool value) async {
    distanceEnabled = value;
    await _prefs.setBool('audio_coach_distance_enabled', value);
    notifyListeners();
  }

  Future<void> togglePace(bool value) async {
    paceEnabled = value;
    await _prefs.setBool('audio_coach_pace_enabled', value);
    notifyListeners();
  }

  Future<void> toggleHydration(bool value) async {
    hydrationEnabled = value;
    await _prefs.setBool('audio_coach_hydration_enabled', value);
    notifyListeners();
  }

  Future<void> toggleHeartRate(bool value) async {
    heartRateEnabled = value;
    await _prefs.setBool('audio_coach_hr_enabled', value);
    notifyListeners();
  }

  Future<void> togglePhase(bool value) async {
    phaseEnabled = value;
    await _prefs.setBool('audio_coach_phase_enabled', value);
    notifyListeners();
  }

  // --- Core Methods ---

  Future<void> speak(String text) async {
    if (!enabled) return;
    try {
      debugPrint('[AudioCoach] Speaking: $text');
      await _tts.speak(text);
    } catch (e) {
      debugPrint('[AudioCoach] TTS Error: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
      debugPrint('[AudioCoach] Stopped');
    } catch (e) {
      debugPrint('[AudioCoach] TTS Stop Error: $e');
    }
  }

  void resetSession() {
    _announcedDistances.clear();
    _lastPaceAnnouncement = null;
    _lastHydrationAnnouncement = null;
    _lastHeartRateWarning = null;
    stop();
  }

  // --- Announcements ---

  void announceWorkoutStart(bool isRouteRun) {
    if (isRouteRun) {
      speak("Route run started. Follow your selected route.");
    } else {
      speak("Free run started. GPS tracking is active.");
    }
  }

  void announceWorkoutPaused() {
    speak("Workout paused.");
  }

  void announceWorkoutResumed() {
    speak("Workout resumed.");
  }

  void announceWorkoutCompleted() {
    speak("Workout completed. Great job.");
  }

  void announceDistance(double km) {
    if (!distanceEnabled) return;

    // We want to announce: 0.5, 1, 2, 3...
    if (km >= 0.5 && !_announcedDistances.contains(0) && km < 1.0) {
      _announcedDistances.add(0);
      speak("You have completed half a kilometer.");
      debugPrint('[AudioCoach] Distance milestone announced: 0.5 km');
      return;
    }

    int fullKm = km.floor();
    if (fullKm >= 1 && !_announcedDistances.contains(fullKm)) {
      _announcedDistances.add(fullKm);
      speak("You have completed $fullKm kilometer${fullKm > 1 ? 's' : ''}. Keep going.");
      debugPrint('[AudioCoach] Distance milestone announced: $fullKm.0 km');
    }
  }

  void announcePace(double paceMin, double distanceKm) {
    if (!paceEnabled || distanceKm <= 0.1 || paceMin <= 0) return;

    final now = DateTime.now();
    if (_lastPaceAnnouncement == null || now.difference(_lastPaceAnnouncement!).inMinutes >= 5) {
      int minutes = paceMin.floor();
      int seconds = ((paceMin - minutes) * 60).round();
      speak("Your current average pace is $minutes minute${minutes == 1 ? '' : 's'} $seconds second${seconds == 1 ? '' : 's'} per kilometer.");
      _lastPaceAnnouncement = now;
      debugPrint('[AudioCoach] Pace announced: $minutes:$seconds /km');
    } else {
      // debugPrint('[AudioCoach] Pace announcement skipped due to cooldown');
    }
  }

  void announceHydrationReminder({double currentTemp = 25.0}) {
    if (!hydrationEnabled) return;

    final now = DateTime.now();
    bool isHot = currentTemp > 32.0;
    int cooldownMinutes = isHot ? 10 : 15;

    if (_lastHydrationAnnouncement == null || now.difference(_lastHydrationAnnouncement!).inMinutes >= cooldownMinutes) {
      if (isHot) {
        speak("It is hot outside. Take small sips of water when possible.");
      } else {
        speak("Remember to stay hydrated.");
      }
      _lastHydrationAnnouncement = now;
      debugPrint('[AudioCoach] Hydration reminder spoken.');
    }
  }

  void announceHeartRateWarning(int bpm) {
    if (!heartRateEnabled || bpm <= 170) return;

    final now = DateTime.now();
    if (_lastHeartRateWarning == null || now.difference(_lastHeartRateWarning!).inMinutes >= 2) {
      speak("Your heart rate is high. Slow down and breathe steadily.");
      _lastHeartRateWarning = now;
      debugPrint('[AudioCoach] Heart rate alert spoken.');
    }
  }

  void announcePhase(String phaseName) {
    if (!phaseEnabled) return;
    speak("$phaseName started.");
    debugPrint('[AudioCoach] Phase announced: $phaseName');
  }
}
