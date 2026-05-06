import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/watch_connection_manager.dart';

class WatchMetricsProvider extends ChangeNotifier {
  final WatchConnectionManager _manager = WatchConnectionManager();
  
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  bool _isStreaming = false;
  bool get isStreaming => _isStreaming;

  int _pulse = 0;
  int get pulse => _pulse;

  int _restingHeartRate = 0;
  int get restingHeartRate => _restingHeartRate;

  int _maxHeartRate = 0;
  int get maxHeartRate => _maxHeartRate;

  int _wellnessScore = 0;
  int get wellnessScore => _wellnessScore;

  double _spO2 = 0.0;
  double get spO2 => _spO2;

  WatchMetricsProvider() {
    _loadFromStorage();
    _manager.onPulseUpdate = (bpm) {
      _pulse = bpm;
      _isStreaming = true;
      _saveToStorage();
      notifyListeners();
    };
  }

  Future<void> _loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    _pulse = prefs.getInt('watch_pulse') ?? 0;
    _restingHeartRate = prefs.getInt('watch_rhr') ?? 0;
    _maxHeartRate = prefs.getInt('watch_mhr') ?? 0;
    _wellnessScore = prefs.getInt('watch_wellness') ?? 0;
    _spO2 = prefs.getDouble('watch_spo2') ?? 0.0;
    notifyListeners();
  }

  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('watch_pulse', _pulse);
    prefs.setInt('watch_rhr', _restingHeartRate);
    prefs.setInt('watch_mhr', _maxHeartRate);
    prefs.setInt('watch_wellness', _wellnessScore);
    prefs.setDouble('watch_spo2', _spO2);
  }

  Future<void> connectWatch() async {
    bool hasPermissions = await _manager.requestPermissions();
    if (!hasPermissions) {
      // Permission denied, handle via UI ideally
      return;
    }

    bool connected = await _manager.scanAndConnect();
    if (connected) {
      _isConnected = true;
      
      // Fetch historical data
      final data = await _manager.fetchHealthData();
      _restingHeartRate = data['restingHeartRate'];
      _maxHeartRate = data['maxHeartRate'];
      _wellnessScore = data['wellnessScore'];
      _spO2 = data['spO2'];
      
      _saveToStorage();
      notifyListeners();
    }
  }

  void disconnectWatch() {
    _manager.disconnect();
    _isConnected = false;
    _isStreaming = false;
    notifyListeners();
  }
}
